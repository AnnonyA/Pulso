import Foundation

/// A build target is independent of Core NFC availability. In particular,
/// `readingAvailable == false` on an iPhone never means "simulator".
enum NFCExecutionEnvironment: String, Codable, Sendable {
    case device
    case simulator

    static var current: Self {
        #if targetEnvironment(simulator)
        .simulator
        #else
        .device
        #endif
    }

    var displayName: String {
        switch self {
        case .device: "Dispositivo iOS"
        case .simulator: "Simulador"
        }
    }
}

enum NFCReadiness: String, Codable, Sendable {
    case ready
    case simulator
    case unavailable
    case missingUsageDescription

    /// Pure policy shared by the real reader and the diagnostic screen.
    /// This function deliberately cannot certify the app's signing permission.
    static func evaluate(
        environment: NFCExecutionEnvironment,
        tagReadingAvailable: Bool,
        usageDescriptionPresent: Bool
    ) -> Self {
        if environment == .simulator { return .simulator }
        if !usageDescriptionPresent { return .missingUsageDescription }
        return tagReadingAvailable ? .ready : .unavailable
    }

    var failureCategory: NFCFailureCategory? {
        switch self {
        case .ready: nil
        case .simulator: .simulator
        case .unavailable: .deviceUnavailable
        case .missingUsageDescription: .missingUsageDescription
        }
    }

    var title: String {
        failureCategory?.title ?? "Disponible para intentar una lectura"
    }

    var message: String {
        failureCategory?.message ?? "iOS informa disponibilidad para iniciar una sesión. Esto todavía no confirma el permiso NFC de la instalación ni la compatibilidad de la tarjeta."
    }
}

enum NFCDiagnosticStage: String, Codable, Sendable {
    case availabilityCheck
    case preflight
    case sessionCreation
    case starting
    case active
    case connecting
    case readingMetadata
    case metadataRead
    case cancelled
    case failed

    var displayName: String {
        switch self {
        case .availabilityCheck: "Comprobación de disponibilidad"
        case .preflight: "Comprobación previa a la lectura"
        case .sessionCreation: "Creación de la sesión"
        case .starting: "Inicio de la sesión"
        case .active: "Buscando una tarjeta"
        case .connecting: "Conexión con la tarjeta"
        case .readingMetadata: "Obtención de metadatos públicos"
        case .metadataRead: "Metadatos públicos obtenidos"
        case .cancelled: "Lectura cancelada"
        case .failed: "Lectura interrumpida por un error"
        }
    }
}

enum NFCFailureCategory: String, Codable, Sendable {
    case simulator
    case deviceUnavailable
    case missingUsageDescription
    case sessionCreation
    case securityViolation
    case radioDisabled
    case systemBusy
    case unsupportedFeature
    case accessNotAccepted
    case ineligible
    case timeout
    case sessionInterrupted
    case connectionLost
    case sessionInvalidated
    case metadataUnavailable
    case cancelled
    case unknown

    var title: String {
        switch self {
        case .simulator: "Lectura NFC en simulador"
        case .deviceUnavailable: "Lectura NFC no disponible"
        case .missingUsageDescription: "Configuración NFC incompleta"
        case .sessionCreation: "No se pudo abrir el lector"
        case .securityViolation: "Acceso NFC rechazado"
        case .radioDisabled: "Radio NFC deshabilitada"
        case .systemBusy: "Lector NFC ocupado"
        case .unsupportedFeature: "Función NFC no compatible"
        case .accessNotAccepted: "Acceso NFC no aceptado"
        case .ineligible: "Sesión NFC no habilitada"
        case .timeout: "Se agotó el tiempo de lectura"
        case .sessionInterrupted: "iOS interrumpió la lectura"
        case .connectionLost: "Se perdió el contacto"
        case .sessionInvalidated: "La sesión NFC terminó"
        case .metadataUnavailable: "Metadatos no disponibles"
        case .cancelled: "Lectura cancelada"
        case .unknown: "No se pudo completar la lectura"
        }
    }

