//
//  ChecksumStoringProtocol.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

protocol ChecksumStoringProtocol: AnyObject {
    func value(for name: String) -> String?
    func set(_ value: String?, for name: String)
}
