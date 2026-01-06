//
//  PreparedInputs.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

struct PreparedInputs {
    let brands: [Brand]
    let categories: [Category]
    let products: [Product]
    let checksums: [String: String]
    let store: ChecksumStoringProtocol
}
