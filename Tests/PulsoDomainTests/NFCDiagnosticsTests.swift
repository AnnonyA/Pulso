import Foundation
import Testing
@testable import PulsoDomain

private let diagnosticDate = Date(timeIntervalSince1970: 1_700_000_000)

private func diagnostic(
    environment: NFCExecutionEnvironment = .device,
    tagAvailable: Bool = false,
    ndefAvailable: Bool = false,
    usageDescription: Bool = true,
    failure: NFCFailureSnapshot? = nil
) -> NFCDiagnostic {
    NFCDiagnostic(
        capturedAt: diagnosticDate,
        environment: environment,
        appVersion: "0.2.1",
        appBuild: "3",
        bundleIdentifier: "app.pulso.nfcreader",
        osVersion: "iOS 26.0",
        deviceType: "iPhone",
        tagReadingAvailable: tagAvailable,
        ndefReadingAvailable: ndefAvailable,
        usageDescriptionPresent: usageDescription,
        requestedMode: .balance,
        stage: .preflight,
        lastFailure: failure
    )
}

@Test("A physical iPhone with unavailable NFC is never called a simulator")
func unavailableDeviceRegression() {
    for ndefAvailable in [false, true] {
        let snapshot = diagnostic(ndefAvailable: ndefAvailable)
        #expect(snapshot.readiness == .unavailable)
        #expect(snapshot.readiness.failureCategory == .deviceUnavailable)
        #expect(!snapshot.readiness.message.localizedCaseInsensitiveContains("simulador"))
        #expect(!snapshot.summaryText.localizedCaseInsensitiveContains("simulador"))
        #expect(!snapshot.exportJSON.contains("simulator"))
        #expect(snapshot.readiness.message.contains("no identifica la causa"))
    }
}

@Test("Simulator classification uses the target environment, not availability")
func simulatorIsIndependentOfAvailability() {
    for available in [false, true] {
        let snapshot = diagnostic(environment: .simulator, tagAvailable: available, ndefAvailable: available)
        #expect(snapshot.readiness == .simulator)
        #expect(snapshot.readiness.message.contains("El simulador permite recorrer la app, pero no escanear."))
    }
}

@Test("NDEF availability never substitutes for native tag availability")
func ndefDoesNotEnableTagReading() {
    #expect(diagnostic(tagAvailable: false, ndefAvailable: true).readiness == .unavailable)
    #expect(diagnostic(tagAvailable: true, ndefAvailable: false).readiness == .ready)
}

@Test("A missing usage description blocks creation even when NFC reports support")
func missingUsageDescriptionStopsPreflight() {
    let snapshot = diagnostic(tagAvailable: true, usageDescription: false)
    #expect(snapshot.readiness == .missingUsageDescription)
    #expect(snapshot.readiness.failureCategory == .missingUsageDescription)
    #expect(!snapshot.readiness.message.localizedCaseInsensitiveContains("simulador"))
}

@Test("New availability samples are reevaluated rather than permanently cached")
func availabilityCanRecoverOrBecomeUnavailable() {
    var snapshot = diagnostic()
    #expect(snapshot.readiness == .unavailable)
    snapshot.tagReadingAvailable = true
    #expect(snapshot.readiness == .ready)
    #expect(snapshot.readiness.failureCategory == nil)
    snapshot.tagReadingAvailable = false
    #expect(snapshot.readiness == .unavailable)
}

@Test("Availability is not exported as NFC signing authorization")
func readyDoesNotClaimAuthorization() throws {
    let snapshot = diagnostic(tagAvailable: true)
    let object = try #require(JSONSerialization.jsonObject(with: Data(snapshot.exportJSON.utf8)) as? [String: Any])
    #expect(object["readiness"] as? String == "ready")
    #expect(object["authorizationStatus"] as? String == "not_verified")
    #expect(snapshot.summaryText.contains("Firma y permiso NFC: no verificados"))
    #expect(snapshot.readiness.message.contains("no confirma el permiso NFC"))
}

