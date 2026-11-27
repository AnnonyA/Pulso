import SwiftUI

/// Reports the local installation even when no reader session or card exists.
/// Sharing is always an explicit action; this view does not start NFC or a network request.
struct NFCDiagnosticsView: View {
    @Environment(ReaderStore.self) private var store

    var body: some View {
        Form {
            if let diagnostic = store.nfcDiagnostic {
                Section {
                    InfoNotice(
                        title: diagnostic.readiness.title,
                        message: diagnostic.readiness.message,
                        systemImage: "wave.3.right",
                        tint: PulsoTheme.accent
                    )
                    .padding(.vertical, 6)
                    .accessibilityIdentifier("nfc.diagnostics.status")

                    ShareLink(
                        item: diagnostic.summaryText,
                        subject: Text("Diagnóstico NFC de Pulso"),
                        message: Text("Estado NFC y último error de esta instalación.")
                    ) {
                        Label("Compartir diagnóstico", systemImage: "square.and.arrow.up")
                            .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("nfc.diagnostics.share")

                    Button {
                        store.refreshNFCDiagnostic()
                    } label: {
                        Label("Actualizar estado", systemImage: "arrow.clockwise")
                            .frame(minHeight: 44)
                    }
                    .disabled(store.phase.isActive)
                    .accessibilityIdentifier("nfc.diagnostics.refresh")
                } footer: {
                    Text("Actualizar no inicia una lectura. El informe permanece en esta sesión de la app y solo se comparte cuando lo elegís.")
                }
                .listRowBackground(PulsoTheme.surface)

                Section {
                    LabeledContent("Entorno", value: diagnostic.environment.displayName)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Entorno: \(diagnostic.environment.displayName)")
                        .accessibilityIdentifier("nfc.diagnostics.environment")
                    LabeledContent("Pulso", value: "\(diagnostic.appVersion) (\(diagnostic.appBuild))")
                    LabeledContent("Dispositivo", value: diagnostic.deviceType)
                    LabeledContent("Sistema", value: diagnostic.osVersion)
                    LabeledContent("Lectura de tarjetas", value: availability(diagnostic.tagReadingAvailable))
                    LabeledContent("Etapa", value: diagnostic.stage.displayName)
                    LabeledContent("Actualizado", value: diagnostic.capturedAt.formatted(date: .abbreviated, time: .standard))
                } header: {
                    Text("Estado observado")
                } footer: {
                    Text("La disponibilidad que informa iOS no confirma que la firma tenga permiso NFC ni que tu tarjeta sea compatible.")
                }
                .listRowBackground(PulsoTheme.surface)

                if let failure = diagnostic.lastFailure {
                    Section {
                        InfoNotice(
                            title: failure.title,
                            message: failure.message,
                            systemImage: "exclamationmark.circle",
                            tint: PulsoTheme.caution
                        )
                        .padding(.vertical, 6)
                        LabeledContent("Ocurrió", value: failure.occurredAt.formatted(date: .abbreviated, time: .standard))
                    } header: {
                        Text("Último error")
                    } footer: {
                        Text("Se conserva al actualizar el estado para poder diagnosticar el intento anterior.")
                    }
                    .listRowBackground(PulsoTheme.surface)
                }

                Section {
                    DisclosureGroup("Información técnica") {
                        LabeledContent("Lectura NDEF", value: availability(diagnostic.ndefReadingAvailable))
                        LabeledContent("Descripción de uso NFC", value: diagnostic.usageDescriptionPresent ? "Presente" : "Falta")
                        Text(diagnostic.summaryText)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("nfc.diagnostics.report")
                        ShareLink(item: diagnostic.exportJSON, subject: Text("Diagnóstico NFC — JSON")) {
                            Label("Compartir JSON técnico", systemImage: "curlybraces")
                                .frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("nfc.diagnostics.shareJSON")
                    }
                } footer: {
                    Text("NDEF es un dato auxiliar: no reemplaza el lector de la tarjeta. Este informe no agrega los registros ni los identificadores de tarjetas guardadas.")
                }
                .listRowBackground(PulsoTheme.surface)

                Section("Si falla en tu iPhone") {
                    Text("Volvé a intentar con Pulso abierto y el iPhone desbloqueado. Si iOS informa que la radio NFC está deshabilitada, revisá si el modo avión está activo.")
                    Text("Si instalaste un IPA, confirmá que la firma final y el perfil permitan NFC TAG. La app no puede conceder ese permiso ni comprobarlo de forma concluyente a partir de la disponibilidad.")
                    Text("Si el problema continúa, compartí este diagnóstico junto con el nombre del método que usaste para firmar e instalar la app.")
                }
                .font(.subheadline)
                .listRowBackground(PulsoTheme.surface)
            } else {
                Section {
                    ProgressView("Consultando el estado NFC…")
                }
                .listRowBackground(PulsoTheme.surface)
            }
        }
        .foregroundStyle(PulsoTheme.ink)
        .tint(PulsoTheme.accent)
        .scrollContentBackground(.hidden)
        .background(PulsoTheme.background)
        .navigationTitle("Diagnóstico NFC")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if store.nfcDiagnostic == nil {
                store.refreshNFCDiagnostic()
            }
        }
    }

    private func availability(_ value: Bool) -> String {
        value ? "Disponible" : "No disponible"
    }
}
