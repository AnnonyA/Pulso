import SwiftUI

struct SettingsView: View {
    @Environment(ReaderStore.self) private var store
    @AppStorage("pulso.appearance") private var appearance = AppAppearance.system.rawValue
    @State private var showingWelcome = false
    @State private var confirmingDelete = false
    @State private var confirmingDisableHistory = false

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                HStack(spacing: 14) {
                    PulsoMark(size: 54)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Pulso")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Lector NFC independiente para SUBE")
                            .font(.subheadline)
                            .foregroundStyle(PulsoTheme.secondary)
                    }
                }
                .padding(.vertical, 9)
                .listRowBackground(PulsoTheme.surface)
            }

            Section {
                Toggle("Guardar lecturas NFC", isOn: Binding(
                    get: { store.keepHistory },
                    set: { newValue in
                        if !newValue, !store.scans.isEmpty {
                            confirmingDisableHistory = true
                        } else {
                            store.keepHistory = newValue
                        }
                    }
                ))
                Toggle("Mostrar el UID completo", isOn: $store.showFullIdentifier)
            } header: {
                Text("Tus datos")
            } footer: {
                Text("Este historial guarda hasta 50 lecturas del chip, no viajes. Al desactivarlo se borran las guardadas. Mostrar el UID no lo incluye automáticamente en los archivos que compartís.")
            }
            .listRowBackground(PulsoTheme.surface)

            Section {
                Picker("Apariencia", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { style in
                        Text(style.title).tag(style.rawValue)
                    }
                }
                Toggle("Vibración al leer", isOn: $store.hapticsEnabled)
            } header: {
                Text("A tu manera")
            } footer: {
                Text("La interfaz respeta el tamaño del texto y la preferencia Reducir movimiento del iPhone. iOS puede emitir su propia respuesta al detectar una tarjeta.")
            }
            .listRowBackground(PulsoTheme.surface)

            Section {
                NavigationLink {
                    HelpView()
                } label: {
                    Label("Cómo leer tu tarjeta", systemImage: "questionmark.circle")
                }
                NavigationLink {
                    PrivacyView()
                } label: {
                    Label("Privacidad y datos", systemImage: "hand.raised")
                }
                Button {
                    showingWelcome = true
                } label: {
                    Label("Ver la bienvenida", systemImage: "sparkles")
                }
                LabeledContent("Versión", value: appVersion)
                LabeledContent("Sistema mínimo", value: "iOS 26.0")
            } header: {
                Text("Acerca de Pulso")
            } footer: {
                Text("Proyecto independiente. No es la aplicación oficial de SUBE ni está afiliado a Nación Servicios. La disponibilidad de lectura depende del protocolo de cada tarjeta.")
            }
            .listRowBackground(PulsoTheme.surface)

            Section {
                Button("Borrar todas las lecturas", role: .destructive) {
                    confirmingDelete = true
                }
                .disabled(store.scans.isEmpty && store.latestScan == nil && store.historyNotice == nil)
            } footer: {
                Text("Borra el historial y la última lectura de la app. No modifica la tarjeta física.")
            }
            .listRowBackground(PulsoTheme.surface)

            if let notice = store.historyNotice {
                Section {
                    Text(notice)
                        .font(.footnote)
                        .foregroundStyle(PulsoTheme.caution)
                }
                .listRowBackground(PulsoTheme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingWelcome) {
            OnboardingView { showingWelcome = false }
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("¿Borrar todas las lecturas?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Borrar lecturas", role: .destructive) { store.clearHistory() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Los registros se eliminarán de este iPhone. La tarjeta no cambia.")
        }
        .confirmationDialog("¿Desactivar y borrar el historial?", isPresented: $confirmingDisableHistory, titleVisibility: .visible) {
            Button("Desactivar y borrar", role: .destructive) { store.keepHistory = false }
            Button("Conservar historial", role: .cancel) {}
        } message: {
            Text("Se borrarán las lecturas guardadas. La lectura actual seguirá visible durante esta sesión.")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "hand.raised")
                    .font(.largeTitle)
                    .foregroundStyle(PulsoTheme.accent)
                    .accessibilityHidden(true)
                Text("Tus datos,\nen tus manos.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)

                PrivacySection(
                    title: "Qué lee Pulso",
                    message: "El tipo de tecnología, la familia de chip que informa iOS, el identificador UID y los metadatos públicos disponibles. También registra el momento en que realizaste la lectura. No obtiene tu nombre, DNI, saldo ni viajes."
                )
                PrivacySection(
                    title: "Dónde se guarda",
                    message: "Si activás el historial, se conservan hasta 50 lecturas en el almacenamiento local de la app. El historial guarda el UID para poder diagnosticar la tarjeta; ocultarlo en pantalla no lo elimina del archivo local. Podés borrar los registros desde Ajustes o Lecturas."
                )
                PrivacySection(
                    title: "Qué se comparte",
                    message: "Pulso no tiene servidor, cuentas, anuncios ni analítica. Solo se comparte información cuando vos abrís la opción Compartir y elegís un destino. El archivo de diagnóstico oculta el identificador por defecto; incluirlo es una decisión separada."
                )
                PrivacySection(
                    title: "Lo que muestra la pantalla",
                    message: "El UID del chip no es el número impreso de SUBE. La hora de lectura no es la hora de un viaje. Detectar una familia como MIFARE Plus no verifica que la tarjeta pertenezca al sistema SUBE."
                )
                PrivacySection(
                    title: "Tu tarjeta queda intacta",
                    message: "Esta versión obtiene los metadatos que expone Core NFC. No autentica sectores, no envía órdenes para modificar la tarjeta, no acredita cargas y no emula una tarjeta de transporte."
                )
            }
            .padding(24)
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
        .navigationTitle("Privacidad")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PrivacySection: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(PulsoTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .pulsoSurface()
    }
}
