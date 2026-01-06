//
//  FirestoreImportViewModelProtocol.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

protocol FirestoreImportViewModelProtocol: AnyObject {
    
    var state: FirestoreImportState { get }
    var onStateChange: ((FirestoreImportState) -> Void)? { get set }
    
    func setImporterEnabled(_ isOn: Bool)
    func setOverwrite(_ isOn: Bool)
    func setSeedVersion(_ version: Int)
    func bumpSeedVersion(by delta: Int)
    func runImport()
    func resetMarkers()
}
