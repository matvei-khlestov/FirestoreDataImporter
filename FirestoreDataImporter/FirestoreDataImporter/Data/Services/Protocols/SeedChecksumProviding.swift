//
//  SeedChecksumProviding.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

protocol SeedChecksumProviding: AnyObject {
    func checksums(for files: [(key: String, file: String, ext: String)]) throws -> [String: String]
}
