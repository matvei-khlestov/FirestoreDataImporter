//
//  FirestoreImportService.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

// MARK: - Import Service

final class FirestoreImportService: FirestoreImportServicingProtocol {
    
    // MARK: Dependencies
    
    private let db: Firestore
    private let makeStore: (String) -> ChecksumStoringProtocol
    private let loader: BundleSeedLoading
    private let checksumProvider: SeedChecksumProviding
    private let dryRunBuilder: FirestoreDryRunBuilding
    private let batchExecutor: FirestoreBatchExecuting
    
    // MARK: Init
    
    init(
        db: Firestore = Firestore.firestore(),
        checksumStoreFactory: @escaping (String) -> ChecksumStoringProtocol,
        loader: BundleSeedLoading = BundleSeedLoader(),
        checksumProvider: SeedChecksumProviding? = nil,
        dryRunBuilder: FirestoreDryRunBuilding? = nil,
        batchExecutor: FirestoreBatchExecuting? = nil
    ) {
        self.db = db
        self.makeStore = checksumStoreFactory
        self.loader = loader
        
        let checksumProvider = checksumProvider ?? SeedChecksumProvider(loader: loader)
        self.checksumProvider = checksumProvider
        
        self.dryRunBuilder = dryRunBuilder ?? FirestoreDryRunBuilder(db: db)
        self.batchExecutor = batchExecutor ?? FirestoreBatchExecutor(db: db)
    }
}

// MARK: - High-level Import API

extension FirestoreImportService {
    public func importSmart(
        overwrite: Bool = true,
        brandsFile: String = SeedConfig.brandsCollection,
        categoriesFile: String = SeedConfig.categoriesCollection,
        productsFile: String = SeedConfig.productsCollection,
        fileExtension: String = SeedConfig.fileExtension,
        checksumNamespace: String = SeedConfig.checksumNamespace,
        dryRun: Bool = false,
        pruneMissing: Bool = false
    ) async throws -> (report: DryRunReport, outcome: ImportOutcome) {
        try ensureFirestore()
        
        let prepared = try prepareInputs(
            brandsFile: brandsFile,
            categoriesFile: categoriesFile,
            productsFile: productsFile,
            ext: fileExtension,
            checksumNamespace: checksumNamespace
        )
        
        let report = try await dryRunBuilder.buildReport(
            brands: prepared.brands,
            categories: prepared.categories,
            products: prepared.products
        )
        
        if dryRun {
            return (report, ImportOutcome(
                brands: 0, categories: 0, products: 0,
                brandsDeleted: 0, categoriesDeleted: 0, productsDeleted: 0
            ))
        }
        
        let outcome = try await importAllSections(
            report: report,
            prepared: prepared,
            overwrite: overwrite,
            pruneMissing: pruneMissing
        )
        
        return (report, outcome)
    }
}

// MARK: - Prepared Inputs

private extension FirestoreImportService {
    struct PreparedInputs {
        let brands: [Brand]
        let categories: [Category]
        let products: [Product]
        let checksums: [String: String]
        let store: ChecksumStoringProtocol
    }
    
    @inline(__always)
    func prepareInputs(
        brandsFile: String,
        categoriesFile: String,
        productsFile: String,
        ext: String,
        checksumNamespace: String
    ) throws -> PreparedInputs {
        let brands = try loader.loadArray(Brand.self, name: brandsFile, ext: ext)
        let categories = try loader.loadArray(Category.self, name: categoriesFile, ext: ext)
        let products = try loader.loadArray(Product.self, name: productsFile, ext: ext)
        
        let checksums = try checksumProvider.checksums(for: [
            (key: SeedConfig.brandsCollection, file: brandsFile, ext: ext),
            (key: SeedConfig.categoriesCollection, file: categoriesFile, ext: ext),
            (key: SeedConfig.productsCollection, file: productsFile, ext: ext)
        ])
        
        let store = makeStore(checksumNamespace)
        
        return PreparedInputs(
            brands: brands,
            categories: categories,
            products: products,
            checksums: checksums,
            store: store
        )
    }
}

// MARK: - Section Planning & Execution

private extension FirestoreImportService {
    struct SectionPlan {
        let section: DryRunReport.Section
        let checksumKey: String
        let op: () async throws -> SectionWriteResult
        let apply: (inout ImportOutcome, SectionWriteResult) -> Void
    }
    
