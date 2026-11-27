# Pulso para SUBE

**Lector NFC nativo para iPhone, con iOS 26.0 como versión mínima.** Creado para probar qué información pública puede obtener el iPhone de tu tarjeta SUBE, con una interfaz en español y sin inicio de sesión.

El proyecto usa Swift 6, SwiftUI y Core NFC. No requiere backend ni dependencias de terceros para compilar la app.

[![Compilar IPA - iOS 26](https://github.com/AnnonyA/Pulso/actions/workflows/ios.yml/badge.svg)](https://github.com/AnnonyA/Pulso/actions/workflows/ios.yml)

## Interfaz de tres modos — versión 0.2.0

La pantalla principal sigue la referencia visual de SUBE: encabezado azul, tres selectores circulares, tarjeta junto al iPhone e indicación **Apoyá la SUBE**.

1. **Consultar saldo** es el modo inicial cada vez que se abre la app.
2. **Historial** corresponde a los viajes de transporte.
3. **Acreditar carga** corresponde a la intención de acreditar una recarga.

Los tres modos permiten iniciar una sesión NFC real para identificar una tarjeta que iOS pueda detectar. El acceso a los datos y las operaciones protegidas de SUBE todavía no está implementado: el saldo, los viajes y las acreditaciones **no están disponibles**. La app explica ese estado antes de leer y al mostrar el resultado; no muestra saldos, viajes o acreditaciones ficticias. La ausencia de una cuenta de usuario no reemplaza la autorización técnica que exige la tarjeta.

El menú reúne el registro local de **lecturas NFC**, los ajustes y la ayuda. Las lecturas guardadas están separadas del modo Historial de viajes.

La documentación de [compatibilidad NFC](docs/NFC_COMPATIBILITY.md) detalla el alcance y los límites en iPhone. Las capturas de revisión de esta versión se generarán en el simulador de iPhone 11 mediante XCTest; no se reutiliza la maqueta de la versión anterior como prueba de ejecución.

## Generar el `.ipa` desde Windows 10

La vía principal es **GitHub Actions**: GitHub ejecuta Xcode en una máquina macOS y entrega el archivo descargable. No necesitás tener una Mac.

1. Abrí [Actions de AnnonyA/Pulso](https://github.com/AnnonyA/Pulso/actions/workflows/ios.yml).
2. Elegí una ejecución correcta de `main`, o **Run workflow → main** para generar otra. También se ejecuta con cambios de la app en `main` y con pull requests.
3. Cuando termine correctamente, abrí **Artifacts → Pulso-iOS26-unsigned-…**.
4. Extraé el ZIP del artifact. Ahí estará **`Pulso-unsigned.ipa`**, junto con su huella y las notas de firma.
5. El artifact **Pulso-iPhone11-UI-…** contiene las capturas nativas, los registros y los resultados de las pruebas en simulador.

La guía [docs/BUILD.md](docs/BUILD.md) explica GitHub Desktop, el ayudante de PowerShell, compilación, firma, diagnósticos y resolución de errores.

### Crear otro repositorio, opcional

El repositorio `AnnonyA/Pulso` ya está configurado. Solo si querés crear una copia independiente, con Git y GitHub CLI instalados podés abrir PowerShell en una carpeta del proyecto sin `.git` y ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-from-windows.ps1 -RepositoryName pulso-ios
```

El script inicia sesión con GitHub si hace falta, crea un **repositorio privado nuevo**, sube el proyecto, espera la compilación y descarga el artifact. Rechaza repositorios existentes para no tocar otro proyecto tuyo. Necesita que tu nombre y correo de autor estén configurados en Git. No sube certificados ni solicita credenciales de Apple.

## Qué incluye

- Pantalla principal con tres modos y guía para acercar una sola tarjeta al borde superior trasero del iPhone.
- Sesión NFC real mediante `NFCTagReaderSession`, con manejo de cancelación, espera agotada, varias tarjetas y errores.
- Datos públicos que iOS exponga: tecnología, familia MIFARE, identificador del chip y metadatos disponibles.
- Resultado asociado al modo que inició el escaneo, con estado claro y exportación de diagnóstico.
- Historial local opcional de hasta 50 lecturas, con eliminación.
- Ajustes, privacidad, ayuda, tema claro/oscuro y accesibilidad.
- Ícono propio y configuración de NFC, privacidad y despliegue.
- Compilación automatizada, pruebas del modelo, pruebas de interfaz en iPhone 11 simulado, capturas reales y validación del binario IPA.

## Alcance de esta versión

**Detectar MIFARE Plus no confirma que una tarjeta sea SUBE.** El UID del chip tampoco equivale al número impreso de la tarjeta.

Saldo y último viaje aparecen como **no disponibles**: esta versión no autentica sectores ni interpreta datos protegidos, y no inventa valores. No acredita cargas, no escribe en la tarjeta y no emula una SUBE. Determinadas generaciones o modos de tarjetas SUBE pueden no ser detectables con Core NFC.

Pulso es un proyecto independiente; no es la app oficial de SUBE ni está afiliado a Nación Servicios.

## Firma y NFC

El flujo entrega un **IPA sin firmar**. Para instalarlo, tu método de firma debe usar una identidad y un perfil válidos que permitan **Near Field Communication Tag Reading** y conserven `com.apple.developer.nfc.readersession.formats = ["TAG"]`.

El artifact incluye el archivo de entitlements como referencia; ese archivo no concede permisos por sí mismo. Que una herramienta consiga instalar la app no garantiza que conserve la capacidad NFC. No se necesitan las autorizaciones especiales de emulación de tarjetas de NFC & SE para este lector.

## Estructura

```text
Pulso.xcodeproj/          Proyecto de Xcode y esquema compartido
Sources/Pulso/           App, interfaz, modelo, NFC y recursos
Config/                  Info.plist y entitlements
Tests/PulsoDomainTests/   Pruebas del modelo sin hardware
Tests/PulsoUITests/       Pruebas nativas de interfaz en iPhone 11
.github/workflows/       Compilación de iPhone en macOS
scripts/                 Ayudantes y validadores
docs/BUILD.md            Guía para Windows y firma
```

## Estado de validación

La versión 0.1.0 se compiló correctamente en la [ejecución #1](https://github.com/AnnonyA/Pulso/actions/runs/45969338666). La versión 0.2.0 amplía las pruebas de modelos y agrega validación de interfaz con capturas en un simulador iPhone 11. Sus resultados se registran en [docs/VALIDATION.md](docs/VALIDATION.md) al terminar la ejecución correspondiente.

La compilación y el simulador no verifican la antena NFC ni garantizan que una SUBE de cualquier generación sea detectable. La instalación con firma válida y la lectura de tu tarjeta física siguen siendo comprobaciones independientes.

## Referencias

- [Core NFC: NFCTagReaderSession](https://developer.apple.com/documentation/corenfc/nfctagreadersession)
- [Entitlement de lectura NFC](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.nfc.readersession.formats)
- [Capacidades y perfiles iOS](https://developer.apple.com/help/account/reference/supported-capabilities-ios)
- [Ejecutores hospedados de GitHub](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Software del runner macOS 26](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md)
