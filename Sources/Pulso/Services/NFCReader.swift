import Foundation
@preconcurrency import CoreNFC

enum NFCReaderEvent: Sendable {
    case phase(ScanPhase)
    case record(ScanRecord)
    case diagnostic(NFCDiagnostic)
}

/// All mutable state and Core NFC objects are confined to `queue`.
/// The unchecked conformance bridges Apple's delegate API; no session or tag
/// ever crosses to MainActor. Only immutable Sendable snapshots do.
/// Apple documents that both delegate callbacks and connect completions use
/// the queue supplied to NFCTagReaderSession.
final class NFCReader: NSObject, NFCTagReaderSessionDelegate, @unchecked Sendable {
    private let queue = DispatchQueue(label: "app.pulso.nfc.reader", qos: .userInitiated)
    private let onEvent: @MainActor @Sendable (UUID, NFCReaderEvent) -> Void

    // Queue-confined state. Do not access directly from views or ReaderStore.
    private var session: NFCTagReaderSession?
    private var requestID: UUID?
    private struct RequestContext: Sendable {
        let id: UUID
        let mode: ReaderMode
        let deviceType: String
    }
    private var pendingRequest: RequestContext?
    private var diagnostic: NFCDiagnostic?
    private var isFinishing = false
    private var isConnecting = false
    private var retryScheduled = false
    private var connectionFailures = 0

    init(onEvent: @escaping @MainActor @Sendable (UUID, NFCReaderEvent) -> Void) {
        self.onEvent = onEvent
        super.init()
    }

