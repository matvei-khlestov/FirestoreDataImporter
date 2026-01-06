//
//  FirestoreBatchExecuting.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation
import FirebaseFirestore

protocol FirestoreBatchExecuting: AnyObject {
    func commitSetBatch(
        operations: [(ref: DocumentReference, data: [String: Any], merge: Bool)],
        maxAttempts: Int,
        initialDelay: TimeInterval,
        jitter: ClosedRange<Double>
    ) async throws
    
    func commitDeleteBatch(
        refs: [DocumentReference],
        maxAttempts: Int,
        initialDelay: TimeInterval,
        jitter: ClosedRange<Double>
    ) async throws
}
