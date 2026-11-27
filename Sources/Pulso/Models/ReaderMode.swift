import Foundation

/// The user's requested operation. None of these operations can access SUBE's
/// protected transport data in this metadata-only version.
enum ReaderMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case balance
    case trips
    case topUp

    static let defaultMode: ReaderMode = .balance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balance: "Consultar saldo"
        case .trips: "Historial"
        case .topUp: "Acreditar carga"
        }
    }

    var instruction: String {
        switch self {
        case .balance: "Acercá tu SUBE al borde superior trasero del iPhone para detectar la tarjeta."
        case .trips: "Acercá la tarjeta cuyos viajes querés consultar y mantenela quieta."
        case .topUp: "Acercá la tarjeta en la que querés acreditar una carga."
        }
    }

    var unavailableTitle: String {
        switch self {
        case .balance: "Saldo no disponible"
        case .trips: "Historial de viajes no disponible"
        case .topUp: "Acreditación no disponible"
        }
    }

    var unavailableMessage: String {
        switch self {
        case .balance:
            "Esta versión detecta el chip, pero todavía no puede leer el saldo protegido de SUBE. No muestra un saldo estimado."
        case .trips:
            "Los viajes no se pueden leer en esta versión. El historial de lecturas es un registro separado de tus escaneos, no de tus viajes."
        case .topUp:
            "Todavía no es posible acreditar cargas con Pulso. Detectar la tarjeta no acredita saldo y no modifica tu SUBE."
        }
    }

    var systemImage: String {
        switch self {
        case .balance: "creditcard"
        case .trips: "clock.arrow.circlepath"
        case .topUp: "arrow.down.to.line"
        }
    }
}

/// A successful metadata read paired with the requested operation. It does not
/// represent a successful balance query, journey query, or credit transaction.
struct ModeScanResult: Identifiable, Sendable {
    let record: ScanRecord
    let mode: ReaderMode

    var id: UUID { record.id }

    init(record: ScanRecord, mode: ReaderMode) {
        var snapshot = record
        snapshot.requestedMode = mode
        self.record = snapshot
        self.mode = mode
    }
}

/// A mode is captured once, when the user starts reading. Results are stamped
/// from this immutable request, never from the selection currently on screen.
struct ScanRequest: Identifiable, Sendable {
    let id: UUID
    let mode: ReaderMode

    init(id: UUID = UUID(), mode: ReaderMode) {
        self.id = id
        self.mode = mode
    }

    func result(from record: ScanRecord) -> ModeScanResult {
        ModeScanResult(record: record, mode: mode)
    }
}
