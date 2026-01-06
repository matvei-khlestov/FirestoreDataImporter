//
//  FirestoreImportStoringProtocol.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

protocol FirestoreImportStoringProtocol: AnyObject {
    var isOverwriteEnabled: Bool { get set }
    var isDebugImportEnabled: Bool { get set }
    var didSeed: Bool { get set }
    var didRunOnce: Bool { get }
    var seedVersion: Int { get set }
    var requiredSeedVersion: Int { get set }
    
    func resetSeedMarkers()
}
