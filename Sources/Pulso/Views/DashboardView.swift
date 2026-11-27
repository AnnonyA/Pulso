import SwiftUI

struct DashboardView: View {
    @Environment(ReaderStore.self) private var store
    @State private var showingScanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                PhysicalCardView(record: store.latestScan)

                VStack(spacing: 12) {
                    PrimaryScanButton(
                        title: store.latestScan == nil ? "Escanear tarjeta" : "Volver a escanear",
                        isDisabled: store.phase.isActive
                    ) {
                        store.resetState()
                        showingScanner = true
                    }
                    Text("Apoyá la tarjeta en la parte superior del iPhone.")
                        .font(.caption)
                        .foregroundStyle(PulsoTheme.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                if let record = store.latestScan {
                    latestReading(record)
                }

                VStack(alignment: .leading, spacing: 17) {
                    HStack {
                        Eyebrow(text: "Datos de transporte")
                        Spacer(minLength: 4)
                        Image(systemName: "lock")
                            .foregroundStyle(PulsoTheme.secondary)
                            .accessibilityHidden(true)
                    }
                    UnavailableDataRow(title: "Saldo real", systemImage: "creditcard")
                    Divider().overlay(PulsoTheme.line)
                    UnavailableDataRow(title: "Último viaje", systemImage: "bus")
                    Text("Estos datos no se pueden leer en esta versión sin acceso a la información protegida de SUBE.")
                        .font(.footnote)
                        .foregroundStyle(PulsoTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .pulsoSurface()

                if !store.isNFCAvailable {
                    InfoNotice(
                        title: "NFC no disponible en este entorno",
                        message: "La lectura requiere un iPhone físico con la app firmada y la capacidad NFC habilitada. El simulador permite recorrer la interfaz.",
                        systemImage: "iphone.slash",
                        tint: PulsoTheme.caution
                    )
                    .pulsoSurface()
                }

                HStack(spacing: 7) {
                    Image(systemName: "lock.shield")
                    Text("Lectura local. Tu tarjeta queda intacta.")
                }
                .font(.caption)
                .foregroundStyle(PulsoTheme.secondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 18)
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 8) {
                    PulsoMark(size: 30)
                    Text("pulso")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(PulsoTheme.ink)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Pulso, lector NFC")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    HelpView()
                } label: {
                    Image(systemName: "questionmark")
                }
                .accessibilityLabel("Ayuda para leer tu tarjeta")
            }
        }
        .sheet(isPresented: $showingScanner) {
            ScanGuideView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Eyebrow(text: "Tu lector personal")
                Spacer(minLength: 6)
                StatusPill(
                    text: "iOS 26+",
                    systemImage: "iphone",
                    tint: PulsoTheme.secondary
                )
            }
            Text("Tu tarjeta,\nmás cerca.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            Text("Acercá tu SUBE y explorá lo que su chip permite leer.")
                .font(.subheadline)
                .foregroundStyle(PulsoTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func latestReading(_ record: ScanRecord) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Eyebrow(text: "Última lectura NFC")
            NavigationLink {
                ScanDetailView(record: record)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "wave.3.right")
                        .font(.title2)
                        .foregroundStyle(PulsoTheme.accent)
                        .frame(width: 48, height: 48)
                        .background(PulsoTheme.surfaceSecondary, in: RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.family)
                            .font(.headline)
                            .foregroundStyle(PulsoTheme.ink)
                        Text(record.scannedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                            .font(.caption)
                            .foregroundStyle(PulsoTheme.secondary)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(PulsoTheme.accent)
                }
                .pulsoSurface()
            }
            .buttonStyle(.plain)
            .accessibilityHint("Muestra los datos detectados. La fecha corresponde al escaneo, no a un viaje")
        }
    }
}

struct PhysicalCardView: View {
    let record: ScanRecord?
    @Environment(ReaderStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(record == nil ? "TU TARJETA FÍSICA" : "TARJETA DETECTADA")
                        .font(.caption.weight(.semibold))
                        .tracking(1.3)
                        .foregroundStyle(PulsoTheme.mint.opacity(0.9))
                    Text(record?.family ?? "Lista para acercar")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Image(systemName: "wave.3.right")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(PulsoTheme.mint)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 0 : 10)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(record == nil ? "Cerca. Simple. En tu iPhone." : "Identificador del chip")
                        .font(.caption)
                        .foregroundStyle(PulsoTheme.mint.opacity(0.8))
                    if let record {
                        Text(store.showFullIdentifier ? record.uidHex : record.maskedIdentifier)
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(.white)
                            .textSelection(.enabled)
                    } else {
                        Text("Lectura NFC")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: record == nil ? "plus" : "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PulsoTheme.mint)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .leading)
        .background {
            ZStack(alignment: .trailing) {
                LinearGradient(
                    colors: [PulsoTheme.deepGreen, Color(red: 0.08, green: 0.33, blue: 0.26)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .stroke(PulsoTheme.mint.opacity(0.1), lineWidth: 32)
                    .frame(width: 250, height: 250)
                    .offset(x: 130, y: 82)
                Circle()
                    .stroke(PulsoTheme.mint.opacity(0.06), lineWidth: 1)
                    .frame(width: 335, height: 335)
                    .offset(x: 125, y: 82)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .shadow(color: PulsoTheme.deepGreen.opacity(0.13), radius: 16, y: 9)
        .accessibilityElement(children: .combine)
    }
}

struct UnavailableDataRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer(minLength: 12)
                Text("No disponible")
                    .foregroundStyle(PulsoTheme.secondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                Text("No disponible")
                    .foregroundStyle(PulsoTheme.secondary)
            }
        }
        .font(.subheadline.weight(.medium))
        .accessibilityElement(children: .combine)
    }
}
