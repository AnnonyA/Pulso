import Foundation
@preconcurrency import CoreNFC

enum NFCReaderEvent: Sendable {
    case phase(ScanPhase)
    case record(ScanRecord)
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
    private var pendingRequestID: UUID?
    private var isFinishing = false
    private var isConnecting = false
    private var retryScheduled = false
    private var connectionFailures = 0

    init(onEvent: @escaping @MainActor @Sendable (UUID, NFCReaderEvent) -> Void) {
        self.onEvent = onEvent
        super.init()
    }

    func start(requestID: UUID) {
        queue.async { [self] in
            if session != nil {
                if isFinishing {
                    // A successful read may still be dismissing the system sheet.
                    // Wait for didInvalidate before opening another reader session.
                    pendingRequestID = requestID
                } else {
                    emit(.phase(.failed("Ya hay una lectura en curso. Cerrala antes de empezar otra.")), for: requestID)
                }
                return
            }
            begin(requestID: requestID)
        }
    }

    func cancel(requestID: UUID) {
        queue.async { [self] in
            if pendingRequestID == requestID {
                pendingRequestID = nil
                emit(.phase(.cancelled), for: requestID)
                return
            }
            guard self.requestID == requestID, let session, !isFinishing else { return }
            isFinishing = true
            emit(.phase(.cancelled), for: requestID)
            session.invalidate()
        }
    }

    private func begin(requestID: UUID) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard NFCTagReaderSession.readingAvailable else {
            emit(.phase(.failed("NFC no está disponible. Usá un iPhone físico compatible; el simulador no puede leer tarjetas.")), for: requestID)
            return
        }

        self.requestID = requestID
        isFinishing = false
        isConnecting = false
        retryScheduled = false
        connectionFailures = 0

        // This iOS 13+ initializer is supported by the minimum iOS 26 SDK.
        // No guessed ISO7816 AIDs, raw frames, authentication, or writes.
        guard let newSession = NFCTagReaderSession(
            pollingOption: .iso14443,
            delegate: self,
            queue: queue
        ) else {
            self.requestID = nil
            emit(.phase(.failed("No se pudo crear la sesión NFC en este iPhone.")), for: requestID)
            return
        }
        session = newSession
        newSession.alertMessage = "Acercá una sola SUBE a la parte superior trasera del iPhone y mantenela quieta."
        emit(.phase(.scanning), for: requestID)
        newSession.begin()
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard self.session === session, !isFinishing, let requestID else { return }
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
                if let nfcError = error as? NFCReaderError,
                   nfcError.code == .readerErrorSecurityViolation || nfcError.code == .readerErrorUnsupportedFeature {
                    self.fail(self.message(for: error), session: currentSession, requestID: requestID)
                } else if self.connectionFailures < 3 {
                    self.scheduleRetry(message: "Se perdió el contacto. Retirá la tarjeta y volvé a apoyarla arriba, detrás del iPhone.")
                } else {
                    self.fail("No pudimos mantener la conexión. Quitá la funda, separá otras tarjetas e intentá de nuevo. Algunas SUBE no son compatibles con Core NFC.", session: currentSession, requestID: requestID)
                }
                return
            }

            guard let connectedTag = currentSession.connectedTag else {
                self.fail("Se perdió el contacto antes de terminar. Mantené la tarjeta junto al borde superior del iPhone y volvé a intentar.", session: currentSession, requestID: requestID)
                return
            }
            guard let record = self.makeRecord(from: connectedTag) else {
                self.fail("iOS encontró una tarjeta, pero no expone sus metadatos mediante este lector.", session: currentSession, requestID: requestID)
                return
            }

            self.isFinishing = true
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
            if let nfcError = error as? NFCReaderError,
               nfcError.code == .readerSessionInvalidationErrorUserCanceled {
                emit(.phase(.cancelled), for: oldRequestID)
            } else {
                emit(.phase(.failed(message(for: error))), for: oldRequestID)
            }
        }

        if let pendingRequestID {
            self.pendingRequestID = nil
            begin(requestID: pendingRequestID)
        }
    }

    private func scheduleRetry(message: String) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let session, let requestID, !isFinishing, !retryScheduled else { return }
        retryScheduled = true
        session.alertMessage = message
        emit(.phase(.scanning), for: requestID)
        queue.asyncAfter(deadline: .now() + .milliseconds(750)) { [weak self] in
            guard let self, self.requestID == requestID, !self.isFinishing,
                  let currentSession = self.session else { return }
            self.retryScheduled = false
            // Never retain or reuse tags from an earlier polling cycle.
            currentSession.restartPolling()
        }
    }

    private func fail(_ message: String, session: NFCTagReaderSession, requestID: UUID) {
        dispatchPrecondition(condition: .onQueue(queue))
        isFinishing = true
        emit(.phase(.failed(message)), for: requestID)
        session.invalidate(errorMessage: message)
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

    private func message(for error: Error) -> String {
        guard let nfcError = error as? NFCReaderError else {
            return "No se pudo completar la lectura. Retirá la tarjeta y volvé a intentarlo."
        }
        switch nfcError.code {
        case .readerSessionInvalidationErrorSessionTimeout:
            return "Se terminó el tiempo de lectura. Acercá una sola tarjeta a la parte superior trasera del iPhone. Si no aparece, puede usar un protocolo que iOS no admite."
        case .readerSessionInvalidationErrorSystemIsBusy:
            return "El lector NFC está ocupado. Cerrá otras lecturas o Wallet y volvé a intentarlo."
        case .readerErrorSecurityViolation:
            return "La instalación no tiene autorización NFC válida. La firma y el perfil deben incluir la capacidad de lectura NFC."
        case .readerErrorUnsupportedFeature:
            return "Esta función NFC no está disponible en este dispositivo o en esta instalación."
        case .readerErrorRadioDisabled:
            return "iOS informó que la radio NFC no está disponible. Reiniciá el iPhone si el problema continúa."
        case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
            return "iOS interrumpió la lectura. Mantené Pulso abierto y desbloqueado e intentá nuevamente."
        case .readerTransceiveErrorTagConnectionLost:
            return "Se perdió el contacto con la tarjeta. Mantenela quieta junto al borde superior del iPhone."
        case .readerTransceiveErrorSessionInvalidated:
            return "La sesión terminó. Iniciá una nueva lectura."
        default:
            return "No se pudo leer esta tarjeta (código NFC \(nfcError.code.rawValue)). Probá otra posición o una tarjeta compatible."
        }
    }
}
