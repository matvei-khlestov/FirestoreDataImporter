//
//  FirestoreImportViewModel.swift
//  FirestoreDataImporter
//
//  Created by Matvei Khlestov on 06.01.2026.
//

import Foundation

final class FirestoreImportViewModel: FirestoreImportViewModelProtocol {
    
    // MARK: - Properties
    
    private(set) var state: FirestoreImportState {
        didSet { onStateChange?(state) }
    }
    
    private let debugImportStorage: FirestoreImportStoringProtocol
    private let debugImporter: FirestoreImportingProtocol
    
    var onStateChange: ((FirestoreImportState) -> Void)?
    
    // MARK: - Init
    
    init(
        debugImportStorage: FirestoreImportStoringProtocol,
        debugImporter: FirestoreImportingProtocol
    ) {
        self.debugImportStorage = debugImportStorage
        self.debugImporter = debugImporter
        
        let didRun = debugImportStorage.didRunOnce
        let overwrite = debugImportStorage.isOverwriteEnabled
        let version = debugImportStorage.requiredSeedVersion
        
        self.state = FirestoreImportState(
            hasRunBefore: didRun,
            isEnabledFlag: SeedConfig.isEnabled,
            overwrite: overwrite,
            seedVersion: version
        )
        
        bindImporterLogsIfPossible()
    }
    
    deinit {
        (debugImporter as? FirestoreImportLogEmitting)?.onLog = nil
    }
    
    // MARK: - Public Methods
    
    func setImporterEnabled(_ isOn: Bool) {
        SeedConfig.isEnabled = isOn
        state.isEnabledFlag = isOn
        refreshDerivedState()
        append("⚙️ DebugImporter.enabled = \(isOn)")
    }
    
    func setOverwrite(_ isOn: Bool) {
        state.overwrite = isOn
        debugImportStorage.isOverwriteEnabled = isOn
        append("⚙️ Overwrite = \(isOn)")
    }
    
    func setSeedVersion(_ version: Int) {
        let newValue = max(1, version)
        debugImportStorage.requiredSeedVersion = newValue
        state.seedVersion = newValue
        append("🏷️ Версия сид-данных = \(newValue)")
    }
    
    func bumpSeedVersion(by delta: Int) {
        setSeedVersion(state.seedVersion + delta)
    }
    
    func runImport() {
        guard !state.isRunning else { return }
        state.isRunning = true
        append("⏳ Запуск импорта…")
        
        Task { [weak self] in
            guard let self else { return }
            
            await self.debugImporter.runIfNeeded(
                overwrite: self.state.overwrite,
                checksumNamespace: SeedConfig.checksumNamespace,
                pruneMissing: true
            )
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.refreshDerivedState()
                self.state.isRunning = false
                self.append("✅ Завершено.")
            }
        }
    }
    
    func resetMarkers() {
        debugImporter.resetMarkers()
        refreshDerivedState()
        append("🔄 Маркеры импорта сброшены (можно запускать снова).")
    }
    
    // MARK: - Private Methods
    
    private func bindImporterLogsIfPossible() {
        guard let emitter = debugImporter as? FirestoreImportLogEmitting else { return }
        
        emitter.onLog = { [weak self] line in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.append(line)
            }
        }
    }
    
    private func append(_ line: String) {
        let prefix = state.log.isEmpty ? "" : "\n"
        state.log.append("\(prefix)\(line)")
    }
    
    private func refreshDerivedState() {
        state.hasRunBefore = debugImportStorage.didRunOnce
        state.isEnabledFlag = SeedConfig.isEnabled
        state.overwrite = debugImportStorage.isOverwriteEnabled
        state.seedVersion = debugImportStorage.requiredSeedVersion
        state.hasRunBefore = debugImportStorage.didRunOnce && state.isEnabledFlag
    }
}
