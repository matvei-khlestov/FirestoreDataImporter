//
//  Product.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

struct Product: Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let nameLower: String
    let categoryId: String
    let brandId: String
    let price: Double
    let imageURL: String
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let keywords: [String]
}
