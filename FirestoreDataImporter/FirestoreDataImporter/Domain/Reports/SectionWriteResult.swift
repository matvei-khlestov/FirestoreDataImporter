//
//  SectionWriteResult.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

public struct SectionWriteResult {
    let upserted: Int
    let deleted: Int
    var didWrite: Bool { upserted > 0 || deleted > 0 }
}
