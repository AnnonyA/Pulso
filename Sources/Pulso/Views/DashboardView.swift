import SwiftUI

struct DashboardView: View {
    @Environment(ReaderStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var utilityRoute: UtilityRoute?
    @State private var technicalRecord: ScanRecord?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                modePicker
                    .padding(.top, 20)
                    .padding(.bottom, 14)

                Divider()
                    .overlay(PulsoTheme.line)

                Text(store.selectedMode.title)
                    .font(.headline)
                    .foregroundStyle(PulsoTheme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 17)
                    .accessibilityIdentifier("reader.mode.title")
                    .accessibilityAddTraits(.isHeader)

                if let result = store.currentResult {
                    OperationResultView(result: result) {
                        technicalRecord = result.record
                    }
                    .padding(.top, 25)
                    .padding(.bottom, 26)
                } else {
                    NFCPlacementIllustration(compact: true)
                        .padding(.top, 12)
                        .padding(.bottom, 7)

                    VStack(spacing: 7) {
                        Text("Apoyá la SUBE")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(PulsoTheme.accent)
                            .accessibilityAddTraits(.isHeader)
                        Text(store.selectedMode.instruction)
                            .font(.subheadline)
                            .foregroundStyle(PulsoTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)
                }

                sessionStatus

                PrimaryScanButton(
                    title: store.currentResult == nil ? "Iniciar lectura" : "Volver a leer",
                    isDisabled: store.phase.isActive
                ) {
                    // Exactly one explicit gesture starts Apple's real reader.
                    // No guide sheet, automatic scanning, or generated records.
                    store.startScan()
                }
                .accessibilityIdentifier("reader.scan")

                unavailableNote
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                Text("Pulso · app independiente para SUBE")
                    .font(.caption2)
                    .foregroundStyle(PulsoTheme.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 15)
            }
            .padding(.horizontal, 24)
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
        .navigationTitle("Pulso")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PulsoTheme.headerBlue, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                utilityMenu
            }
            ToolbarItem(placement: .principal) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text("Pulso")
                        .font(.title3.weight(.semibold))
                    Text("para SUBE")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .foregroundStyle(.white)
                .accessibilityElement(children: .combine)
            }
        }
        .sheet(item: $utilityRoute) { route in
            UtilitySheet(route: route)
        }
        .sheet(item: $technicalRecord) { record in
            NavigationStack {
                ScanDetailView(record: record)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Listo") { technicalRecord = nil }
                        }
                    }
            }
        }
    }

    private var modePicker: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(ReaderMode.allCases) { mode in
                        modeButton(mode, horizontal: true)
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 9) {
                    ForEach(ReaderMode.allCases) { mode in
                        modeButton(mode, horizontal: false)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Operación con tu tarjeta")
    }

    private func modeButton(_ mode: ReaderMode, horizontal: Bool) -> some View {
        ReaderModeButton(
            mode: mode,
            isSelected: store.selectedMode == mode,
            isDisabled: store.phase.isActive,
            horizontal: horizontal
        ) {
            store.selectMode(mode)
        }
    }

    private var utilityMenu: some View {
        Menu {
            Button {
                utilityRoute = .readings
            } label: {
                Label("Historial de lecturas NFC", systemImage: "wave.3.right")
            }
            .accessibilityIdentifier("menu.readings")

            Button {
                utilityRoute = .settings
            } label: {
                Label("Ajustes y privacidad", systemImage: "slider.horizontal.3")
            }
            .accessibilityIdentifier("menu.settings")

            Button {
                utilityRoute = .help
            } label: {
                Label("Ayuda", systemImage: "questionmark.circle")
            }
            .accessibilityIdentifier("menu.help")
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .tint(.white)
        .disabled(store.phase.isActive)
        .accessibilityLabel("Abrir menú")
        .accessibilityIdentifier("menu.open")
    }

    private var unavailableNote: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: "lock")
                .font(.caption)
                .padding(.top, 2)
                .accessibilityHidden(true)
            Text(modeAvailabilityNote)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(PulsoTheme.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("reader.unavailable.note")
    }

    private var modeAvailabilityNote: String {
        switch store.selectedMode {
        case .balance:
            "Podés intentar leer un chip compatible. El saldo real aún no está disponible."
        case .trips:
            "Podés intentar leer un chip compatible. El historial de viajes aún no está disponible."
        case .topUp:
            "Podés intentar leer un chip compatible. Todavía no acredita cargas ni modifica el saldo."
        }
    }

    @ViewBuilder
    private var sessionStatus: some View {
        switch store.phase {
        case .scanning, .connecting:
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(PulsoTheme.accent)
                    Text(store.phase == .connecting ? "Conectando con la tarjeta…" : "Acercá una sola tarjeta…")
                        .font(.subheadline)
                }
                Button("Cancelar lectura", role: .cancel) {
                    store.cancelScan()
                }
                .frame(minHeight: 44)
            }
            .padding(.bottom, 16)
        case .failed(let message):
            InfoNotice(
                title: "No se pudo completar la lectura",
                message: message,
                systemImage: "exclamationmark.circle",
                tint: PulsoTheme.caution
            )
            .pulsoSurface(padding: 16)
            .padding(.bottom, 16)
        case .cancelled:
            Text("Lectura cancelada. Podés volver a intentarlo.")
                .font(.footnote)
                .foregroundStyle(PulsoTheme.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
        case .idle, .completed:
            EmptyView()
        }
    }
}

