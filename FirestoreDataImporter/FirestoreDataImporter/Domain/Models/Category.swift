//
//  Category.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

struct Category: Codable, Equatable {
    let id: String
    let name: String
    let imageURL: String
    let brandIds: [String]
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
}