    var message: String {
        switch self {
        case .simulator:
            "Esta compilación está ejecutándose en un simulador. El simulador permite recorrer la app, pero no escanear."
        case .deviceUnavailable:
            "iOS informó que la lectura NFC no está disponible en este iPhone. Ese resultado no identifica la causa. Podés reintentar o compartir el diagnóstico. Revisá también que la firma y el perfil de esta instalación permitan NFC TAG."
        case .missingUsageDescription:
            "Falta la descripción de uso NFC de esta compilación. Se necesita una versión con la configuración corregida."
        case .sessionCreation:
            "Core NFC no pudo crear la sesión de lectura. Podés volver a intentar y compartir el diagnóstico."
        case .securityViolation:
            "iOS rechazó el acceso NFC por seguridad. Revisá que la firma y el perfil de esta instalación permitan NFC TAG. El diagnóstico conserva el error informado por iOS."
        case .radioDisabled:
            "iOS informó que la radio NFC está deshabilitada. Si activaste el modo avión, desactivalo y volvé a intentar. Si persiste, reiniciá el iPhone."
        case .systemBusy:
            "iOS no pudo atender esta sesión porque el lector está ocupado. Cerrá otras sesiones de lectura y volvé a intentarlo."
        case .unsupportedFeature:
            "iOS indicó que la función solicitada no está disponible en esta sesión o instalación. Podés compartir el diagnóstico para revisar el error."
        case .accessNotAccepted:
            "iOS no aceptó el acceso solicitado a NFC. El diagnóstico conserva el código del sistema para investigar la causa."
        case .ineligible:
            "iOS indicó que esta sesión no reúne las condiciones para acceder a NFC. Ese código por sí solo no identifica qué condición falta."
        case .timeout:
            "Se terminó el tiempo de lectura. Acercá una sola tarjeta a la parte superior trasera del iPhone. Si no aparece, puede usar un protocolo que iOS no admite."
        case .sessionInterrupted:
            "iOS interrumpió la lectura. Mantené Pulso abierto y el iPhone desbloqueado, y volvé a intentarlo."
        case .connectionLost:
            "Se perdió el contacto con la tarjeta. Mantenela quieta junto al borde superior trasero del iPhone y volvé a intentar. Algunas tarjetas no son compatibles con Core NFC."
        case .sessionInvalidated:
            "La sesión NFC terminó antes de completar la operación. Iniciá una nueva lectura."
        case .metadataUnavailable:
            "iOS encontró una tarjeta, pero no expone sus metadatos mediante este lector."
        case .cancelled:
            "La lectura fue cancelada. Podés iniciar otra cuando quieras."
        case .unknown:
            "Se produjo un error que Pulso no puede clasificar. Podés reintentar y compartir el diagnóstico para revisar el dominio y el código informados por el sistema."
        }
    }
}

/// No raw userInfo, card bytes, UID, device name or persistent identifier.
struct NFCFailureSnapshot: Codable, Equatable, Sendable {
    var category: NFCFailureCategory
    var stage: NFCDiagnosticStage
    var occurredAt: Date
    var domain: String?
    var code: Int?
    var errorDescription: String?
    var requestedMode: ReaderMode?

    init(
        category: NFCFailureCategory,
        stage: NFCDiagnosticStage,
        occurredAt: Date = Date(),
        domain: String? = nil,
        code: Int? = nil,
        errorDescription: String? = nil,
        requestedMode: ReaderMode? = nil
    ) {
        self.category = category
        self.stage = stage
        self.occurredAt = occurredAt
        self.domain = domain
        self.code = code
        self.errorDescription = errorDescription.map { String($0.prefix(512)) }
        self.requestedMode = requestedMode
    }

