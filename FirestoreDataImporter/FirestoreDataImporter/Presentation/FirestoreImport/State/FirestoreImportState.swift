//
//  FirestoreImportState.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

struct FirestoreImportState {
    var isRunning: Bool = false
    var hasRunBefore: Bool
    var isEnabledFlag: Bool
    var overwrite: Bool = false
    var seedVersion: Int
    var log: String = ""
}