@Test("An identical numeric code from another domain is not a Core NFC failure")
func errorDomainMustMatchBeforeClassification() {
    let nfc = NFCFailureSnapshot.systemError(
        domain: "NFCError", code: 2, description: "Missing required entitlement",
        expectedNFCDomain: "NFCError", nfcCategory: .securityViolation,
        stage: .starting, occurredAt: diagnosticDate
    )
    let other = NFCFailureSnapshot.systemError(
        domain: "NSCocoaErrorDomain", code: 2, description: "Unrelated operation failed",
        expectedNFCDomain: "NFCError", nfcCategory: .securityViolation,
        stage: .starting, occurredAt: diagnosticDate
    )
    #expect(nfc.category == .securityViolation)
    #expect(other.category == .unknown)
    #expect(other.domain == "NSCocoaErrorDomain")
    #expect(other.code == 2)
    #expect(other.errorDescription == "Unrelated operation failed")
    #expect(!other.message.contains("firma"))
}

@Test("System errors retain distinct recovery guidance without invented causes")
func errorGuidanceIsSpecificAndNeutral() {
    let categories: [NFCFailureCategory] = [.radioDisabled, .securityViolation, .systemBusy, .timeout, .cancelled, .unsupportedFeature, .accessNotAccepted, .ineligible, .unknown]
    #expect(Set(categories.map(\.title)).count == categories.count)
    #expect(categories.allSatisfy { !$0.message.localizedCaseInsensitiveContains("simulador") })
    #expect(NFCFailureCategory.radioDisabled.message.contains("Si activaste el modo avión"))
    #expect(NFCFailureCategory.securityViolation.message.contains("iOS rechazó"))
    #expect(!NFCFailureCategory.securityViolation.message.contains("La instalación no tiene autorización"))
    #expect(NFCFailureCategory.ineligible.message.contains("no identifica qué condición falta"))
    #expect(NFCFailureCategory.cancelled.title == "Lectura cancelada")
}

@Test("A manual availability refresh preserves the last failure and its operation")
func refreshPreservesErrorEvidence() {
    let failure = NFCFailureSnapshot(
        category: .securityViolation, stage: .starting, occurredAt: diagnosticDate,
        domain: "NFCError", code: 2, errorDescription: "Missing required entitlement", requestedMode: .balance
    )
    let previous = diagnostic(failure: failure)
    var fresh = diagnostic(tagAvailable: true)
    fresh.capturedAt = diagnosticDate.addingTimeInterval(60)
    fresh.stage = .availabilityCheck
    fresh.requestedMode = .trips
    let refreshed = fresh.preservingFailure(from: previous)
    #expect(refreshed.readiness == .ready)
    #expect(refreshed.capturedAt > previous.capturedAt)
    #expect(refreshed.lastFailure == failure)
    #expect(refreshed.lastFailure?.requestedMode == .balance)
    #expect(refreshed.requestedMode == .trips)
    #expect(refreshed.summaryText.contains("Missing required entitlement"))
}

@Test("A useful availability report exports without any detected card")
func reportDoesNotRequireCardData() throws {
    let snapshot = diagnostic()
    let object = try #require(JSONSerialization.jsonObject(with: Data(snapshot.exportJSON.utf8)) as? [String: Any])
    let payload = try #require(object["diagnostic"] as? [String: Any])
    #expect(object["schemaVersion"] as? Int == 1)
    #expect(object["cardDataIncluded"] as? Bool == false)
    #expect(payload["environment"] as? String == "device")
    #expect(payload["appBuild"] as? String == "3")
    #expect(payload["tagReadingAvailable"] as? Bool == false)
    #expect(payload["ndefReadingAvailable"] as? Bool == false)
    #expect(payload["usageDescriptionPresent"] as? Bool == true)
    #expect(payload["lastFailure"] == nil)
    for forbidden in ["uidHex", "cardNumber", "deviceName", "identifierForVendor", "serialNumber", "userInfo", "scans"] {
        #expect(payload[forbidden] == nil)
    }
}

@Test("Diagnostic serialization preserves the failure phase, code and time")
func diagnosticRoundTrip() throws {
    let failure = NFCFailureSnapshot(
        category: .unknown, stage: .connecting, occurredAt: diagnosticDate,
        domain: "NFCError", code: 999, errorDescription: String(repeating: "x", count: 2048), requestedMode: .balance
    )
    let snapshot = diagnostic(failure: failure)
    #expect(snapshot.lastFailure?.errorDescription?.count == 512)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(NFCDiagnostic.self, from: encoder.encode(snapshot))
    #expect(decoded == snapshot)
    #expect(decoded.lastFailure?.stage == .connecting)
    #expect(decoded.lastFailure?.code == 999)
    #expect(decoded.lastFailure?.occurredAt == diagnosticDate)
}
