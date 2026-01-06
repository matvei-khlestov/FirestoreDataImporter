//
//  FirestoreImportServicingProtocol.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

protocol FirestoreImportServicingProtocol: AnyObject {
    func importSmart(
        overwrite: Bool,
        brandsFile: String,
        categoriesFile: String,
        productsFile: String,
        fileExtension: String,
        checksumNamespace: String,
        dryRun: Bool,
        pruneMissing: Bool
    ) async throws -> (report: DryRunReport, outcome: ImportOutcome)
}

extension FirestoreImportServicingProtocol {
    /// Convenience overload with sensible defaults for bundle file names and extension.
    func importSmart(
        overwrite: Bool,
        checksumNamespace: String,
        dryRun: Bool,
        pruneMissing: Bool
    ) async throws -> (report: DryRunReport, outcome: ImportOutcome) {
        try await importSmart(
            overwrite: overwrite,
            brandsFile: SeedConfig.brandsCollection,
            categoriesFile: SeedConfig.categoriesCollection,
            productsFile: SeedConfig.productsCollection,
            fileExtension: SeedConfig.fileExtension,
            checksumNamespace: checksumNamespace,
            dryRun: dryRun,
            pruneMissing: pruneMissing
        )
    }
}