    /// Uses only public availability APIs. This never creates a reader session,
    /// parses signing files, or obtains device/card identifiers.
    static func captureDiagnostic(
        deviceType: String,
        requestedMode: ReaderMode? = nil,
        stage: NFCDiagnosticStage = .availabilityCheck
    ) -> NFCDiagnostic {
        let usage = Bundle.main.object(forInfoDictionaryKey: "NFCReaderUsageDescription") as? String
        return NFCDiagnostic(
            capturedAt: Date(),
            environment: .current,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Desconocida",
            appBuild: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Desconocido",
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "Desconocido",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceType: deviceType,
            tagReadingAvailable: NFCTagReaderSession.readingAvailable,
            ndefReadingAvailable: NFCNDEFReaderSession.readingAvailable,
            usageDescriptionPresent: !(usage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
            requestedMode: requestedMode,
            stage: stage,
            lastFailure: nil
        )
    }

    func start(requestID: UUID, mode: ReaderMode, deviceType: String) {
        let request = RequestContext(id: requestID, mode: mode, deviceType: deviceType)
        queue.async { [self] in
            if session != nil {
                if isFinishing {
                    // A successful read may still be dismissing the system sheet.
                    // Wait for didInvalidate before opening another reader session.
                    pendingRequest = request
                } else {
                    var snapshot = Self.captureDiagnostic(deviceType: deviceType, requestedMode: mode, stage: .preflight)
                    snapshot.lastFailure = NFCFailureSnapshot(category: .systemBusy, stage: .preflight, requestedMode: mode)
                    emit(.diagnostic(snapshot), for: requestID)
                    emit(.phase(.failed(NFCFailureCategory.systemBusy.message)), for: requestID)
                }
                return
            }
            begin(request)
        }
    }

    func cancel(requestID: UUID) {
        queue.async { [self] in
            if pendingRequest?.id == requestID {
                pendingRequest = nil
                emit(.phase(.cancelled), for: requestID)
                return
            }
            guard self.requestID == requestID, let session, !isFinishing else { return }
            isFinishing = true
            publishDiagnostic(stage: .cancelled, for: requestID)
            emit(.phase(.cancelled), for: requestID)
            session.invalidate()
        }
    }

    private func begin(_ request: RequestContext) {
        dispatchPrecondition(condition: .onQueue(queue))
        let requestID = request.id
        // Re-evaluate on every attempt, including requests queued while the
        // preceding iOS sheet was being dismissed. No cached availability flag.
        diagnostic = Self.captureDiagnostic(deviceType: request.deviceType, requestedMode: request.mode, stage: .preflight)
        guard let snapshot = diagnostic else { return }
        if let failureCategory = snapshot.readiness.failureCategory {
            let failure = NFCFailureSnapshot(category: failureCategory, stage: .preflight)
            publishDiagnostic(stage: .failed, failure: failure, for: requestID)
            emit(.phase(.failed(failure.message)), for: requestID)
            return
        }

        self.requestID = requestID
        isFinishing = false
        isConnecting = false
        retryScheduled = false
        connectionFailures = 0
        publishDiagnostic(stage: .sessionCreation, for: requestID)

        // This iOS 13+ initializer is supported by the minimum iOS 26 SDK.
        // No guessed ISO7816 AIDs, raw frames, authentication, or writes.
        guard let newSession = NFCTagReaderSession(
            pollingOption: .iso14443,
            delegate: self,
            queue: queue
        ) else {
            self.requestID = nil
            let failure = NFCFailureSnapshot(category: .sessionCreation, stage: .sessionCreation)
            publishDiagnostic(stage: .failed, failure: failure, for: requestID)
            emit(.phase(.failed(failure.message)), for: requestID)
            return
        }
        session = newSession
        newSession.alertMessage = "Acercá una sola SUBE a la parte superior trasera del iPhone y mantenela quieta."
        publishDiagnostic(stage: .starting, for: requestID)
        emit(.phase(.scanning), for: requestID)
        newSession.begin()
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard self.session === session, !isFinishing, let requestID else { return }
        publishDiagnostic(stage: .active, for: requestID)
        emit(.phase(.scanning), for: requestID)
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard self.session === session, !isFinishing, !isConnecting, !retryScheduled,
              let requestID else { return }

        guard tags.count == 1, let tag = tags.first else {
            scheduleRetry(message: "Hay más de una tarjeta cerca. Separalas y acercá solamente la que querés leer.")
            return
        }

        isConnecting = true
        publishDiagnostic(stage: .connecting, for: requestID)
        emit(.phase(.connecting), for: requestID)
        session.alertMessage = "Tarjeta encontrada. Mantenela quieta un momento."
        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            dispatchPrecondition(condition: .onQueue(self.queue))
            // The callback runs on `queue`. Recover the current session and tag
            // there instead of capturing Apple's non-Sendable NFC objects in
            // the completion closure. Each UUID names exactly one session.
            guard self.requestID == requestID, !self.isFinishing, self.isConnecting,
                  let currentSession = self.session else { return }
            self.isConnecting = false

            if let error {
                self.connectionFailures += 1
                let failure = Self.failure(for: error, stage: .connecting)
                self.publishDiagnostic(stage: .connecting, failure: failure, for: requestID)
                let canRetry = failure.category == .connectionLost || failure.category == .unknown
                if canRetry && self.connectionFailures < 3 {
                    self.scheduleRetry(message: "Se perdió el contacto. Retirá la tarjeta y volvé a apoyarla arriba, detrás del iPhone.")
                } else {
                    self.fail(failure, session: currentSession, requestID: requestID)
                }
                return
            }

            guard let connectedTag = currentSession.connectedTag else {
                self.fail(NFCFailureSnapshot(category: .connectionLost, stage: .connecting), session: currentSession, requestID: requestID)
                return
            }
            self.publishDiagnostic(stage: .readingMetadata, for: requestID)
            guard let record = self.makeRecord(from: connectedTag) else {
                self.fail(NFCFailureSnapshot(category: .metadataUnavailable, stage: .readingMetadata), session: currentSession, requestID: requestID)
                return
            }

            self.isFinishing = true
            self.diagnostic?.lastFailure = nil
            self.publishDiagnostic(stage: .metadataRead, for: requestID)
            self.emit(.record(record), for: requestID)
            currentSession.alertMessage = "Tarjeta detectada. El saldo, los viajes y la acreditación no están disponibles en esta versión."
            currentSession.invalidate()
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard self.session === session else { return }
        let oldRequestID = requestID
        let alreadyFinished = isFinishing
        self.session = nil
        requestID = nil
        isConnecting = false
        retryScheduled = false
        isFinishing = false

        if !alreadyFinished, let oldRequestID {
            let failure = Self.failure(for: error, stage: diagnostic?.stage ?? .starting)
            if failure.category == .cancelled {
                publishDiagnostic(stage: .cancelled, failure: failure, for: oldRequestID)
                emit(.phase(.cancelled), for: oldRequestID)
            } else {
                publishDiagnostic(stage: .failed, failure: failure, for: oldRequestID)
                emit(.phase(.failed(failure.message)), for: oldRequestID)
            }
        }

        if let pendingRequest {
            self.pendingRequest = nil
            begin(pendingRequest)
        }
    }

    private func scheduleRetry(message: String) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let session, let requestID, !isFinishing, !retryScheduled else { return }
        retryScheduled = true
        session.alertMessage = message
        publishDiagnostic(stage: .active, for: requestID)
        emit(.phase(.scanning), for: requestID)
        queue.asyncAfter(deadline: .now() + .milliseconds(750)) { [weak self] in
            guard let self, self.requestID == requestID, !self.isFinishing,
                  let currentSession = self.session else { return }
            self.retryScheduled = false
            // Never retain or reuse tags from an earlier polling cycle.
            currentSession.restartPolling()
        }
    }

