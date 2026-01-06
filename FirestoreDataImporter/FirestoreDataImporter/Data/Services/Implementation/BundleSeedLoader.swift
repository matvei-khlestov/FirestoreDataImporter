//
//  BundleSeedLoader.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

final class BundleSeedLoader: BundleSeedLoading {
    
    private let bundle: Bundle
    
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    func loadArray<T: Decodable>(_ type: T.Type, name: String, ext: String) throws -> [T] {
        let data = try loadData(name: name, ext: ext)
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            throw ImportError.decodingFailed("\(name).\(ext)", underlying: error)
        }
    }
    
    func loadData(name: String, ext: String) throws -> Data {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw ImportError.fileNotFound("\(name).\(ext)")
        }
        return try Data(contentsOf: url)
    }
}
