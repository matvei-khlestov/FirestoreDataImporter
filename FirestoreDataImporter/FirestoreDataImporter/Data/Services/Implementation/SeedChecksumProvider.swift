//
//  SeedChecksumProvider.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

final class SeedChecksumProvider: SeedChecksumProviding {
    
    private let loader: BundleSeedLoading
    
    init(loader: BundleSeedLoading) {
        self.loader = loader
    }
    
    func checksums(for files: [(key: String, file: String, ext: String)]) throws -> [String: String] {
        var dict: [String: String] = [:]
        for f in files {
            let data = try loader.loadData(name: f.file, ext: f.ext)
            dict[f.key] = SHA256.hex(of: data)
        }
        return dict
    }
}
