//
//  SHA256.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation
import CryptoKit

enum SHA256 {
    static func hex(of data: Data) -> String {
        let digest = CryptoKit.SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
