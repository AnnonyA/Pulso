# Estado de la entrega

Actualizado el 27 de noviembre de 2026. App 0.1.0, build 1.

## Compilación nativa confirmada

La [ejecución #1 de GitHub Actions](https://github.com/AnnonyA/Pulso/actions/runs/45969338666) terminó con estado **success** sobre el commit `46928c7e17f14be549e2f5b118fb59ffbb378600`.

| Comprobación | Resultado observado |
| --- | --- |
| Entorno | Runner `macos-26-arm64`, macOS 26.7.2. |
| Compilador | Xcode 26.6, Apple Swift 6.3.3; lenguaje Swift 6. |
| SDK | iPhoneOS 26.5. |
| Pruebas del modelo | 7 de 7 aprobadas. |
| Compilación nativa | `BUILD SUCCEEDED`, Release para iPhone. |
| Arquitectura | Ejecutable Mach-O arm64. |
| Versión mínima | iOS 26.0 en Info.plist y en el ejecutable. |
| Recursos | Catálogo de assets compilado y manifiesto de privacidad presentes. |
| Firma | Sin firma ni provisioning profile; requiere firma posterior con NFC TAG. |
| Archivo IPA | `Pulso-unsigned.ipa`, 479.866 bytes. |
| Ejecutable dentro de la app | 1.609.816 bytes. |

Artifact: [Pulso-iOS26-unsigned-1](https://github.com/AnnonyA/Pulso/actions/runs/45969338666/artifacts/15184396513). La retención de esta compilación en GitHub vence el 11 de diciembre de 2026; el workflow permite generar una nueva.

SHA-256 del IPA sin firmar:

```text
491ccd578cbf233b501ea3a43bf1f2b84c7e0ea5ad5022fa46a8f51da373b91a
```

Después de descargar el artifact se comprobó su hash contra el digest informado por GitHub, el hash del IPA contra `SHA256SUMS.txt` y su estructura binaria mediante `scripts/verify_ipa.py`.

## Pruebas que pasaron

Las siete pruebas verifican los estados activos de escaneo, la ocultación de identificadores en exportaciones, la inclusión explícita de metadatos completos, el resumen para compartir, el tratamiento de UID cortos, la distinción entre una familia candidata y SUBE verificada, y la serialización del historial.

También pasaron las comprobaciones de configuración, recursos, formatos y referencias del proyecto. La revisión independiente corrigió la disponibilidad de APIs del paquete de pruebas para macOS y el detalle de una lectura borrada que podía permanecer en la navegación de otra pestaña.

## Observaciones del compilador

Xcode emitió dos advertencias de `Sendable` por capturas de objetos Core NFC en el callback de conexión. El lector usa una cola serial para la sesión, sus delegados y las finalizaciones; los objetos NFC no se transfieren al estado de la interfaz. Las advertencias no impidieron la compilación. También apareció el aviso de omisión de metadatos App Intents porque la app no usa ese framework.

## Pendiente de prueba física

- Instalación con una firma y un perfil que permitan NFC TAG.
- Ejecución de la interfaz, VoiceOver y tamaños de texto en el dispositivo.
- Detección de la SUBE concreta del usuario y comportamiento al perder el contacto.
- Ejecución del ayudante de PowerShell en Windows, si se elige esa alternativa; la compilación de esta entrega se inició directamente desde el repositorio.

La imagen de diseño adjunta sigue siendo una maqueta, no una captura del simulador. Esta versión obtiene solamente los metadatos públicos que iOS exponga; no lee saldo ni último viaje mediante autenticación. Una tarjeta no detectada puede usar un protocolo o modo que Core NFC no permita.
