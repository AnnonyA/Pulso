import Foundation
import Testing
@testable import PulsoDomain

private func modeRecord() -> ScanRecord {
    ScanRecord(
        id: UUID(uuidString: "106AAFD5-763B-4C71-B71C-2561D95F29CD")!,
        scannedAt: Date(timeIntervalSince1970: 1_700_000_000),
        technology: "ISO 14443-A",
        family: "MIFARE Plus",
        uidHex: "04123456789ABC"
    )
}

@Test("The three modes preserve the requested order and default")
func modeOrderAndDefault() {
    #expect(ReaderMode.allCases == [.balance, .trips, .topUp])
    #expect(ReaderMode.defaultMode == .balance)
    #expect(ReaderMode.allCases.map(\.title) == ["Consultar saldo", "Historial", "Acreditar carga"])
    #expect(Set(ReaderMode.allCases.map(\.id)).count == 3)
}

@Test("A result retains the operation selected when the request started")
func requestFreezesOperation() {
    var selectedMode = ReaderMode.trips
    let request = ScanRequest(mode: selectedMode)
    selectedMode = .topUp
    let result = request.result(from: modeRecord())
    #expect(selectedMode == .topUp)
    #expect(result.mode == .trips)
    #expect(result.record.requestedMode == .trips)
    #expect(result.id == result.record.id)
    #expect(result.record.id == modeRecord().id)
}

@Test("A new request replaces any stale mode attached to a source record")
func resultModeIsConsistent() {
    var record = modeRecord()
    record.requestedMode = .balance
    let result = ScanRequest(mode: .topUp).result(from: record)
    #expect(result.mode == .topUp)
    #expect(result.record.requestedMode == .topUp)
    #expect(record.requestedMode == .balance)
}

@Test("Version 0.1 history decodes without inventing a previous operation")
func legacyRecordWithoutMode() throws {
    let json = """
    {"id":"106AAFD5-763B-4C71-B71C-2561D95F29CD","scannedAt":"2023-11-14T22:13:20Z","technology":"ISO 14443-A","family":"MIFARE Plus","uidHex":"04123456789ABC","notes":[]}
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let record = try decoder.decode(ScanRecord.self, from: Data(json.utf8))
    #expect(record.requestedMode == nil)
    #expect(record.id == modeRecord().id)
    #expect(record.shareSummary.contains("Operación solicitada: Diagnóstico NFC"))
    let export = try #require(JSONSerialization.jsonObject(with: Data(record.diagnosticJSON(includeIdentifier: false).utf8)) as? [String: Any])
    #expect(export["requestedMode"] == nil)
    #expect(export["requestedOperationStatus"] as? String == "not_requested")
}

@Test("Every operation remains unavailable after metadata detection")
func exportsNeverClaimTransportSuccess() throws {
    for mode in ReaderMode.allCases {
        let result = ScanRequest(mode: mode).result(from: modeRecord())
        let json = result.record.diagnosticJSON(includeIdentifier: false)
        let object = try #require(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        #expect(object["schemaVersion"] as? Int == 2)
        #expect(object["requestedMode"] as? String == mode.rawValue)
        #expect(object["requestedOperationStatus"] as? String == "unavailable_without_authorized_access")
        #expect(object["balanceStatus"] as? String == "unavailable_without_authorized_access")
        #expect(object["lastTripStatus"] as? String == "unavailable_without_authorized_access")
        #expect(object["topUpStatus"] as? String == "not_performed")
        #expect(object["subeVerified"] as? Bool == false)
        #expect(object["uidHex"] == nil)
        #expect(object["balance"] == nil)
        #expect(object["trips"] == nil)
        #expect(object["creditedAmount"] == nil)
        #expect(!mode.unavailableTitle.isEmpty)
        #expect(!mode.unavailableMessage.isEmpty)
        #expect(result.record.shareSummary.contains("Acreditación de carga: no realizada"))
    }
}

@Test("New history preserves each requested mode through serialization")
func modeHistoryRoundTrip() throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    for mode in ReaderMode.allCases {
        let record = ScanRequest(mode: mode).result(from: modeRecord()).record
        let restored = try decoder.decode(ScanRecord.self, from: encoder.encode(record))
        #expect(restored == record)
        #expect(restored.requestedMode == mode)
    }
}
