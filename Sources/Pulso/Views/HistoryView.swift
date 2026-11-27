import SwiftUI

struct HistoryView: View {
    @Environment(ReaderStore.self) private var store
    @State private var confirmingDelete = false

    var body: some View {
        Group {
            if store.scans.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        VStack(alignment: .leading, spacing: 12) {
                            Eyebrow(text: "Un registro para vos")
                            Text("Cada señal\ntiene su momento.")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Acá vas a encontrar las lecturas que decidas guardar.")
                                .foregroundStyle(PulsoTheme.secondary)
                        }
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 68, weight: .ultraLight))
                            .foregroundStyle(PulsoTheme.accent)
                            .frame(maxWidth: .infinity, minHeight: 170)
                            .accessibilityHidden(true)
                        InfoNotice(
                            title: store.keepHistory ? "Todavía no hay lecturas" : "El historial está desactivado",
                            message: store.keepHistory
                                ? "Iniciá una lectura desde la pantalla principal. Se guardarán hasta 50 lecturas del chip en este iPhone. Este registro no contiene viajes."
                                : "Podés activarlo en Ajustes cuando quieras. La lectura actual sigue disponible durante esta sesión.",
                            systemImage: store.keepHistory ? "wave.3.right" : "lock"
                        )
                        .pulsoSurface()
                        if let notice = store.historyNotice {
                            InfoNotice(
                                title: "Revisá el historial local",
                                message: notice,
                                systemImage: "exclamationmark.circle",
                                tint: PulsoTheme.caution
                            )
                            .pulsoSurface()
                        }
                        privacyNote
                    }
                    .padding(24)
                }
            } else {
                List {
                    Section {
                        Text("Este registro contiene lecturas del chip, no viajes. La fecha indica cuándo acercaste la tarjeta al iPhone.")
                            .font(.footnote)
                            .foregroundStyle(PulsoTheme.secondary)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 14, trailing: 0))
                    }
                    Section {
                        ForEach(store.scans) { record in
                            NavigationLink {
                                ScanDetailView(record: record)
                            } label: {
                                HistoryRow(record: record)
                            }
                            .listRowBackground(PulsoTheme.surface)
                            .listRowSeparatorTint(PulsoTheme.line)
                        }
                        .onDelete { offsets in
                            let identifiers = offsets.map { store.scans[$0].id }
                            for id in identifiers { store.deleteScan(id: id) }
                        }
                    } header: {
                        Text("\(store.scans.count) lecturas guardadas")
                    } footer: {
                        Text("Se conservan las 50 más recientes. Deslizá una lectura hacia la izquierda para borrarla.")
                    }
                    if let notice = store.historyNotice {
                        Section {
                            Text(notice)
                                .font(.footnote)
                                .foregroundStyle(PulsoTheme.caution)
                        }
                    }
                    Section {
                        privacyNote
                            .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
        .navigationTitle("Lecturas NFC")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Borrar historial", systemImage: "trash", role: .destructive) {
                    confirmingDelete = true
                }
                .disabled(store.scans.isEmpty && store.historyNotice == nil)
                .labelStyle(.iconOnly)
            }
        }
        .confirmationDialog("¿Borrar el historial de lecturas?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Borrar todas las lecturas", role: .destructive) {
                store.clearHistory()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrarán los registros guardados en este iPhone. Tu tarjeta física no cambia.")
        }
    }

    private var privacyNote: some View {
        Label("Tus lecturas se guardan únicamente en este iPhone.", systemImage: "lock.shield")
            .font(.caption)
            .foregroundStyle(PulsoTheme.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HistoryRow: View {
    let record: ScanRecord
    @Environment(ReaderStore.self) private var store

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "wave.3.right")
                .font(.title3)
                .foregroundStyle(PulsoTheme.accent)
                .frame(width: 42, height: 42)
                .background(PulsoTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(record.family)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PulsoTheme.ink)
                Text(store.showFullIdentifier ? record.uidHex : record.maskedIdentifier)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(PulsoTheme.secondary)
                Text(record.scannedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                    .font(.caption)
                    .foregroundStyle(PulsoTheme.secondary)
            }
            .padding(.vertical, 7)
        }
        .accessibilityElement(children: .combine)
    }
}
