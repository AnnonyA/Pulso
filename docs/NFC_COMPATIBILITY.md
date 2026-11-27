# NFC en iPhone: compatibilidad y límites

Esta versión está orientada a iPhone con iOS 26.0 o posterior. El iPhone 11 es el dispositivo de referencia para la interfaz. La compilación para arm64, las pruebas del simulador y una lectura con una tarjeta física verifican aspectos diferentes; ninguno sustituye a los otros.

## Tres modos, una detección real

| Modo | Comportamiento actual |
| --- | --- |
| Consultar saldo, seleccionado al abrir | Detecta una tarjeta compatible y muestra los metadatos públicos. El saldo protegido no está disponible. |
| Historial | Detecta la tarjeta. No obtiene viajes ni presenta los escaneos locales como viajes. |
| Acreditar carga | Detecta la tarjeta. No modifica saldo ni acredita una recarga. |

La app no solicita una cuenta. La falta de inicio de sesión no elimina la autenticación que puede exigir la propia tarjeta ni reemplaza la integración necesaria con el sistema SUBE.

## Qué permite Core NFC

Pulso crea una `NFCTagReaderSession` con sondeo `iso14443`, establece la conexión y consulta propiedades públicas del objeto que devuelve iOS. La familia MIFARE, el UID y los bytes históricos pueden aparecer cuando la tarjeta es compatible. El UID no es el número impreso en la tarjeta; la familia de chip tampoco verifica quién la emitió.

Apple documenta las familias Ultralight, Plus y DESFire, además de un caso `unknown` para una tarjeta ISO 14443 tipo A compatible. La documentación de introducción del acceso nativo excluye MIFARE Classic. Las APIs públicas consultadas no aportan evidencia de que iOS 26 habilite ese protocolo. La existencia de hardware NFC en un iPhone no garantiza que Core NFC entregue un objeto para todas las generaciones o modos de SUBE.

No se incluyeron identificadores de aplicaciones ISO 7816 supuestos. Sin AIDs documentados y declarados, el manejo defensivo de `NFCISO7816Tag` no debe interpretarse como detección general de tarjetas ISO 7816.

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
2. Abrir Pulso, elegir uno de los tres modos y tocar **Iniciar lectura**.
3. Acercar una sola tarjeta al borde superior trasero del iPhone y mantenerla quieta. Retirar tarjetas cercanas y fundas que interfieran.
4. Si se detecta, abrir el diagnóstico para comprobar la familia que expuso iOS. La fecha corresponde al escaneo.
5. Si se agota el tiempo, probar de nuevo con la posición indicada. Un tiempo agotado no demuestra que la tarjeta esté dañada; también puede haber incompatibilidad de protocolo.

La prueba decisiva de detección sigue siendo una sesión con la tarjeta real del usuario. El simulador no tiene una antena NFC y no permite verificar esa parte.

## Fuentes primarias consultadas

- [Apple: modelos de iPhone compatibles con iOS 26, incluido iPhone 11](https://support.apple.com/guide/iphone/iphone-models-compatible-with-ios-26-iphe3fa5df43/26).
- [Apple: NFCTagReaderSession](https://developer.apple.com/documentation/corenfc/nfctagreadersession).
- [Apple: NFCMiFareFamily](https://developer.apple.com/documentation/corenfc/nfcmifarefamily).
- [Apple: connectedTag](https://developer.apple.com/documentation/corenfc/nfctagreadersession/connectedtag-3mlqu).
- [Apple: cola del callback de conexión](https://developer.apple.com/documentation/corenfc/nfctagreadersession/connecttotag%3Acompletionhandler%3A).
- [Apple: Core NFC Enhancements, WWDC19](https://developer.apple.com/videos/play/wwdc2019/715/), protocolos MIFARE y acceso nativo.
- [SUBE: funcionalidades y compatibilidad de la aplicación oficial](https://www.argentina.gob.ar/sube/terminos-y-condiciones-sitio-oficial-sube/app-sube).
