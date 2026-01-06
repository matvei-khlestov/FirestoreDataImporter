//
//  FirestoreDryRunBuilding.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

protocol FirestoreDryRunBuilding: AnyObject {
    func buildReport(
        brands: [Brand],
        categories: [Category],
        products: [Product]
    ) async throws -> DryRunReport
}