private struct ReaderModeButton: View {
    let mode: ReaderMode
    let isSelected: Bool
    let isDisabled: Bool
    let horizontal: Bool
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if horizontal {
                    HStack(spacing: 15) {
                        modeIcon
                        Text(mode.title)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(spacing: 10) {
                        modeIcon
                        Text(displayTitle)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: 42, alignment: .top)
                    }
                }
            }
            .foregroundStyle(isSelected ? PulsoTheme.selectedText : PulsoTheme.secondary)
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mode.title)
        .accessibilityValue(isSelected ? "Seleccionado" : "No seleccionado")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("mode.\(mode.rawValue)")
    }

    private var modeIcon: some View {
        Image(systemName: mode.systemImage)
            .font(.system(size: horizontal ? 23 : 28, weight: .regular))
            .foregroundStyle(isSelected ? PulsoTheme.orange : PulsoTheme.idleRing)
            .frame(width: horizontal ? 56 : 68, height: horizontal ? 56 : 68)
            .background(isSelected ? PulsoTheme.selectionFill : PulsoTheme.surface, in: Circle())
            .overlay {
                Circle()
                    .stroke(isSelected ? PulsoTheme.orange : PulsoTheme.idleRing, lineWidth: 3)
            }
            .accessibilityHidden(true)
    }

    private var displayTitle: String {
        switch mode {
        case .balance: "Consultar\nsaldo"
        case .trips: "Historial"
        case .topUp: "Acreditar\ncarga"
        }
    }
}

private struct OperationResultView: View {
    let result: ModeScanResult
    let showTechnicalDetails: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle")
                .font(.system(size: 68, weight: .ultraLight))
                .foregroundStyle(PulsoTheme.accent)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(result.mode.unavailableTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(PulsoTheme.ink)
                Text(result.mode.unavailableMessage)
                    .font(.subheadline)
                    .foregroundStyle(PulsoTheme.secondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Label("El chip sí fue detectado", systemImage: "wave.3.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PulsoTheme.accent)
                Text(result.record.family)
                    .font(.body.weight(.medium))
                Text("Esto no verifica que la tarjeta sea SUBE ni habilita sus funciones protegidas.")
                    .font(.footnote)
                    .foregroundStyle(PulsoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: showTechnicalDetails) {
                    HStack {
                        Text("Ver datos del chip")
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(PulsoTheme.accent)
            }
            .pulsoSurface()
        }
    }
}

private enum UtilityRoute: String, Identifiable {
    case readings, settings, help
    var id: String { rawValue }
}

private struct UtilitySheet: View {
    let route: UtilityRoute
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch route {
                case .readings: HistoryView()
                case .settings: SettingsView()
                case .help: HelpView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Listo") { dismiss() }
                }
            }
        }
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
