//
//  DIContainer.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation
import FactoryKit

// MARK: - Dependency Injection Container
/// Регистрация зависимостей приложения в `FactoryKit.Container`.
///
/// Этот файл описывает граф зависимостей для сценария импорта сид-данных в Firestore:
/// - `FirestoreImportStorage` — хранение флагов/маркеров импорта (UserDefaults).
/// - `ChecksumStorage` — хранение checksum для секций (по namespace).
/// - `FirestoreImportService` — низкоуровневая работа с Firestore (dry-run, upsert/delete, retry/backoff).
/// - `FirestoreImporter` — оркестратор пайплайна (dry-run → импорт, выставление маркеров).
/// - `FirestoreImportViewModel` — UI-слой управления импортом (состояние, действия).
///
/// ## Notes
/// - `singleton` используется для сервисов и оркестратора, чтобы сохранять единый runtime-state
///   и не пересоздавать тяжелые зависимости.
/// - `ParameterFactory` применяется для `ChecksumStorage`, т.к. хранилище зависит от `namespace`.
extension Container {
    
    // MARK: - Storage
    
    /// Хранилище флагов и маркеров импорта (UserDefaults).
    /// Используется ViewModel и Importer'ом.
    var debugImportStorage: Factory<FirestoreImportStoringProtocol> {
        self {
            FirestoreImportStorage.shared
        }
    }
    
    // MARK: - Checksums
    
    /// Фабрика checksum-хранилища по namespace.
    /// Применяется сервисом импорта для определения, изменилась ли секция по данным в Bundle.
    var checksumStorage: ParameterFactory<String, ChecksumStoringProtocol> {
        self { namespace in
            ChecksumStorage(namespace: namespace)
        }
    }
    
    // MARK: - Service
    
    /// Сервис импорта в Firestore (dry-run + запись) с поддержкой checksum и retry/backoff.
    /// Singleton — чтобы не пересоздавать service и его внутренние зависимости.
    var debugImportService: Factory<FirestoreImportServicingProtocol> {
        self { [unowned self] in
            FirestoreImportService(
                checksumStoreFactory: { namespace in
                    self.checksumStorage(namespace)
                }
            )
        }.singleton
    }
    
    // MARK: - Orchestrator
    
    /// Оркестратор импорта (решает, нужно ли выполнять импорт и в каком режиме).
    /// Singleton — единый координатор пайплайна на жизненный цикл приложения.
    var debugImporter: Factory<FirestoreImportingProtocol> {
        self { [unowned self] in
            FirestoreImporter(
                debugImportService: self.debugImportService(),
                debugImportStorage: self.debugImportStorage()
            )
        }.singleton
    }
    
    // MARK: - ViewModel
    
    /// ViewModel экрана импорта.
    /// Не singleton: создаётся на экран/сцену и не должна переживать UI-жизненный цикл.
    var debugImportViewModel: Factory<FirestoreImportViewModelProtocol> {
        self {
            FirestoreImportViewModel(
                debugImportStorage: self.debugImportStorage(),
                debugImporter: self.debugImporter()
            )
        }
    }
}
