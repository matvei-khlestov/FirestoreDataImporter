//
//  FirestoreImportingProtocol.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

/// Контракт оркестратора импорта (для DI/тестов)
protocol FirestoreImportingProtocol: AnyObject {
    /// Запуск пайплайна (dry-run → импорт)
    func runIfNeeded(
        overwrite: Bool,
        checksumNamespace: String,
        pruneMissing: Bool,
        force: Bool
    ) async
    
    /// Сброс маркеров импорта
    func resetMarkers()
}

/// Отдельный маленький контракт для эмиссии логов (ISP + DIP).
protocol FirestoreImportLogEmitting: AnyObject {
    var onLog: ((String) -> Void)? { get set }
}

// Удобный враппер с дефолтными параметрами
extension FirestoreImportingProtocol {
    @inlinable
    func runIfNeeded(
        overwrite: Bool = false,
        checksumNamespace: String = SeedConfig.checksumNamespace,
        pruneMissing: Bool = true,
        force: Bool = false
    ) async {
        await runIfNeeded(
            overwrite: overwrite,
            checksumNamespace: checksumNamespace,
            pruneMissing: pruneMissing,
            force: force
        )
    }
}
