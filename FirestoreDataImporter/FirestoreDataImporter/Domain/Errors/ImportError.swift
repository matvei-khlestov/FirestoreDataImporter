//
//  ImportError.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

enum ImportError: Error {
    case fileNotFound(String)
    case decodingFailed(String, underlying: Error)
    case firestoreNotConfigured
}
