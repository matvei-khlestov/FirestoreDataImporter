//
//  FirestoreImporter.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

// MARK: - Debug Import Orchestrator

final class FirestoreImporter: FirestoreImportingProtocol {
    
    // MARK: - Callbacks
    
    /// Вызывается на каждую строку лога (UI может подписаться и показывать в logView).
    var onLog: ((String) -> Void)?
    
    // MARK: - Properties
    
    private let df = ISO8601DateFormatter()
    
    private let debugImportStorage: FirestoreImportStoringProtocol
    private let debugImportService: FirestoreImportServicingProtocol
    
    // MARK: - Init
    
    init(
        debugImportService: FirestoreImportServicingProtocol,
        debugImportStorage: FirestoreImportStoringProtocol
    ) {
        self.debugImportService = debugImportService
        self.debugImportStorage = debugImportStorage
    }
    
    // MARK: - Public API
    
    /// Стартап-сценарий: dry-run → импорт (если нужно), выставляет маркеры.
    func runIfNeeded(
        overwrite: Bool = false,
        checksumNamespace: String = SeedConfig.checksumNamespace,
        pruneMissing: Bool = true,
        force: Bool = false
    ) async {
        guard canRun(force: force) else { return }
        
        let t0 = Date()
        
        do {
            let report = try await performDryRun(
                service: debugImportService,
                overwrite: overwrite,
                checksumNamespace: checksumNamespace,
                pruneMissing: pruneMissing
            )
            
            if isNothingToDo(report) {
                markAsSeeded()
                log("ℹ️ [DebugImporter] Изменений нет — запись в Firestore пропущена.")
                return
            }
            
            try await performImport(
                service: debugImportService,
                overwrite: overwrite,
                checksumNamespace: checksumNamespace,
                pruneMissing: pruneMissing,
                startedAt: t0
            )
        } catch {
            log("❌ [DebugImporter] Ошибка импорта: \(error)")
        }
    }
    
    /// Сбросить маркеры — позволит выполнить импорт снова при следующем запуске.
    func resetMarkers() {
        debugImportStorage.resetSeedMarkers()
        log("🔁 [DebugImporter] Маркеры импорта сброшены")
    }
    
    // MARK: - Private helpers
    
    private func canRun(force: Bool) -> Bool {
        guard FirebaseApp.app() != nil else {
            log("⚠️ [DebugImporter] Firebase не сконфигурирован — импорт пропущен")
            return false
        }
        guard SeedConfig.isEnabled else {
            log("ℹ️ [DebugImporter] Импорт выключен (SeedConfig.isEnabled == false)")
            return false
        }
        
        let didSeed = debugImportStorage.didSeed
        let currentVersion = debugImportStorage.seedVersion
        let needsReseed = (currentVersion != SeedConfig.seedVersion)
        
        if !(force || !didSeed || needsReseed) {
            log("ℹ️ [DebugImporter] Импорт уже выполнялся (версия \(currentVersion)) — пропускаем")
            return false
        }
        return true
    }
    
    private func performDryRun(
        service: FirestoreImportServicingProtocol,
        overwrite: Bool,
        checksumNamespace: String,
        pruneMissing: Bool
    ) async throws -> DryRunReport {
        let (report, _) = try await service.importSmart(
            overwrite: overwrite,
            checksumNamespace: checksumNamespace,
            dryRun: true,
            pruneMissing: pruneMissing
        )
        
        log("📊 [DebugImporter] Dry-run отчёт:")
        
        let lines = report.summary.components(separatedBy: .newlines)
        let bodyLines = (lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("Dry-run:") == true)
        ? Array(lines.dropFirst())
        : lines
        
        for line in bodyLines.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) where !line.isEmpty {
            log(line)
        }
        
        return report
    }
    
    private func performImport(
        service: FirestoreImportServicingProtocol,
        overwrite: Bool,
        checksumNamespace: String,
        pruneMissing: Bool,
        startedAt: Date
    ) async throws {
        let (_, outcome) = try await service.importSmart(
            overwrite: overwrite,
            checksumNamespace: checksumNamespace,
            dryRun: false,
            pruneMissing: pruneMissing
        )
        
        markAsSeeded()
        
        let dt = Date().timeIntervalSince(startedAt)
        log("✅ [DebugImporter] Импорт выполнен за \(String(format: "%.2f", dt))s")
        log("• Brands — upsert: \(outcome.brands), deleted: \(outcome.brandsDeleted)")
        log("• Categories — upsert: \(outcome.categories), deleted: \(outcome.categoriesDeleted)")
        log("• Products — upsert: \(outcome.products), deleted: \(outcome.productsDeleted)")
    }
    
    private func markAsSeeded() {
        debugImportStorage.didSeed = true
        debugImportStorage.seedVersion = SeedConfig.seedVersion
    }
    
    /// Проверка, что нечего делать (нет ни добавлений, ни обновлений, ни удалений).
    @inline(__always)
    private func isNothingToDo(_ r: DryRunReport) -> Bool {
        (r.brands.new | r.brands.update | r.brands.delete) == 0 &&
        (r.categories.new | r.categories.update | r.categories.delete) == 0 &&
        (r.products.new | r.products.update | r.products.delete) == 0
    }
    
    /// Единый логер с таймстампом.
    @inline(__always)
    private func log(_ message: String) {
        let line = "[\(df.string(from: Date()))] \(message)"
        if let onLog {
            onLog(line)
        } else {
            print(line)
        }
    }
}