    /// Apple enum cases are mapped by the Core NFC adapter. Matching numeric
    /// values from a different NSError domain must never inherit that meaning.
    static func systemError(
        domain: String,
        code: Int,
        description: String,
        expectedNFCDomain: String,
        nfcCategory: NFCFailureCategory?,
        stage: NFCDiagnosticStage,
        occurredAt: Date = Date()
    ) -> Self {
        Self(
            category: domain == expectedNFCDomain ? (nfcCategory ?? .unknown) : .unknown,
            stage: stage,
            occurredAt: occurredAt,
            domain: domain,
            code: code,
            errorDescription: description
        )
    }

    var title: String { category.title }
    var message: String { category.message }
}

/// A local snapshot can exist without any tag detection or NFC session.
struct NFCDiagnostic: Codable, Equatable, Sendable {
    var capturedAt: Date
    var environment: NFCExecutionEnvironment
    var appVersion: String
    var appBuild: String
    var bundleIdentifier: String
    var osVersion: String
    var deviceType: String
    var tagReadingAvailable: Bool
    var ndefReadingAvailable: Bool
    var usageDescriptionPresent: Bool
    var requestedMode: ReaderMode?
    var stage: NFCDiagnosticStage
    var lastFailure: NFCFailureSnapshot?

    var readiness: NFCReadiness {
        .evaluate(
            environment: environment,
            tagReadingAvailable: tagReadingAvailable,
            usageDescriptionPresent: usageDescriptionPresent
        )
    }

    /// Refreshing availability does not erase the last observed error.
    func preservingFailure(from previous: NFCDiagnostic?) -> Self {
        var result = self
        result.lastFailure = previous?.lastFailure ?? lastFailure
        return result
    }

    var summaryText: String {
        var lines = [
            "Pulso · Diagnóstico de disponibilidad NFC",
            "Fecha: \(capturedAt.formatted(.iso8601))",
            "Entorno: \(environment.displayName)",
            "Dispositivo: \(deviceType)",
            "Sistema: \(osVersion)",
            "Pulso: \(appVersion) (\(appBuild))",
            "Identificador de la app: \(bundleIdentifier)",
            "Operación: \(requestedMode?.title ?? "Comprobación sin tarjeta")",
            "Lectura de tarjetas disponible: \(tagReadingAvailable ? "Sí" : "No")",
            "Lectura NDEF disponible (dato auxiliar): \(ndefReadingAvailable ? "Sí" : "No")",
            "Descripción de uso NFC presente: \(usageDescriptionPresent ? "Sí" : "No")",
            "Fase: \(stage.displayName)",
            "Estado: \(readiness.title)",
            "Firma y permiso NFC: no verificados por este diagnóstico."
        ]
        if let failure = lastFailure {
            lines += [
                "Último resultado: \(failure.title)",
                "Fecha del último resultado: \(failure.occurredAt.formatted(.iso8601))",
                "Fase del último resultado: \(failure.stage.displayName)",
                "Operación del último resultado: \(failure.requestedMode?.title ?? "No indicada")",
                failure.message
            ]
            if let domain = failure.domain { lines.append("Dominio del error: \(domain)") }
            if let code = failure.code { lines.append("Código del error: \(code)") }
            if let description = failure.errorDescription { lines.append("Descripción del sistema: \(description)") }
        }
        lines.append("Este informe no contiene datos de una tarjeta ni prueba una lectura física.")
        return lines.joined(separator: "\n")
    }

    var exportJSON: String {
        struct Export: Encodable {
            let schemaVersion: Int
            let source: String
            let authorizationStatus: String
            let cardDataIncluded: Bool
            let readiness: NFCReadiness
            let diagnostic: NFCDiagnostic
        }
        let value = Export(
            schemaVersion: 1,
            source: "Core NFC availability and session diagnostics",
            authorizationStatus: "not_verified",
            cardDataIncluded: false,
            readiness: readiness,
            diagnostic: self
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value), let json = String(data: data, encoding: .utf8) else {
            return "{\"error\":\"No se pudo preparar el diagnóstico NFC.\"}"
        }
        return json
    }
}
