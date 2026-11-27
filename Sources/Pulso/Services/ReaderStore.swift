import Foundation
import Observation
import CoreNFC
import UIKit

/// UI state is exclusively MainActor-isolated. Core NFC objects stay in NFCReader.
@MainActor
@Observable
final class ReaderStore {
    private(set) var phase: ScanPhase = .idle
    private(set) var latestScan: ScanRecord?
    private(set) var scans: [ScanRecord] = []
    private(set) var historyNotice: String?

    var keepHistory: Bool {
        didSet {
            defaults.set(keepHistory, forKey: Keys.keepHistory)
            if !keepHistory {
                // The current scan can remain visible for this session, but all
                // durable history and the history list are removed immediately.
                scans.removeAll()
                removeStoredHistory()
            }
        }
    }

    var showFullIdentifier: Bool {
        didSet { defaults.set(showFullIdentifier, forKey: Keys.showFullIdentifier) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    var isNFCAvailable: Bool { NFCTagReaderSession.readingAvailable }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let historyURL: URL?
    @ObservationIgnored private var activeRequestID: UUID?
    @ObservationIgnored private var reader: NFCReader?

    private enum Keys {
        static let keepHistory = "pulso.keepHistory"
        static let showFullIdentifier = "pulso.showFullIdentifier"
        static let hapticsEnabled = "pulso.hapticsEnabled"
    }

    private struct HistoryFile: Codable {
        let schemaVersion: Int
        let records: [ScanRecord]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        keepHistory = defaults.object(forKey: Keys.keepHistory) as? Bool ?? true
        showFullIdentifier = defaults.object(forKey: Keys.showFullIdentifier) as? Bool ?? false
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true

        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Pulso", isDirectory: true)
        historyURL = directory?.appendingPathComponent("scan-history.json")

        if keepHistory {
            loadHistory()
        } else {
            // Complete a prior deletion even if the process was killed during it.
            removeStoredHistory()
        }
    }

    func startScan() {
        guard !phase.isActive else { return }
        guard isNFCAvailable else {
            phase = .failed("Para leer tu tarjeta necesitás un iPhone físico con NFC. El simulador permite recorrer la app, pero no escanear.")
            return
        }

        if reader == nil {
            reader = NFCReader { [weak self] requestID, event in
                self?.receive(event, for: requestID)
            }
        }
        let requestID = UUID()
        activeRequestID = requestID
        phase = .scanning
        reader?.start(requestID: requestID)
    }

    /// Also called when the app actually enters the background, never merely
    /// when it becomes inactive while presenting Apple's NFC system sheet.
    func cancelScan() {
        guard let requestID = activeRequestID else { return }
        activeRequestID = nil
        phase = .cancelled
        reader?.cancel(requestID: requestID)
    }

    func resetState() {
        guard !phase.isActive else { return }
        phase = .idle
    }

    func clearHistory() {
        scans.removeAll()
        latestScan = nil
        removeStoredHistory()
    }

    func deleteScan(id: UUID) {
        scans.removeAll { $0.id == id }
        if latestScan?.id == id { latestScan = scans.first }
        persistHistory()
    }

    private func receive(_ event: NFCReaderEvent, for requestID: UUID) {
        guard activeRequestID == requestID else { return }
        switch event {
        case .phase(let phase):
            self.phase = phase
            if !phase.isActive {
                activeRequestID = nil
                if case .failed = phase, hapticsEnabled {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        case .record(let record):
            activeRequestID = nil
            latestScan = record
            phase = .completed
            if keepHistory {
                scans.insert(record, at: 0)
                if scans.count > 50 { scans = Array(scans.prefix(50)) }
                persistHistory()
            }
            if hapticsEnabled {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func loadHistory() {
        guard let historyURL else {
            historyNotice = "No se encontró una ubicación para el historial local."
            return
        }
        guard FileManager.default.fileExists(atPath: historyURL.path) else { return }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: historyURL.path)
            if let size = attributes[.size] as? NSNumber, size.intValue > 1_048_576 {
                historyNotice = "El historial local no tiene el formato esperado. Podés borrarlo desde Ajustes."
                return
            }
            let data = try Data(contentsOf: historyURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let history = try decoder.decode(HistoryFile.self, from: data)
            guard history.schemaVersion == 1 else {
                historyNotice = "Este historial pertenece a otra versión de Pulso. No se pudo abrir."
                return
            }
            var seen = Set<UUID>()
            scans = Array(history.records
                .sorted { $0.scannedAt > $1.scannedAt }
                .filter { seen.insert($0.id).inserted }
                .prefix(50))
            latestScan = scans.first
        } catch {
            historyNotice = "No se pudo abrir el historial local. La lectura NFC sigue disponible."
        }
    }

    private func persistHistory() {
        guard keepHistory else { return }
        guard let historyURL else {
            historyNotice = "No se pudo guardar esta lectura."
            return
        }
        do {
            var directory = historyURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var resources = URLResourceValues()
            resources.isExcludedFromBackup = true
            try directory.setResourceValues(resources)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(HistoryFile(schemaVersion: 1, records: Array(scans.prefix(50))))
            try data.write(to: historyURL, options: [.atomic, .completeFileProtection])
            historyNotice = nil
        } catch {
            historyNotice = "La lectura está en memoria, pero no se pudo guardar en este iPhone."
        }
    }

    private func removeStoredHistory() {
        guard let historyURL else { return }
        do {
            if FileManager.default.fileExists(atPath: historyURL.path) {
                try FileManager.default.removeItem(at: historyURL)
            }
            historyNotice = nil
        } catch {
            historyNotice = "No se pudo borrar el archivo local. Volvé a intentarlo con el iPhone desbloqueado."
        }
    }
}
