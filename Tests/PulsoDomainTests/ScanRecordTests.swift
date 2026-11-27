import Foundation
import Testing
@testable import PulsoDomain

private func exampleRecord(family: String = "MIFARE Plus", uid: String = "04112233445566") -> ScanRecord {
    ScanRecord(
        id: UUID(uuidString: "20C09039-8C15-4771-AE25-57A26E838F12")!,
        scannedAt: Date(timeIntervalSince1970: 1_700_000_000),
        technology: "ISO 14443-A",
        family: family,
        uidHex: uid,
        historicalBytesHex: "DEADBEEF",
        applicationDataHex: "AABBCC",
        selectedAID: "D2760000850101",
        notes: ["La fecha corresponde al escaneo, no a un viaje."]
    )
}

@Test("Only active states block a second scan")
func activeStates() {
    #expect(ScanPhase.scanning.isActive)
    #expect(ScanPhase.connecting.isActive)
    for phase in [ScanPhase.idle, .completed, .cancelled, .failed("test")] {
        #expect(!phase.isActive)
    }
}

@Test("The default export omits raw UID and low-level identifying data")
func redactedDiagnostics() throws {
    let record = exampleRecord()
    let json = record.diagnosticJSON(includeIdentifier: false)
    let object = try #require(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
    #expect(object["uidHex"] == nil)
    #expect(object["historicalBytesHex"] == nil)
    #expect(object["applicationDataHex"] == nil)
    #expect(object["selectedAID"] == nil)
    #expect(object["identifierRedacted"] as? Bool == true)
    #expect(object["subeVerified"] as? Bool == false)
    #expect(!json.contains(record.uidHex))
    #expect(!json.contains("DEADBEEF"))
    #expect(object["balanceStatus"] as? String == "unavailable_without_authorized_access")
    #expect(object["lastTripStatus"] as? String == "unavailable_without_authorized_access")
}

@Test("Raw metadata only appears when explicitly requested")
func fullDiagnostics() throws {
    let record = exampleRecord()
    let object = try #require(JSONSerialization.jsonObject(with: Data(record.diagnosticJSON(includeIdentifier: true).utf8)) as? [String: Any])
    #expect(object["uidHex"] as? String == record.uidHex)
    #expect(object["historicalBytesHex"] as? String == "DEADBEEF")
    #expect(object["identifierRedacted"] as? Bool == false)
    #expect(object["subeVerified"] as? Bool == false)
}

@Test("Text sharing remains redacted and distinguishes scans from journeys")
func textSharing() {
    let record = exampleRecord()
    #expect(!record.shareSummary.contains(record.uidHex))
    #expect(record.shareSummary.contains("•••• 5566"))
    #expect(record.shareSummary.contains("SUBE: sin verificar"))
    #expect(record.shareSummary.contains("no a un viaje"))
}

@Test("A short or missing identifier is never fully revealed by the mask")
func shortUIDs() {
    for uid in ["", "04", "1234", "12 34"] {
        #expect(exampleRecord(uid: uid).maskedIdentifier == "Oculto")
    }
    #expect(exampleRecord(uid: "04 11 22 33 44 aa bb").maskedIdentifier == "•••• AABB")
}

@Test("Only the Plus family is a candidate, and a candidate is still unverified")
func familyHint() throws {
    #expect(exampleRecord().canBeSUBE)
    for family in ["MIFARE Classic", "MIFARE DESFire", "MIFARE Ultralight", "ISO 7816", "ISO 14443-A compatible"] {
        #expect(!exampleRecord(family: family).canBeSUBE)
    }
    let object = try #require(JSONSerialization.jsonObject(with: Data(exampleRecord().diagnosticJSON(includeIdentifier: true).utf8)) as? [String: Any])
    #expect(object["subeVerified"] as? Bool == false)
}

@Test("Local history can round-trip the actual metadata snapshot")
func persistenceRoundTrip() throws {
    let record = exampleRecord()
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    #expect(try decoder.decode(ScanRecord.self, from: encoder.encode(record)) == record)
}
