# Compilar Pulso desde Windows 10

## Resultado esperado

GitHub Actions compila el proyecto con Xcode en un runner `macos-26`. La versión mínima de la app queda fijada en **iOS 26.0**, tanto en el proyecto como en el proceso de compilación. Se produce una aplicación de **iPhone, arm64**, empaquetada en `Pulso-unsigned.ipa`.

No hace falta instalar Xcode en Windows. La firma e instalación se realizan después con tu método elegido.

## Opción A: GitHub Desktop

1. Instalá [GitHub Desktop](https://desktop.github.com/) e iniciá sesión con tu cuenta.
2. Extraé el ZIP recibido. La carpeta correcta contiene directamente `README.md`, `Pulso.xcodeproj`, `Sources`, `Config`, `scripts` y `.github`.
3. Creá un repositorio local nuevo en GitHub Desktop y copiá **todo el contenido** del proyecto dentro de su carpeta. Incluí `.github`, `.gitignore` y `.gitattributes`.
4. Hacé un commit y elegí **Publish repository**. Podés mantenerlo privado.
5. Abrí el repositorio en GitHub. En la raíz deben verse `Pulso.xcodeproj` y `.github/workflows/ios.yml`.
6. Entrá en **Actions**. El primer push a `main` suele iniciar el flujo automáticamente. Si no, seleccioná **Compilar IPA - iOS 26 → Run workflow**.
7. Esperá a que todas las etapas terminen correctamente. Desde la ejecución, descargá **Pulso-iOS26-unsigned-…** en **Artifacts**.
8. Extraé el archivo descargado: contiene `Pulso-unsigned.ipa` y sus notas.

GitHub conserva estos artifacts durante 14 días según el workflow. El consumo de runners y los límites dependen de la cuenta y de la configuración del repositorio; consultá tu sección de Actions antes de habilitar gasto adicional.

## Opción B: PowerShell

Instalá [Git para Windows](https://git-scm.com/download/win) y [GitHub CLI](https://cli.github.com/). Si usás `winget`:

```powershell
winget install --id Git.Git --exact
winget install --id GitHub.cli --exact
```

Cerrá y volvé a abrir PowerShell para actualizar el `PATH`. Configurá tu identidad de commits si todavía no lo hiciste:

```powershell
git config --global user.name "TU NOMBRE"
git config --global user.email "TU CORREO DE GIT O EL NOREPLY DE GITHUB"
```

Dentro de la carpeta extraída:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-from-windows.ps1 -RepositoryName pulso-ios
```

`ExecutionPolicy Bypass` se aplica solamente a ese proceso. El script crea un **repositorio privado nuevo** en la cuenta personal con la que hayas iniciado sesión en `gh`. Si `pulso-ios` ya existe, elegí otro nombre; el ayudante se detiene antes de publicar.

El ayudante requiere una carpeta sin `.git` y fuera de otros repositorios. Esto evita asociarlo por accidente a otro proyecto. La autenticación de GitHub usa el mecanismo habitual de GitHub CLI. El script no guarda tokens en el código ni requiere secretos de Apple.

Al terminar la compilación, el resultado se descarga en `downloads/run-NUMERO/`. Para publicar y seguir la compilación desde el navegador sin esperar en PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-from-windows.ps1 -RepositoryName pulso-ios -SkipDownload
```

Si la publicación quedó hecha pero hubo un corte de conexión al esperar el resultado, no vuelvas a crear el repositorio. Abrí su pestaña Actions y descargá el artifact desde allí.

## Opción C: subir archivos desde GitHub

Creá un repositorio nuevo y usá **Add file → Upload files**. Subí las carpetas y archivos extraídos, no el ZIP y no una carpeta externa que desplace el proyecto un nivel.

Verificá especialmente `.github/workflows/ios.yml`: algunos métodos de arrastrar archivos omiten carpetas ocultas. Si falta, usá **Add file → Create new file**, escribí `.github/workflows/ios.yml` como nombre y pegá el contenido del archivo local. El flujo debe estar en la rama predeterminada para aparecer en **Run workflow**.

## Archivos del artifact

| Archivo | Uso |
| --- | --- |
| `Pulso-unsigned.ipa` | Aplicación compilada de iPhone pendiente de firma. |
| `NFC-entitlements.plist` | Referencia del permiso NFC requerido al firmar. |
| `build-info.json` | Plataforma, arquitectura, versión y mínimo iOS verificados. |
| `SHA256SUMS.txt` | Huella del IPA sin firmar para comprobar su integridad. |
| `INSTALL_README.txt` | Notas de instalación y límites del lector. |

En Windows podés comparar la huella del IPA con `SHA256SUMS.txt`:

```powershell
Get-FileHash .\Pulso-unsigned.ipa -Algorithm SHA256
```

La huella cambia cuando el IPA se vuelve a firmar; eso es esperado.

## Qué valida Actions

1. Selecciona una instalación estable de Xcode 26 o posterior con SDK de iPhone 26 o posterior.
2. Revisa el proyecto, el esquema, los archivos de configuración NFC, el manifiesto de privacidad y los recursos.
3. Ejecuta `swift test --parallel` sobre `PulsoDomain`, un módulo de modelo puro que no depende de Core NFC ni de SwiftUI.
4. Compila `Pulso.xcodeproj` para un dispositivo iPhone genérico, en Release y sin firma.
5. Crea `Payload/Pulso.app` con el resultado real de Xcode y lo empaqueta en un IPA.
6. Verifica el encabezado Mach-O, arquitectura arm64, plataforma iOS, versión mínima 26.0, recursos compilados y manifiesto de privacidad.

El proceso rechaza binarios de simulador y archivos fuente empaquetados como si fueran una app. Ninguna de estas comprobaciones sustituye la prueba NFC con tu tarjeta real.

## Firma e instalación: el requisito para que funcione NFC

El archivo generado está **sin firmar**. Para instalarlo, la identidad del binario, su firma y el provisioning profile deben corresponder. El perfil y los entitlements firmados tienen que permitir:

```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>TAG</string>
</array>
```

El bundle identifier inicial es `app.pulso.nfcreader`. Si tu método de firma lo cambia, debe mantenerlo consistente con el perfil y conservar NFC. El archivo `NFC-entitlements.plist` es solamente una referencia; agregarlo a un ZIP o editar un plist no concede permisos.

Las capacidades disponibles dependen del tipo de cuenta y de perfil de Apple. No se garantiza que todos los métodos de instalación o firmas personales gratuitas permitan esta capacidad. Si instalás la app pero el lector da un error de entitlement, el problema está en la firma/perfil; reinstalar el mismo archivo con el mismo perfil no lo resuelve.

Este lector no usa Apple Pay, HCE ni la plataforma NFC & SE. Tampoco requiere autenticarse con SUBE para detectar los metadatos públicos que iOS exponga.

## Prueba con iPhone 11

1. Comprobá que tenga iOS 26.0 o posterior e instalá la app con un perfil NFC válido.
2. Abrí Pulso y seguí la guía de escaneo.
3. Acercá una sola tarjeta a la parte posterior superior del iPhone, cerca de la cámara. Mantenela quieta durante la lectura.
4. Si se detecta, revisá la familia y el identificador. La app mantiene la distinción entre identificador del chip y número de SUBE.
5. Si no se detecta, quitá otras tarjetas o una funda que interfiera y repetí. Algunas tarjetas o modos no son accesibles con Core NFC; el programa no puede cambiar ese soporte.
6. Si querés compartir el diagnóstico, usá el informe con identificador oculto para empezar.

Las fechas del historial son **momentos de escaneo**, nunca fechas de viajes. Saldo y último viaje siguen sin estar disponibles en esta versión sin autenticación.

## Errores frecuentes

| Problema | Qué revisar |
| --- | --- |
| No aparece el workflow | Debe existir `.github/workflows/ios.yml` en la raíz y en la rama predeterminada. |
| El trabajo no inicia | Revisá si Actions está habilitado y si la cuenta tiene cuota de ejecución. |
| GitHub CLI rechaza el push de un workflow | Revisá que tu autorización de GitHub incluya el alcance `workflow`; con `gh`, usá `gh auth refresh --hostname github.com --scopes workflow`. |
| No hay Xcode compatible | Consultá la imagen oficial del runner; el script muestra la falta de SDK y no produce un IPA falso. |
| Error de Swift | Abrí la etapa roja y descargá `Pulso-build-log-…` si llegó a compilar. Conservá el error exacto para corregirlo. |
| El `.ipa` no se instala | Recordá que está sin firmar; necesitás firma, perfil y dispositivo autorizados según el método elegido. |
| Instala, pero NFC falla por permisos | Comprobá el entitlement NFC y el provisioning profile usados por el firmador. |
| Se agota el tiempo de escaneo | Probá la posición, una sola tarjeta y la compatibilidad de ese chip/modo. |
| Detecta otra tarjeta MIFARE | MIFARE es una familia de chips compartida; la detección no verifica que sea SUBE. |

## Compilar en una Mac, si más adelante tenés acceso

```bash
python3 scripts/validate_project.py
swift test --parallel
bash scripts/build_unsigned_ipa.sh
```

Para ejecutar desde Xcode, abrí `Pulso.xcodeproj`, seleccioná tu equipo de desarrollo y configurá un bundle identifier y perfil que permitan lectura NFC. Las vistas se pueden inspeccionar en el simulador; el NFC necesita un iPhone real.

## Fuentes primarias

- [GitHub: ejecutores hospedados](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).
- [Imagen oficial: macOS 26 / Xcode disponible](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md).
- [GitHub: ejecutar workflows manualmente](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).
- [Apple: NFCTagReaderSession](https://developer.apple.com/documentation/corenfc/nfctagreadersession).
- [Apple: entitlement NFC de lectura](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.nfc.readersession.formats).
- [Apple: capacidades de perfiles iOS](https://developer.apple.com/help/account/reference/supported-capabilities-ios).
- [Apple: razones declaradas para acceso a preferencias y archivos](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons).
