import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

struct ScanDetailView: View {
    let record: ScanRecord

    @Environment(ReaderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingExport = false

    /// A navigation stack can survive while another route removes its data.
    /// An unpersisted current scan is still available when history is disabled.
    private var recordIsAvailable: Bool {
        store.latestScan?.id == record.id || store.scans.contains { $0.id == record.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 13) {
                    StatusPill(text: "Datos públicos del chip", systemImage: "wave.3.right")
                    Text("Lectura NFC")
                        .font(.largeTitle.weight(.bold))
                    Text("El iPhone obtuvo los datos públicos que expone esta tarjeta.")
                        .font(.subheadline)
                        .foregroundStyle(PulsoTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 14) {
                        PulsoMark(size: 52)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(record.family)
                                .font(.system(.title2, design: .rounded, weight: .semibold))
                            Text(record.technology)
                                .font(.subheadline)
                                .foregroundStyle(PulsoTheme.secondary)
                        }
                    }
                    Divider().overlay(PulsoTheme.line)
                    MetadataRow(
                        title: "Identificador del chip (UID)",
                        value: store.showFullIdentifier ? record.uidHex : record.maskedIdentifier,
                        monospaced: true
                    )
                    MetadataRow(
                        title: "Momento de esta lectura",
                        value: record.scannedAt.formatted(date: .abbreviated, time: .standard)
                    )
                    Text("El UID no es el número impreso de SUBE. La fecha es la del escaneo, no la de un viaje.")
                        .font(.caption)
                        .foregroundStyle(PulsoTheme.secondary)
                }
                .pulsoSurface()

                InfoNotice(
                    title: record.canBeSUBE ? "Familia compatible con algunas SUBE" : "Tipo de tarjeta sin verificar",
                    message: record.canBeSUBE
                        ? "MIFARE Plus también se usa en otras tarjetas. Detectar esta familia no confirma que sea SUBE."
                        : "La lectura del chip no identifica por sí sola al emisor de la tarjeta ni confirma que sea SUBE.",
                    systemImage: "info.circle"
                )
                .pulsoSurface()

                if let requestedMode = record.requestedMode {
                    InfoNotice(
                        title: requestedMode.unavailableTitle,
                        message: requestedMode.unavailableMessage,
                        systemImage: "lock",
                        tint: PulsoTheme.accent
                    )
                    .pulsoSurface()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Eyebrow(text: "Funciones de transporte")
                        UnavailableDataRow(title: "Saldo real", systemImage: "creditcard")
                        Divider()
                        UnavailableDataRow(title: "Historial de viajes", systemImage: "bus")
                        Divider()
                        UnavailableDataRow(title: "Acreditación de cargas", systemImage: "arrow.down.to.line")
                        Text("Esta versión no accede a los sectores protegidos de la tarjeta. Detectar el chip no habilita estas funciones.")
                            .font(.footnote)
                            .foregroundStyle(PulsoTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .pulsoSurface()
                }

                technicalInformation

                if let notice = store.historyNotice {
                    InfoNotice(
                        title: "Sobre el historial local",
                        message: notice,
                        systemImage: "exclamationmark.circle",
                        tint: PulsoTheme.caution
                    )
                    .pulsoSurface()
                }

                Button {
                    showingExport = true
                } label: {
                    Label("Compartir diagnóstico", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 16))
            }
            .padding(24)
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
        .navigationTitle("Detalle de lectura")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExport) {
            DiagnosticExportView(record: record)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            dismissIfRecordWasRemoved()
        }
        .onChange(of: recordIsAvailable) { _, available in
            if !available { dismissIfRecordWasRemoved() }
        }
    }

    private func dismissIfRecordWasRemoved() {
        // ReaderStore loads its history synchronously before this view exists;
        // there is no transient loading state to mistake for deleted data.
        guard !recordIsAvailable else { return }
        showingExport = false
        dismiss()
    }

    private var technicalInformation: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 18) {
                if let mode = record.requestedMode {
                    MetadataRow(title: "Operación elegida al escanear", value: mode.title)
                }
                MetadataRow(title: "Tecnología", value: record.technology)
                MetadataRow(title: "Familia informada por iOS", value: record.family)
                MetadataRow(title: "Bytes históricos", value: record.historicalBytesHex ?? "No informados", monospaced: true)
                if let applicationData = record.applicationDataHex {
                    MetadataRow(title: "Datos de aplicación", value: applicationData, monospaced: true)
                }
                if let aid = record.selectedAID {
                    MetadataRow(title: "AID informado por iOS", value: aid, monospaced: true)
                }
                ForEach(Array(record.notes.enumerated()), id: \.offset) { _, note in
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(PulsoTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 18)
        } label: {
            Label("Información técnica", systemImage: "slider.horizontal.3")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PulsoTheme.ink)
                .padding(.vertical, 6)
        }
        .pulsoSurface()
    }
}

private struct MetadataRow: View {
    let title: String
    let value: String
    var monospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(PulsoTheme.secondary)
            Text(value.isEmpty ? "No informado" : value)
                .font(.system(.subheadline, design: monospaced ? .monospaced : .default, weight: .medium))
                .foregroundStyle(PulsoTheme.ink)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DiagnosticExport: Transferable, Sendable {
    let json: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation<DiagnosticExport>(exportedContentType: .json) { export in
            Data(export.json.utf8)
        }
        .suggestedFileName("Pulso-diagnostico.json")
    }
}

struct DiagnosticExportView: View {
    let record: ScanRecord
    @State private var includeIdentifier = false
    @Environment(ReaderStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var recordIsAvailable: Bool {
        store.latestScan?.id == record.id || store.scans.contains { $0.id == record.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundStyle(PulsoTheme.accent)
                        .accessibilityHidden(true)
                    Text("Compartí solo\nlo que elijas.")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("El archivo JSON incluye el tipo de chip, la fecha de lectura y el diagnóstico. El identificador queda oculto por defecto.")
                        .font(.subheadline)
                        .foregroundStyle(PulsoTheme.secondary)

                    Toggle("Incluir UID y metadatos completos", isOn: $includeIdentifier)
                        .tint(PulsoTheme.accent)
                        .pulsoSurface()

                    if includeIdentifier {
                        InfoNotice(
                            title: "Vas a compartir el identificador del chip",
                            message: "Puede servir para reconocer esta tarjeta en distintas lecturas. Compartilo únicamente con quien elijas.",
                            systemImage: "eye",
                            tint: PulsoTheme.caution
                        )
                    }

                    ShareLink(
                        item: DiagnosticExport(json: record.diagnosticJSON(includeIdentifier: includeIdentifier)),
                        preview: SharePreview("Diagnóstico NFC de Pulso", image: Image(systemName: "wave.3.right"))
                    ) {
                        Label("Compartir archivo JSON", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .tint(PulsoTheme.accent)

                    ShareLink(item: record.shareSummary) {
                        Label("Compartir resumen con UID oculto", systemImage: "text.alignleft")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
                .padding(24)
            }
            .foregroundStyle(PulsoTheme.ink)
            .background(PulsoTheme.background)
            .navigationTitle("Exportar diagnóstico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                }
            }
        }
        .onAppear {
            if !recordIsAvailable { dismiss() }
        }
        .onChange(of: recordIsAvailable) { _, available in
            if !available { dismiss() }
        }
    }
}
