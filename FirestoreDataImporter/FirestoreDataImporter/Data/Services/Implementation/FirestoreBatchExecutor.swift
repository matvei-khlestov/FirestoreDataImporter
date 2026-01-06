//
//  FirestoreBatchExecutor.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreBatchExecutor: FirestoreBatchExecuting {
    
    private let db: Firestore
    
    init(db: Firestore) {
        self.db = db
    }
    
    func commitSetBatch(
        operations: [(ref: DocumentReference, data: [String: Any], merge: Bool)],
        maxAttempts: Int = 5,
        initialDelay: TimeInterval = 0.25,
        jitter: ClosedRange<Double> = 0.0...0.25
    ) async throws {
        var attempt = 0
        var delay = initialDelay
        
        while true {
            do {
                let batch = db.batch()
                for op in operations {
                    batch.setData(op.data, forDocument: op.ref, merge: op.merge)
                }
                try await batch.commit()
                return
            } catch {
                attempt += 1
                if attempt >= maxAttempts || !isRetryable(error) { throw error }
                let jitterSec = Double.random(in: jitter)
                try await Task.sleep(nanoseconds: UInt64((delay + jitterSec) * 1_000_000_000))
                delay *= 2
            }
        }
    }
    
    func commitDeleteBatch(
        refs: [DocumentReference],
        maxAttempts: Int = 5,
        initialDelay: TimeInterval = 0.25,
        jitter: ClosedRange<Double> = 0.0...0.25
    ) async throws {
        var attempt = 0
        var delay = initialDelay
        
        while true {
            do {
                let batch = db.batch()
                for ref in refs { batch.deleteDocument(ref) }
                try await batch.commit()
                return
            } catch {
                attempt += 1
                if attempt >= maxAttempts || !isRetryable(error) { throw error }
                let jitterSec = Double.random(in: jitter)
                try await Task.sleep(nanoseconds: UInt64((delay + jitterSec) * 1_000_000_000))
                delay *= 2
            }
        }
    }
    
    private func isRetryable(_ error: Error) -> Bool {
        let ns = error as NSError
        
        if ns.domain == FirestoreErrorDomain {
            switch ns.code {
            case FirestoreErrorCode.unavailable.rawValue,
                 FirestoreErrorCode.deadlineExceeded.rawValue,
                 FirestoreErrorCode.resourceExhausted.rawValue:
                return true
            default:
                return false
            }
        }
        
        return ns.domain == NSURLErrorDomain
    }
}
