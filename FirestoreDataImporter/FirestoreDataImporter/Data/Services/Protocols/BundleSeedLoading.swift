//
//  BundleSeedLoading.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

protocol BundleSeedLoading: AnyObject {
    func loadArray<T: Decodable>(_ type: T.Type, name: String, ext: String) throws -> [T]
    func loadData(name: String, ext: String) throws -> Data
}
