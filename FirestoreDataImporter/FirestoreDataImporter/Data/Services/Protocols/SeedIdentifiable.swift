//
//  SeedIdentifiable.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

protocol SeedIdentifiable {
    var id: String { get }
}

extension Brand: SeedIdentifiable {}
extension Category: SeedIdentifiable {}
extension Product: SeedIdentifiable {}