    private func fail(_ failure: NFCFailureSnapshot, session: NFCTagReaderSession, requestID: UUID) {
        dispatchPrecondition(condition: .onQueue(queue))
        isFinishing = true
        let cancelled = failure.category == .cancelled
        publishDiagnostic(stage: cancelled ? .cancelled : .failed, failure: failure, for: requestID)
        emit(.phase(cancelled ? .cancelled : .failed(failure.message)), for: requestID)
        if cancelled {
            session.invalidate()
        } else {
            session.invalidate(errorMessage: failure.message)
        }
    }

    private func publishDiagnostic(
        stage: NFCDiagnosticStage,
        failure: NFCFailureSnapshot? = nil,
        for requestID: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard var snapshot = diagnostic else { return }
        snapshot.capturedAt = Date()
        snapshot.stage = stage
        if var failure = failure {
            failure.requestedMode = snapshot.requestedMode
            snapshot.lastFailure = failure
        }
        diagnostic = snapshot
        // Always precedes the terminal phase/record event; ReaderStore still
        // owns the same request UUID when this immutable snapshot arrives.
        emit(.diagnostic(snapshot), for: requestID)
    }

    private func emit(_ event: NFCReaderEvent, for requestID: UUID) {
        // Dispatch preserves event order from the serial session queue.
        let handler = onEvent
        DispatchQueue.main.async { handler(requestID, event) }
    }

    private func makeRecord(from tag: NFCTag) -> ScanRecord? {
        let commonNotes = [
            "El identificador NFC no es el número impreso en tu SUBE.",
            "La fecha corresponde a esta lectura, no a un viaje.",
            "No se autenticó la tarjeta ni se leyeron sectores protegidos.",
            "No se determinó el modelo exacto del chip ni su nivel de seguridad."
        ]

        switch tag {
        case .miFare(let mifare):
            let family: String
            switch mifare.mifareFamily {
            case .plus: family = "MIFARE Plus"
            case .desfire: family = "MIFARE DESFire"
            case .ultralight: family = "MIFARE Ultralight"
            case .unknown: family = "ISO 14443-A compatible"
            @unknown default: family = "MIFARE sin identificar"
            }
            return ScanRecord(
                technology: "ISO 14443-A",
                family: family,
                uidHex: hex(mifare.identifier),
                historicalBytesHex: nonemptyHex(mifare.historicalBytes),
                notes: commonNotes + ["La familia informada por iOS no confirma que el emisor sea SUBE."]
            )

        case .iso7816(let iso7816):
            // No AIDs are declared in this build. This defensive branch handles
            // an ISO7816 object only if the operating system supplies one; it
            // does not make unsupported cards discoverable.
            return ScanRecord(
                technology: "ISO 14443 / ISO 7816",
                family: "ISO 7816",
                uidHex: hex(iso7816.identifier),
                historicalBytesHex: nonemptyHex(iso7816.historicalBytes),
                applicationDataHex: nonemptyHex(iso7816.applicationData),
                selectedAID: iso7816.initialSelectedAID.isEmpty ? nil : iso7816.initialSelectedAID,
                notes: commonNotes + ["No se enviaron comandos APDU ni se seleccionaron aplicaciones desde Pulso."]
            )

        case .iso15693, .feliCa:
            // These cannot normally be delivered by .iso14443 polling.
            return nil
        @unknown default:
            return nil
        }
    }

    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined()
    }

    private func nonemptyHex(_ data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        return hex(data)
    }

    private static func failure(for error: Error, stage: NFCDiagnosticStage) -> NFCFailureSnapshot {
        let nsError = error as NSError
        var category: NFCFailureCategory?
        // Core NFC's numeric error values are meaningful only in its domain.
        if nsError.domain == NFCErrorDomain, let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorSessionTimeout: category = .timeout
            case .readerSessionInvalidationErrorSystemIsBusy: category = .systemBusy
            case .readerErrorSecurityViolation: category = .securityViolation
            case .readerErrorUnsupportedFeature: category = .unsupportedFeature
            case .readerErrorRadioDisabled: category = .radioDisabled
            case .readerErrorAccessNotAccepted: category = .accessNotAccepted
            case .readerErrorIneligible: category = .ineligible
            case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly: category = .sessionInterrupted
            case .readerTransceiveErrorTagConnectionLost, .readerTransceiveErrorTagNotConnected: category = .connectionLost
            case .readerTransceiveErrorSessionInvalidated: category = .sessionInvalidated
            case .readerSessionInvalidationErrorUserCanceled: category = .cancelled
            default: category = .unknown
            }
        }
        return NFCFailureSnapshot.systemError(
            domain: nsError.domain,
            code: nsError.code,
            description: nsError.localizedDescription,
            expectedNFCDomain: NFCErrorDomain,
            nfcCategory: category,
            stage: stage
        )
    }
}
