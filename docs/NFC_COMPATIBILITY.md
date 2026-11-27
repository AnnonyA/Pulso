# NFC en iPhone: compatibilidad y límites

Pulso 0.2.1 está orientado a iPhone con iOS 26.0 o posterior. El iPhone 11 es el dispositivo de referencia para la interfaz. La compilación para arm64, las pruebas del simulador y una lectura con una tarjeta física verifican aspectos diferentes; ninguno sustituye a los otros.

## Disponibilidad NFC y entorno son datos distintos

En 0.2.0, un resultado `false` de `readingAvailable` podía producir un mensaje que indicaba usar un iPhone físico, aunque la app ya estuviera instalada en uno. Era un error de diagnóstico de Pulso. **La disponibilidad de lectura no identifica un simulador.** La corrección 0.2.1 distingue el entorno compilado de la disponibilidad que informa Core NFC.

En un dispositivo físico, una disponibilidad negativa no determina por sí sola una causa. La firma y el perfil finales, las restricciones administradas del dispositivo y el estado del servicio NFC son aspectos que deben investigarse según el diagnóstico observado. Apple documenta, por ejemplo, la restricción `allowNFC`. No se puede deducir de ese booleano que el iPhone carezca de NFC, que una herramienta haya eliminado un permiso ni que la tarjeta sea incompatible.

**Diagnóstico NFC** está disponible desde el menú y tras un error, sin necesitar una tarjeta detectada. Su informe compartible reúne versión/build de Pulso, entorno, versión de iOS, disponibilidad y datos del último error cuando existen. No sustituye una lectura física ni verifica por sí solo la validez de la firma. El dominio y código de error ayudan a distinguir una indisponibilidad previa a la sesión de un error producido durante ella.

El empaquetado comprueba `iPhoneOS` y la plataforma iOS del ejecutable Mach-O, además de arm64. Esa verificación evita confundir un binario de simulador arm64 con uno de dispositivo, pero no evalúa los permisos que otra herramienta agregue o elimine al firmarlo después.

## Tres modos y alcance actual

| Modo | Comportamiento actual |
| --- | --- |
| Consultar saldo, seleccionado al abrir | Intenta detectar una tarjeta compatible y mostrar sus metadatos públicos. El saldo protegido no está disponible. |
| Historial | Intenta detectar la tarjeta. No obtiene viajes ni presenta los escaneos locales como viajes. |
| Acreditar carga | Intenta detectar la tarjeta. No modifica saldo ni acredita una recarga. |

La app no solicita una cuenta. La falta de inicio de sesión no elimina la autenticación que puede exigir la propia tarjeta ni reemplaza la integración necesaria con el sistema SUBE.

## Qué permite Core NFC

Pulso crea una `NFCTagReaderSession` con sondeo `iso14443`, establece la conexión y consulta propiedades públicas del objeto que devuelve iOS. La familia MIFARE, el UID y los bytes históricos pueden aparecer cuando la tarjeta es compatible. El UID no es el número impreso en la tarjeta; la familia de chip tampoco verifica quién la emitió.

Apple documenta las familias Ultralight, Plus y DESFire, además de un caso `unknown` para una tarjeta ISO 14443 tipo A compatible. La documentación de introducción del acceso nativo excluye MIFARE Classic. Las APIs públicas consultadas no aportan evidencia de que iOS 26 habilite ese protocolo. La existencia de hardware NFC en un iPhone no garantiza que Core NFC entregue un objeto para todas las generaciones o modos de SUBE.

No se incluyeron identificadores de aplicaciones ISO 7816 supuestos. Sin AIDs documentados y declarados, el manejo defensivo de `NFCISO7816Tag` no debe interpretarse como detección general de tarjetas ISO 7816.

## Firma y autorización de la instalación

La app utiliza `com.apple.developer.nfc.readersession.formats = ["TAG"]`. El perfil debe autorizar la capacidad y la firma de la app debe reclamarla. El archivo de entitlements incluido como referencia en el ZIP no la concede. Una app que abre correctamente puede seguir sin disponer de una capacidad que no quedó habilitada durante la firma.

