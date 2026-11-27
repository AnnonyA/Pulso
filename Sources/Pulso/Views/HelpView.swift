import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Eyebrow(text: "Una buena primera lectura")
                Text("Cómo acercar\ntu SUBE")
                    .font(.largeTitle.weight(.bold))
                Text("El lector está en la parte superior del iPhone. Probá con una sola tarjeta y mantenela cerca hasta que termine la sesión.")
                    .font(.body)
                    .foregroundStyle(PulsoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                NFCPlacementIllustration(compact: true)

                VStack(alignment: .leading, spacing: 21) {
                    HelpItem(
                        title: "Tres opciones, una tarjeta",
                        text: "La pantalla empieza en Consultar saldo. También podés elegir Historial para los viajes o Acreditar carga. Tocá Iniciar lectura una sola vez para abrir el lector NFC de iOS. En esta versión las tres opciones intentan detectar un chip compatible; las funciones protegidas todavía no están disponibles."
                    )
                    Divider()
                    HelpItem(
                        title: "Historial de viajes y lecturas NFC",
                        text: "La opción Historial de la pantalla principal se refiere a viajes, que todavía no se pueden leer. En el menú, Historial de lecturas NFC guarda únicamente cuándo escaneaste una tarjeta y qué metadatos expuso su chip."
                    )
                    Divider()
                    HelpItem(
                        title: "No encuentra mi tarjeta",
                        text: "Retirá la funda si tiene metal o imanes, separá otras tarjetas y apoyá la SUBE cerca del borde superior trasero. Algunos protocolos, como MIFARE Classic, no son compatibles con Core NFC. Que la sesión termine sin detectar una tarjeta no significa que esté dañada."
                    )
                    Divider()
                    HelpItem(
                        title: "La app abre, pero NFC da error",
                        text: "Abrí Diagnóstico NFC desde el menú o desde el mensaje de error. Funciona aunque no hayas detectado una tarjeta. La disponibilidad que informa iOS no identifica un simulador ni revela por sí sola la causa del fallo. Si instalaste un IPA, comprobá también que su firma y perfil permitan NFC TAG."
                    )
                    Divider()
                    HelpItem(
                        title: "¿Cómo sé qué está fallando?",
                        text: "El diagnóstico distingue la compilación de dispositivo de la de simulador, muestra la versión de Pulso y conserva el último error de iOS. Actualizar estado no inicia una lectura ni borra ese último error. Si iOS informa radio NFC deshabilitada, revisá si el modo avión está activo; si informa sistema ocupado, esperá y volvé a intentar."
                    )
                    Divider()
                    HelpItem(
                        title: "¿Por qué no aparece el saldo?",
                        text: "El saldo real y los registros de viaje requieren acceso a datos protegidos de SUBE. Esta versión no autentica la tarjeta: detecta el chip y muestra los metadatos públicos que iOS entrega."
                    )
                    Divider()
                    HelpItem(
                        title: "¿MIFARE Plus significa que es SUBE?",
                        text: "No. Esa familia de chip se usa en varios sistemas. Pulso puede mostrar que la familia es compatible con algunas SUBE, pero no identifica al emisor ni verifica que la tarjeta sea auténtica."
                    )
                    Divider()
                    HelpItem(
                        title: "¿Qué es el UID?",
                        text: "Es el identificador que el chip expone durante la lectura. No es el número impreso en tu SUBE y no sirve, por sí solo, para consultar el saldo o asociar la tarjeta a tu cuenta."
                    )
                    Divider()
                    HelpItem(
                        title: "¿Hace falta internet?",
                        text: "No para detectar el chip ni guardar lecturas locales. Si decidís compartir un diagnóstico, la aplicación que elijas como destino puede usar internet."
                    )
                    Divider()
                    HelpItem(
                        title: "¿Puedo pagar o acreditar una carga?",
                        text: "Esta versión es un lector de diagnóstico. No acredita cargas, no modifica el saldo y no convierte el iPhone en una SUBE Digital."
                    )
                }
                .pulsoSurface()

                InfoNotice(
                    title: "El diagnóstico ayuda a avanzar",
                    message: "Si el lector no llega a abrirse, usá Menú → Diagnóstico NFC → Compartir diagnóstico. Después de detectar una tarjeta, Ver datos del chip ofrece por separado los metadatos de esa lectura.",
                    systemImage: "doc.text"
                )
            }
            .padding(24)
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
        .navigationTitle("Ayuda")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HelpItem: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(PulsoTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
