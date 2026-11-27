# Estado de la entrega

Fecha: 27 de noviembre de 2026. Versión de la app: 0.1.0, build 1.

## Completado en esta entrega

- Código nativo SwiftUI, modelo y lector Core NFC integrado.
- Despliegue mínimo fijado en iOS 26.0 para iPhone. La app no habilita versiones anteriores.
- Proyecto real de Xcode, esquema compartido, íconos de claro/oscuro/tintado, privacidad y entitlement TAG.
- Flujo de GitHub Actions para producir una aplicación arm64 y empaquetarla como IPA sin firmar.
- Ayudante de PowerShell orientado a Windows 10 y guía de publicación manual.
- Revisión independiente del aislamiento del lector NFC y la integración con la interfaz.
- Corrección de la disponibilidad de APIs en las pruebas SwiftPM para macOS.
- Corrección del detalle de una lectura borrada que podía permanecer en la navegación de otra pestaña.
- Comprobaciones locales de configuración, recursos, formatos, sintaxis Bash/Python, estructura YAML y referencias del proyecto.

## Aún no ejecutado

- Compilación del código Swift para iPhone con el SDK de Apple.
- Las siete pruebas Swift Testing del modelo.
- Ejecución del ayudante en PowerShell.
- Renderizado nativo en simulador, pruebas de VoiceOver o de tamaños de texto en un iPhone.
- Prueba física de NFC, confirmación de compatibilidad con una SUBE concreta o instalación del IPA.

El entorno utilizado es Linux sin Swift ni Xcode. No se produjo un binario IPA en él. La imagen de diseño adjunta está rotulada como maqueta y no acredita una ejecución de la app.

## Primera verificación nativa

Al publicar este proyecto en un repositorio, `Compilar IPA - iOS 26` ejecuta las pruebas de modelos y compila la app con Xcode en macOS. Si cualquier etapa falla, Actions conserva el error y no publica un IPA de éxito. El verificador del paquete revisa el formato Mach-O, arm64, plataforma iOS y mínimo 26.0; rechaza archivos fuente o binarios de simulador presentados como una app.

Después de instalarla con una firma y un perfil NFC válidos, la prueba decisiva es escanear la tarjeta física del usuario. Esta versión obtiene solamente los metadatos públicos que iOS exponga, nunca saldo ni último viaje por autenticación. Una tarjeta no detectada puede usar un protocolo o modo que Core NFC no permita.