La [tabla de Apple](https://developer.apple.com/help/account/reference/supported-capabilities-ios) marca NFC Tag Reading para Apple Developer Program y Enterprise Program, pero no para la columna gratuita Apple Developer. [Apple DTS explica](https://developer.apple.com/forums/thread/821896) que esa columna corresponde al aprovisionamiento gratuito llamado Personal Team en Xcode. Si se utilizó una cuenta gratuita, es un punto concreto que revisar; no demuestra qué cuenta o perfil se usó en la instalación del usuario.

Apple describe `readerErrorSecurityViolation` como una violación de seguridad asociada a la sesión. Ese error justifica revisar firma y permisos, pero no identifica automáticamente qué parte de la instalación falló. El diagnóstico debe conservar el error observado y separar las causas posibles de las confirmadas.

La [guía de compilación y firma](BUILD.md#diagnóstico-nfc-sin-detectar-una-tarjeta) explica qué datos recuperar del instalador y cómo inspeccionar opcionalmente el IPA firmado con las herramientas oficiales `codesign` y `security` en una Mac. Pulso no interpreta formatos privados de firmas ni perfiles como prueba de autorización. Apple advierte en TN3125 que esos formatos pueden cambiar y que las representaciones DER son relevantes en sistemas actuales.

## Cambios para una sesión consistente

- Una sola sesión activa; los toques repetidos no crean sesiones paralelas.
- El modo se fija al iniciar y acompaña al resultado. Cambiar la selección después no cambia el significado de una lectura anterior.
- La sesión, las etiquetas y sus callbacks permanecen en una cola serial. El callback de conexión recupera `connectedTag` en esa misma cola, evitando capturar objetos NFC no Sendable.
- Los callbacks atrasados se descartan por identificador de solicitud.
- Se reintenta el contacto dentro de la sesión y se pide separar tarjetas cuando se detectan varias.
- La app cancela al ir a segundo plano, pero no cuando la hoja NFC del sistema la vuelve inactiva temporalmente.
- El resultado distingue «tarjeta detectada» de una consulta o acreditación completada. No se producen resultados de transporte ficticios.

## Recursos y rendimiento

La pantalla usa componentes nativos y una ilustración vectorial estática. No mantiene animaciones o consultas de red en segundo plano, ni busca tarjetas fuera de una sesión iniciada por el usuario. El historial local está limitado a 50 lecturas. Estos son criterios de implementación; no representan mediciones de FPS, batería o latencia en un iPhone físico.

## Prueba en el iPhone 11

1. Instalar el IPA con una firma y un perfil que habiliten NFC Tag Reading (`TAG`).
2. Abrir Pulso, elegir uno de los tres modos y tocar **Iniciar lectura**. Si iOS no habilita la sesión, compartir **Diagnóstico NFC** antes de atribuir el fallo a la tarjeta.
3. Acercar una sola tarjeta al borde superior trasero del iPhone y mantenerla quieta. Retirar tarjetas cercanas y fundas que interfieran.
4. Si se detecta, abrir el diagnóstico para comprobar la familia que expuso iOS. La fecha corresponde al escaneo.
5. Si se agota el tiempo, probar de nuevo con la posición indicada. Un tiempo agotado no demuestra que la tarjeta esté dañada; también puede haber incompatibilidad de protocolo.

La prueba decisiva de detección sigue siendo una sesión con la tarjeta real del usuario. El simulador no tiene una antena NFC y no permite verificar esa parte.

## Fuentes primarias consultadas

- [Apple: modelos de iPhone compatibles con iOS 26, incluido iPhone 11](https://support.apple.com/guide/iphone/iphone-models-compatible-with-ios-26-iphe3fa5df43/26).
- [Apple: NFCTagReaderSession](https://developer.apple.com/documentation/corenfc/nfctagreadersession).
- [Apple: ejemplo oficial de lector y comprobación de disponibilidad](https://developer.apple.com/documentation/corenfc/building-an-nfc-tag-reader-app).
- [Apple: entitlement de lectura NFC TAG](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.nfc.readersession.formats).
- [Apple: capacidades según el tipo de membresía](https://developer.apple.com/help/account/reference/supported-capabilities-ios).
- [Apple: TN3125, perfiles y entitlements de firma](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles).
- [Apple: error de seguridad de una sesión NFC](https://developer.apple.com/documentation/corenfc/nfcreadererror-swift.struct/code/readererrorsecurityviolation).
- [Apple: restricciones administradas, incluido allowNFC](https://developer.apple.com/documentation/devicemanagement/restrictions).
- [Apple: NFCMiFareFamily](https://developer.apple.com/documentation/corenfc/nfcmifarefamily).
- [Apple: connectedTag](https://developer.apple.com/documentation/corenfc/nfctagreadersession/connectedtag-3mlqu).
- [Apple: cola del callback de conexión](https://developer.apple.com/documentation/corenfc/nfctagreadersession/connecttotag%3Acompletionhandler%3A).
- [Apple: Core NFC Enhancements, WWDC19](https://developer.apple.com/videos/play/wwdc2019/715/), protocolos MIFARE y acceso nativo.
- [SUBE: funcionalidades y compatibilidad de la aplicación oficial](https://www.argentina.gob.ar/sube/terminos-y-condiciones-sitio-oficial-sube/app-sube).
