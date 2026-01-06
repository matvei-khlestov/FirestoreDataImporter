//
//  FirestoreDryRunBuilder.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreDryRunBuilder: FirestoreDryRunBuilding {
    
    fileprivate typealias Doc = [String: Any]
    
    private let db: Firestore
    
    init(db: Firestore) {
        self.db = db
    }
    
    func buildReport(
        brands: [Brand],
        categories: [Category],
        products: [Product]
    ) async throws -> DryRunReport {
        let brandsSection = try await buildBrandsSection(brands)
        let categoriesSection = try await buildCategoriesSection(categories)
        let productsSection = try await buildProductsSection(products)
        
        return DryRunReport(
            brands: brandsSection,
            categories: categoriesSection,
            products: productsSection
        )
    }
}

// MARK: - Sections

private extension FirestoreDryRunBuilder {
    @inline(__always)
    func buildBrandsSection(_ brands: [Brand]) async throws -> DryRunReport.Section {
        try await computeSection(
            name: "brands",
            collection: SeedConfig.brandsCollection,
            models: brands,
            id: \.id,
            map: { ["name": $0.name, "imageURL": $0.imageURL, "isActive": $0.isActive] },
            compareKeys: ["name", "imageURL", "isActive"]
        )
    }
    
    @inline(__always)
    func buildCategoriesSection(_ categories: [Category]) async throws -> DryRunReport.Section {
        try await computeSection(
            name: "categories",
            collection: SeedConfig.categoriesCollection,
            models: categories,
            id: \.id,
            map: { ["name": $0.name, "imageURL": $0.imageURL, "brandIds": $0.brandIds, "isActive": $0.isActive] },
            compareKeys: ["name", "imageURL", "brandIds", "isActive"]
        )
    }
    
    @inline(__always)
    func buildProductsSection(_ products: [Product]) async throws -> DryRunReport.Section {
        try await computeSection(
            name: "products",
            collection: SeedConfig.productsCollection,
            models: products,
            id: \.id,
            map: {
                [
                    "name":        $0.name,
                    "description": $0.description,
                    "nameLower":   $0.nameLower,
                    "categoryId":  $0.categoryId,
                    "brandId":     $0.brandId,
                    "price":       $0.price,
                    "imageURL":    $0.imageURL,
                    "isActive":    $0.isActive,
                    "keywords":    $0.keywords
                ]
            },
            compareKeys: [
                "name",
                "description",
                "nameLower",
                "categoryId",
                "brandId",
                "price",
                "imageURL",
                "isActive",
                "keywords"
            ]
        )
    }
}

// MARK: - Core diff

private extension FirestoreDryRunBuilder {
    func fetchAllIDs(in collection: String) async throws -> Set<String> {
        var ids = Set<String>()
        let snapshot = try await db.collection(collection).getDocuments()
        for doc in snapshot.documents { ids.insert(doc.documentID) }
        return ids
    }
    
    func fetchExistingDocuments(collection: String, ids: [String]) async throws -> [String: Doc] {
        var result: [String: Doc] = [:]
        
        try await withThrowingTaskGroup(of: (String, Doc?).self) { group in
            for id in ids {
                group.addTask { [db] in
                    let snap = try await db.collection(collection).document(id).getDocument()
                    return (id, snap.data())
                }
            }
            for try await (id, data) in group {
                if let data { result[id] = data }
            }
        }
        
        return result
    }
    
    func computeSection<T>(
        name: String,
        collection: String,
        models: [T],
        id: KeyPath<T, String>,
        map: (T) -> Doc,
        compareKeys: [String]
    ) async throws -> DryRunReport.Section {
        
        let jsonIDs = Set(models.map { $0[keyPath: id] })
        
        async let existingForJSONTask = fetchExistingDocuments(collection: collection, ids: Array(jsonIDs))
        async let allExistingIDsTask = fetchAllIDs(in: collection)
        
        let (existingForJSON, allExistingIDs) = try await (existingForJSONTask, allExistingIDsTask)
        let deletions = allExistingIDs.subtracting(jsonIDs)
        
        var create = 0, update = 0, skip = 0
        for m in models {
            let mid = m[keyPath: id]
            let newData = map(m)
            if let old = existingForJSON[mid] {
                equalByKeys(old, newData, keys: compareKeys) ? (skip += 1) : (update += 1)
            } else {
                create += 1
            }
        }
        
        return .init(
            name: name,
            willCreate: create,
            willUpdate: update,
            willSkip: skip,
            willDelete: deletions.count,
            totalJSON: models.count
        )
    }
    
    @inline(__always)
    func pick(_ dict: Doc, keys: [String]) -> Doc {
        var out: Doc = [:]
        for k in keys { if let v = dict[k] { out[k] = v } }
        return out
    }
    
    @inline(__always)
    func canonicalJSON(_ dict: Doc) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])) ?? Data()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    @inline(__always)
    func equalByKeys(_ lhs: Doc, _ rhs: Doc, keys: [String]) -> Bool {
        canonicalJSON(pick(lhs, keys: keys)) == canonicalJSON(pick(rhs, keys: keys))
    }
}

