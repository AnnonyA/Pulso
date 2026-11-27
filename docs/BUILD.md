# Compilar y probar Pulso 0.2 desde Windows

El proyecto ya está en [AnnonyA/Pulso](https://github.com/AnnonyA/Pulso). **No necesitás crear otro repositorio ni instalar Xcode en Windows.** GitHub Actions utiliza una Mac para ejecutar las pruebas y generar **Pulso-unsigned.ipa** para iPhone, arquitectura arm64 y **iOS 26.0 como mínimo**.

Pulso 0.2 presenta tres modos, en este orden: **Consultar saldo**, **Historial** y **Acreditar carga**. Consultar saldo es el predeterminado en cada inicio. En esta etapa, los tres modos intentan detectar el chip y obtener los metadatos públicos que iOS exponga; **todavía no leen saldo ni viajes protegidos, ni acreditan cargas**.

## Descargar o iniciar la compilación

1. Abrí [Actions de AnnonyA/Pulso](https://github.com/AnnonyA/Pulso/actions/workflows/ios.yml) con una cuenta con acceso al proyecto.
2. Seleccioná **Compilar IPA - iOS 26**. Si ya hay una ejecución correcta para el commit de la versión 0.2 que querés instalar, abrila directamente.
3. Para compilar de nuevo, elegí **Run workflow**, seleccioná **main** y confirmá **Run workflow**. Los cambios relevantes enviados a main también pueden iniciar el flujo automáticamente.
4. Esperá el resultado de todas las etapas. Una prueba de interfaz fallida o la ausencia del simulador requerido detienen el flujo antes de producir el IPA de esa ejecución.
5. En la ejecución correcta, bajá hasta **Artifacts** y descargá **Pulso-iOS26-unsigned-N**, donde N es su número de ejecución.
6. Extraé el ZIP. El archivo para firmar e instalar es **Pulso-unsigned.ipa**.
7. Descargá por separado **Pulso-iPhone11-UI-N** para revisar las capturas y los resultados de las pruebas nativas.

El IPA, las pruebas y las capturas deben corresponder a **la misma ejecución y al mismo commit**. Un artifact anterior no valida cambios posteriores. El workflow conserva IPA y resultados UI durante 14 días; los logs de compilación, durante 7 días.

## Contenido de los artifacts

| Artifact | Contenido |
| --- | --- |
| Pulso-iOS26-unsigned-N | IPA de dispositivo, requisitos de firma, información del build y huella SHA-256. |
| Pulso-iPhone11-UI-N | Capturas de XCTest, resultados .xcresult, inventario del simulador y logs disponibles. También puede existir si una prueba falla. |
| Pulso-build-log-N | xcodebuild.log, si la ejecución llegó a la compilación del IPA. |

El paquete del IPA contiene:

| Archivo | Uso |
| --- | --- |
| Pulso-unsigned.ipa | Aplicación de iPhone pendiente de firma. |
| NFC-entitlements.plist | Referencia del permiso NFC que debe conservarse al firmar. |
| build-info.json | Plataforma, arquitectura, versión y mínimo iOS verificados. |
| SHA256SUMS.txt | Huella del IPA sin firmar. |
| INSTALL_README.txt | Pasos de prueba y límites de esta versión. |

Desde la carpeta del IPA, podés comparar su huella en PowerShell:

```powershell
Get-FileHash .\Pulso-unsigned.ipa -Algorithm SHA256
```

La huella cambia al volver a firmar el archivo.

## Qué está configurado para probar Actions

Esta sección describe **las comprobaciones previstas**, no afirma que una ejecución concreta haya pasado. Confirmá su resultado en las etapas de Actions, los logs y el archivo **ui-test-summary.json**.

1. Seleccionar Xcode 26 o posterior con un SDK de iPhone 26 o posterior.
2. Validar proyecto, esquemas, configuración NFC, privacidad y recursos.
3. Ejecutar las **13 pruebas de dominio** con **swift test --parallel**: modos, conservación de la operación solicitada, historial anterior, serialización y privacidad.
4. Compilar Debug y ejecutar los tres escenarios UI siguientes en un **simulador iPhone 11 con un runtime iOS 26 instalado**.
5. Compilar Release para dispositivo iPhone, sin firma.
6. Empaquetar la app real de Xcode y verificar Mach-O, arm64, plataforma iPhoneOS, mínimo iOS 26.0, recursos y manifiesto de privacidad.

### Tres escenarios de interfaz nativa

| Escenario | Comprobaciones previstas | Capturas previstas |
| --- | --- | --- |
| Claro | Orden y selección de los tres modos, títulos y límites, respuesta real de NFC no disponible en simulador, modo predeterminado al reiniciar y menú. | Consultar saldo, Historial, Acreditar carga y estado después de reiniciar. |
| Oscuro | Inicio y modo predeterminado con apariencia oscura del sistema. | Consultar saldo en oscuro. |
| Texto grande | Modo predeterminado y cambio a Historial con texto de accesibilidad. | Consultar saldo e Historial con texto grande. |

El script exige **iPhone 11 e iOS 26**. Si faltan, informa el problema; no sustituye silenciosamente otro modelo o versión. Las capturas previstas son imágenes de **828 × 1792 píxeles** obtenidas mediante XCTest.

**Tener el artifact UI no significa que las pruebas hayan pasado**: se intenta conservar evidencia también ante fallos. Revisá el estado de la etapa y el resumen de escenarios. Los archivos .xcresult y los logs permiten comprobar qué se ejecutó.

El simulador no puede leer una tarjeta física. Los argumentos de prueba solo permiten omitir la bienvenida y controlar la apariencia en Debug; no habilitan NFC ficticio ni insertan tarjetas de ejemplo.

## Firma e instalación: habilitar NFC

El IPA está **sin firmar** y no incluye un provisioning profile de Apple. La identidad final de la app, su firma y el perfil deben corresponder. Tanto el perfil como los entitlements firmados deben permitir:

```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>TAG</string>
</array>
```

El bundle identifier inicial es **app.pulso.nfcreader**. Si tu método de firma lo cambia, debe mantenerlo consistente con el perfil y conservar NFC. Copiar NFC-entitlements.plist al IPA o editar un plist no concede ese permiso.

No todos los tipos de cuenta, perfiles o métodos de instalación permiten conservar la capacidad. Si la interfaz abre pero el lector informa un error NFC de permisos, revisá la firma y el perfil. Pulso usa **Core NFC**; no utiliza Apple Pay, HCE ni emulación mediante NFC & SE.

### Cuenta de usuario y autorización de SUBE son cosas distintas

Pulso no pide usuario, contraseña ni inicio de sesión. Eso es independiente de la **autorización técnica para acceder a la tarjeta y sus operaciones protegidas**.

Esta versión no implementa autenticación de la tarjeta ni una integración autorizada para leer saldo, recuperar viajes o acreditar cargas. Seleccionar un modo y detectar el chip no concede ese acceso. La app indica que la operación sigue sin estar disponible; no presenta importes, viajes ni cargas realizadas sin haberlos obtenido realmente.

## Primera prueba con el iPhone 11

1. Usá **iOS 26.0 o posterior** e instalá la app con una firma y un perfil NFC válidos.
2. Abrí Pulso y completá la bienvenida si aparece. La pantalla empieza en **Consultar saldo**.
3. Elegí **Consultar saldo**, **Historial** o **Acreditar carga** y tocá **Iniciar lectura**. Ese botón abre directamente el lector de iOS; no hay una segunda guía que confirmar.
4. Acercá una sola SUBE a la **parte posterior superior del iPhone**, cerca del borde de arriba, y mantenela quieta. Separá otras tarjetas y accesorios que interfieran.
5. Si iOS detecta el chip, Pulso muestra que la operación protegida todavía no está disponible. Abrí **Ver datos del chip** para revisar familia y metadatos.
6. Si no se detecta, cambiá de posición, probá sin una funda que interfiera y repetí. Algunas tarjetas o modos no son accesibles con Core NFC; instalar la app no agrega protocolos que iOS no admite.
7. Para compartir evidencia, usá **Compartir diagnóstico**. El UID completo queda oculto por defecto; incluir los metadatos completos requiere una elección aparte.

El **UID no es el número impreso de SUBE**. Detectar MIFARE Plus no verifica que el emisor sea SUBE. Las fechas del **Historial de lecturas NFC**, disponible en el menú, son momentos de escaneo, no viajes.

## Errores frecuentes

| Problema | Qué revisar |
| --- | --- |
| No aparece Run workflow | Abrí el workflow de AnnonyA/Pulso con permiso para ejecutarlo y comprobá que exista en la rama predeterminada. |
| La ejecución no inicia | Revisá si Actions está habilitado y si hay cuota disponible. |
| Falta iOS 26 o el tipo de dispositivo iPhone 11 | Consultá el inventario y logs de la etapa UI. Son requisitos explícitos de las pruebas. |
| Falla una prueba UI | Descargá Pulso-iPhone11-UI-N y revisá escenario, .xcresult, capturas y logs. Esa ejecución no genera IPA mientras falle la etapa. |
| Error de Swift | Consultá la etapa roja: el build de simulador tiene logs en el artifact UI; el de dispositivo, en Pulso-build-log-N si existe. |
| No aparece el artifact IPA | Verificá que la ejecución completa haya terminado correctamente. Puede haber evidencia UI aunque el empaquetado nunca haya comenzado. |
| El IPA no se instala | Está sin firmar: necesitás firma, perfil y dispositivo autorizados según tu método. |
| Instala, pero NFC falla por permisos | Comprobá NFC TAG en el perfil y los entitlements firmados. |
| Se agota el tiempo | Probá posición, una sola tarjeta y compatibilidad del chip o modo. |
| Detecta MIFARE pero no muestra saldo | Detectar el chip no permite acceder por sí solo a sus datos protegidos ni confirma el emisor. |

## Compilar en una Mac

Desde la raíz del proyecto, con Xcode seleccionado y un runtime iOS 26 instalado:

```bash
python3 scripts/validate_project.py
swift test --parallel
python3 scripts/run_ui_tests.py
bash scripts/build_unsigned_ipa.sh
```

Para ejecutar desde Xcode, abrí Pulso.xcodeproj, elegí tu equipo de desarrollo y configurá un bundle identifier y perfil que permitan NFC. El simulador sirve para la interfaz; la prueba SUBE requiere el iPhone y la tarjeta reales.

## Opcional: crear una copia en otro repositorio

Para AnnonyA/Pulso, seguí el flujo principal. Si querés una copia independiente, podés publicar la carpeta completa con GitHub Desktop o usar **scripts/build-from-windows.ps1** con un nombre nuevo.

Ese ayudante crea **otro repositorio privado**; no reutiliza AnnonyA/Pulso. Requiere Git, GitHub CLI y una carpeta fuera de cualquier repositorio Git. Incluí **.github/workflows/ios.yml** en la raíz. No crees otro repositorio solo porque falle una compilación: corregí el fallo y volvé a ejecutar su workflow.

## Referencias

- [Workflow del proyecto](https://github.com/AnnonyA/Pulso/actions/workflows/ios.yml).
- [GitHub: ejecutar workflows manualmente](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).
- [Imagen oficial del runner macOS 26](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md).
- [Apple: NFCTagReaderSession](https://developer.apple.com/documentation/corenfc/nfctagreadersession).
- [Apple: entitlement NFC](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.nfc.readersession.formats).
- [Apple: capacidades de perfiles iOS](https://developer.apple.com/help/account/reference/supported-capabilities-ios).
- [SUBE: funciones y compatibilidad oficial](https://www.argentina.gob.ar/sube/terminos-y-condiciones-sitio-oficial-sube/app-sube).