    @inline(__always)
    func importAllSections(
        report: DryRunReport,
        prepared: PreparedInputs,
        overwrite: Bool,
        pruneMissing: Bool
    ) async throws -> ImportOutcome {
        var outcome = ImportOutcome(
            brands: 0, categories: 0, products: 0,
            brandsDeleted: 0, categoriesDeleted: 0, productsDeleted: 0
        )
        
        let plans: [SectionPlan] = [
            SectionPlan(
                section: report.brands,
                checksumKey: SeedConfig.brandsCollection,
                op: { [prepared, overwrite, pruneMissing] in
                    try await self.processBrands(
                        brands: prepared.brands,
                        overwrite: overwrite,
                        pruneMissing: pruneMissing,
                        jsonIDs: Set(prepared.brands.map { $0.id })
                    )
                },
                apply: { outcome, res in
                    outcome = outcome.updating(brands: res.upserted, brandsDeleted: res.deleted)
                }
            ),
            SectionPlan(
                section: report.categories,
                checksumKey: SeedConfig.categoriesCollection,
                op: { [prepared, overwrite, pruneMissing] in
                    try await self.processCategories(
                        categories: prepared.categories,
                        overwrite: overwrite,
                        pruneMissing: pruneMissing,
                        jsonIDs: Set(prepared.categories.map { $0.id })
                    )
                },
                apply: { outcome, res in
                    outcome = outcome.updating(categories: res.upserted, categoriesDeleted: res.deleted)
                }
            ),
            SectionPlan(
                section: report.products,
                checksumKey: SeedConfig.productsCollection,
                op: { [prepared, overwrite, pruneMissing] in
                    try await self.processProducts(
                        products: prepared.products,
                        overwrite: overwrite,
                        pruneMissing: pruneMissing,
                        jsonIDs: Set(prepared.products.map { $0.id })
                    )
                },
                apply: { outcome, res in
                    outcome = outcome.updating(products: res.upserted, productsDeleted: res.deleted)
                }
            )
        ]
        
        for plan in plans {
            if let res = try await runSection(
                section: plan.section,
                checksumKey: plan.checksumKey,
                store: prepared.store,
                checksums: prepared.checksums,
                pruneMissing: pruneMissing,
                operation: plan.op
            ) {
                plan.apply(&outcome, res)
            }
        }
        
        return outcome
    }
    
    @inline(__always)
    func runSection(
        section: DryRunReport.Section,
        checksumKey: String,
        store: ChecksumStoringProtocol,
        checksums: [String: String],
        pruneMissing: Bool,
        operation: () async throws -> SectionWriteResult
    ) async throws -> SectionWriteResult? {
        let changedByChecksum = store.value(for: checksumKey) != checksums[checksumKey]
        let mustImport = shouldImportSection(
            changedByChecksum: changedByChecksum,
            section: section,
            pruneMissing: pruneMissing
        )
        guard mustImport else { return nil }
        
        let res = try await operation()
        if res.didWrite { store.set(checksums[checksumKey], for: checksumKey) }
        return res
    }
    
    @inline(__always)
    func shouldImportSection(
        changedByChecksum: Bool,
        section: DryRunReport.Section,
        pruneMissing: Bool
    ) -> Bool {
        changedByChecksum
        || section.willCreate > 0
        || section.willUpdate > 0
        || (pruneMissing && section.willDelete > 0)
    }
}

// MARK: - Section Operations

private extension FirestoreImportService {
    func processBrands(
        brands: [Brand],
        overwrite: Bool,
        pruneMissing: Bool,
        jsonIDs: Set<String>
    ) async throws -> SectionWriteResult {
        var upserted = 0, deleted = 0
        
        if pruneMissing {
            let refs = try await deletionsFor(collection: SeedConfig.brandsCollection, jsonIDs: jsonIDs)
            if !refs.isEmpty {
                try await batchExecutor.commitDeleteBatch(refs: refs)
                deleted = refs.count
            }
        }
        
        if !brands.isEmpty {
            upserted = try await upsertWithTimestampsAndRetry(
                collection: SeedConfig.brandsCollection,
                models: brands,
                overwrite: overwrite,
                map: { b in ["name": b.name, "imageURL": b.imageURL, "isActive": b.isActive] }
            )
        }
        
        return SectionWriteResult(upserted: upserted, deleted: deleted)
    }
    
