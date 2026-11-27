import Foundation

/// State of a real reader session. A completed session means metadata was read,
/// not that a SUBE was verified or its balance was obtained.
enum ScanPhase: Equatable, Sendable {
    case idle
    case scanning
    case connecting
    case completed
    case cancelled
    case failed(String)

    var isActive: Bool {
        switch self {
        case .scanning, .connecting: true
        case .idle, .completed, .cancelled, .failed: false
        }
    }
}

/// A snapshot of public Core NFC properties, captured after a successful connect.
/// There is deliberately no balance, journey time, printed card number, or
/// authenticated issuer field: this build cannot obtain those values.
struct ScanRecord: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var scannedAt: Date
    var technology: String
    var family: String
    var uidHex: String
    var historicalBytesHex: String?
    var applicationDataHex: String?
    var selectedAID: String?
    var notes: [String]

    init(
        id: UUID = UUID(),
        scannedAt: Date = Date(),
        technology: String,
        family: String,
        uidHex: String,
        historicalBytesHex: String? = nil,
        applicationDataHex: String? = nil,
        selectedAID: String? = nil,
        notes: [String] = []
    ) {
        self.id = id
        self.scannedAt = scannedAt
        self.technology = technology
        self.family = family
        self.uidHex = uidHex
        self.historicalBytesHex = historicalBytesHex
        self.applicationDataHex = applicationDataHex
        self.selectedAID = selectedAID
        self.notes = notes
    }

    var maskedIdentifier: String {
        let compact = uidHex.filter { !$0.isWhitespace }
        guard compact.count > 4 else { return "Oculto" }
        return "•••• " + compact.suffix(4).uppercased()
    }

    /// A family-level research hint only. Never show this as “SUBE verificada”.
    var canBeSUBE: Bool {
        family == "MIFARE Plus"
    }

    /// Sharing never silently follows the on-screen “show full UID” preference.
    var shareSummary: String {
        """
        Pulso · Diagnóstico NFC
        Fecha de lectura: \(scannedAt.formatted(.iso8601))
        Tecnología: \(technology)
        Familia informada por iOS: \(family)
        Identificador NFC: \(maskedIdentifier)
        Emisor SUBE: sin verificar
        Saldo: no disponible
        Último viaje: no disponible
        Lectura de metadatos públicos, sin autenticación ni escritura.
        La fecha corresponde al escaneo, no a un viaje.
        """
    }

    /// Stable diagnostic export. Raw identifiers and low-level metadata require
    /// an explicit choice; the export never contains guessed transit data.
    func diagnosticJSON(includeIdentifier: Bool) -> String {
        struct Diagnostic: Encodable {
            let schemaVersion: Int
            let app: String
            let source: String
            let scannedAt: Date
            let technology: String
            let family: String
            let identifierRedacted: Bool
            let maskedIdentifier: String
            let uidHex: String?
            let historicalBytesHex: String?
            let applicationDataHex: String?
            let selectedAID: String?
            let subeVerified: Bool
            let balanceStatus: String
            let lastTripStatus: String
            let notes: [String]
        }

        let value = Diagnostic(
            schemaVersion: 1,
            app: "Pulso",
            source: "Core NFC · public tag metadata",
            scannedAt: scannedAt,
            technology: technology,
            family: family,
            identifierRedacted: !includeIdentifier,
            maskedIdentifier: maskedIdentifier,
            uidHex: includeIdentifier ? uidHex : nil,
            historicalBytesHex: includeIdentifier ? historicalBytesHex : nil,
            applicationDataHex: includeIdentifier ? applicationDataHex : nil,
            selectedAID: includeIdentifier ? selectedAID : nil,
            subeVerified: false,
            balanceStatus: "unavailable_without_authorized_access",
            lastTripStatus: "unavailable_without_authorized_access",
            notes: notes
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value), let json = String(data: data, encoding: .utf8) else {
            return "{\"error\":\"No se pudo preparar el diagnóstico.\"}"
        }
        return json
    }
}
