import SwiftUI

struct ScanGuideView: View {
    @Environment(ReaderStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.phase == .completed, let record = store.latestScan {
                    ScanDetailView(record: record, onScanAgain: store.resetState)
                } else {
                    guide
                        .navigationTitle("Leer tarjeta")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(store.phase.isActive ? "Cancelar" : "Listo") {
                        if store.phase.isActive { store.cancelScan() }
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(store.phase.isActive)
        .onDisappear {
            if store.phase.isActive { store.cancelScan() }
        }
    }

    private var guide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "Un toque, una lectura")
                    Text("La señal está\nen la parte de arriba.")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Acercá la SUBE al borde superior trasero del iPhone y mantenela quieta.")
                        .font(.body)
                        .foregroundStyle(PulsoTheme.secondary)
                }

                NFCPlacementIllustration()
                    .frame(height: 230)

                VStack(spacing: 21) {
                    ScanInstruction(number: "1", text: "Retirá otras tarjetas y accesorios metálicos.")
                    ScanInstruction(number: "2", text: "Tocá Iniciar lectura y acercá una sola tarjeta.")
                    ScanInstruction(number: "3", text: "Esperá la respuesta sin mover el iPhone.")
                }
                .pulsoSurface()

                status

                if store.phase.isActive {
                    Button("Cancelar lectura", role: .cancel) {
                        store.cancelScan()
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                } else {
                    PrimaryScanButton(title: retryTitle, isDisabled: !store.isNFCAvailable) {
                        store.startScan()
                    }
                }

                Text("Si iOS no admite el protocolo de tu tarjeta, puede no detectarla. Ninguna lectura cambia su saldo.")
                    .font(.footnote)
                    .foregroundStyle(PulsoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .padding(.bottom, 16)
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
    }

    @ViewBuilder
    private var status: some View {
        switch store.phase {
        case .scanning, .connecting:
            HStack(spacing: 12) {
                ProgressView()
                    .tint(PulsoTheme.accent)
                Text(store.phase == .connecting ? "Conectando con la tarjeta…" : "Buscando una tarjeta…")
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .accessibilityElement(children: .combine)
        case .failed(let message):
            InfoNotice(
                title: "No pudimos completar la lectura",
                message: message,
                systemImage: "exclamationmark.circle",
                tint: PulsoTheme.caution
            )
            .pulsoSurface()
        case .cancelled:
            InfoNotice(
                title: "Lectura cancelada",
                message: "Podés volver a intentarlo cuando quieras.",
                systemImage: "arrow.counterclockwise"
            )
        case .idle, .completed:
            if !store.isNFCAvailable {
                InfoNotice(
                    title: "Hace falta un iPhone con NFC habilitado",
                    message: "La lectura real requiere un dispositivo compatible y una firma que habilite NFC. No está disponible en el simulador.",
                    systemImage: "iphone.slash",
                    tint: PulsoTheme.caution
                )
            }
        }
    }

    private var retryTitle: String {
        switch store.phase {
        case .failed, .cancelled: "Volver a intentar"
        default: "Iniciar lectura"
        }
    }
}

private struct ScanInstruction: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(PulsoTheme.accent)
                .frame(width: 29, height: 29)
                .background(PulsoTheme.surfaceSecondary, in: Circle())
            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
