//
//  SeedConfig.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

// MARK: - Seed Configuration

/// Конфигурация флагов и имён файлов для импорта.
enum SeedConfig {
    /// Можно включать/выключать импорт из UI.
    static var isEnabled: Bool {
        get { FirestoreImportStorage.shared.isDebugImportEnabled }
        set { FirestoreImportStorage.shared.isDebugImportEnabled = newValue }
    }
    
    /// Версия сид-данных. Увеличивай при изменении payload'ов.
    static var seedVersion: Int { FirestoreImportStorage.shared.requiredSeedVersion }
    
    /// Имена JSON-файлов без расширения (лежат в Bundle).
    nonisolated static let brandsCollection = "brands"
    nonisolated static let categoriesCollection = "categories"
    nonisolated static let productsCollection = "products"
    
    /// Расширение файлов.
    nonisolated static let fileExtension = "json"
    
    /// Namespace для хранимых checksum (можно переключать из UI, если нужно несколько наборов данных).
    nonisolated static let checksumNamespace = "seed.v1"
}