    func processCategories(
        categories: [Category],
        overwrite: Bool,
        pruneMissing: Bool,
        jsonIDs: Set<String>
    ) async throws -> SectionWriteResult {
        var upserted = 0, deleted = 0
        
        if pruneMissing {
            let refs = try await deletionsFor(collection: SeedConfig.categoriesCollection, jsonIDs: jsonIDs)
            if !refs.isEmpty {
                try await batchExecutor.commitDeleteBatch(refs: refs)
                deleted = refs.count
            }
        }
        
        if !categories.isEmpty {
            upserted = try await upsertWithTimestampsAndRetry(
                collection: SeedConfig.categoriesCollection,
                models: categories,
                overwrite: overwrite,
                map: { c in [
                    "name": c.name,
                    "imageURL": c.imageURL,
                    "brandIds": c.brandIds,
                    "isActive": c.isActive
                ] }
            )
        }
        
        return SectionWriteResult(upserted: upserted, deleted: deleted)
    }
    
    func processProducts(
        products: [Product],
        overwrite: Bool,
        pruneMissing: Bool,
        jsonIDs: Set<String>
    ) async throws -> SectionWriteResult {
        var upserted = 0, deleted = 0
        
        if pruneMissing {
            let refs = try await deletionsFor(collection: SeedConfig.productsCollection, jsonIDs: jsonIDs)
            if !refs.isEmpty {
                try await batchExecutor.commitDeleteBatch(refs: refs)
                deleted = refs.count
            }
        }
        
        if !products.isEmpty {
            upserted = try await upsertWithTimestampsAndRetry(
                collection: SeedConfig.productsCollection,
                models: products,
                overwrite: overwrite,
                map: { p in
                    [
                        "name": p.name,
                        "description": p.description,
                        "nameLower": p.nameLower,
                        "categoryId": p.categoryId,
                        "brandId": p.brandId,
                        "price": p.price,
                        "imageURL": p.imageURL,
                        "isActive": p.isActive,
                        "keywords": p.keywords
                    ]
                }
            )
        }
        
        return SectionWriteResult(upserted: upserted, deleted: deleted)
    }
}

// MARK: - Upsert with timestamps

private extension FirestoreImportService {
    func upsertWithTimestampsAndRetry<T: SeedIdentifiable>(
        collection: String,
        models: [T],
        overwrite: Bool,
        map: (T) -> [String: Any]
    ) async throws -> Int {
        let chunkSize = 300
        var total = 0
        
        for chunkStart in stride(from: 0, to: models.count, by: chunkSize) {
            let end = min(chunkStart + chunkSize, models.count)
            let slice = Array(models[chunkStart..<end])
            
            var ops: [(ref: DocumentReference, data: [String: Any], merge: Bool)] = []
            ops.reserveCapacity(slice.count)
            
            for model in slice {
                let ref = db.collection(collection).document(model.id)
                let snap = try await ref.getDocument()
                
                let isNew = !snap.exists
                if !isNew && !overwrite { continue }
                
                var data = map(model)
                data["updatedAt"] = FieldValue.serverTimestamp()
                if isNew { data["createdAt"] = FieldValue.serverTimestamp() }
                
                ops.append((ref: ref, data: data, merge: !isNew))
            }
            
            guard !ops.isEmpty else { continue }
            try await batchExecutor.commitSetBatch(operations: ops)
            total += ops.count
        }
        
        return total
    }
}

// MARK: - Deletions

private extension FirestoreImportService {
    func fetchAllIDs(in collection: String) async throws -> Set<String> {
        var ids = Set<String>()
        let snapshot = try await db.collection(collection).getDocuments()
        for doc in snapshot.documents { ids.insert(doc.documentID) }
        return ids
    }
    
    func deletionsFor(collection: String, jsonIDs: Set<String>) async throws -> [DocumentReference] {
        let existing = try await fetchAllIDs(in: collection)
        let toDelete = existing.subtracting(jsonIDs)
        return toDelete.map { db.collection(collection).document($0) }
    }
}

// MARK: - Preconditions

private extension FirestoreImportService {
    @inline(__always)
    func ensureFirestore() throws {
        guard FirebaseApp.app() != nil else { throw ImportError.firestoreNotConfigured }
    }
}
