//
//  FirestoreBatchExecuting+Defaults.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation
import FirebaseFirestore

extension FirestoreBatchExecuting {
    
    func commitSetBatch(
        operations: [(ref: DocumentReference, data: [String: Any], merge: Bool)],
        maxAttempts: Int = 5,
        initialDelay: TimeInterval = 0.25,
        jitter: ClosedRange<Double> = 0.0...0.25
    ) async throws {
        try await commitSetBatch(
            operations: operations,
            maxAttempts: maxAttempts,
            initialDelay: initialDelay,
            jitter: jitter
        )
    }
    
    func commitDeleteBatch(
        refs: [DocumentReference],
        maxAttempts: Int = 5,
        initialDelay: TimeInterval = 0.25,
        jitter: ClosedRange<Double> = 0.0...0.25
    ) async throws {
        try await commitDeleteBatch(
            refs: refs,
            maxAttempts: maxAttempts,
            initialDelay: initialDelay,
            jitter: jitter
        )
    }
}
