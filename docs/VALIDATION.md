# Estado de la entrega: Pulso

Actualizado el 27 de noviembre de 2026.

## Corrección 0.2.1, build 3

Un usuario instaló la app en un iPhone 11 físico y recibió un aviso de simulador. El código de 0.2.0 utilizaba `readingAvailable == false` para elegir ese mensaje en `ReaderStore.startScan` y mantenía una segunda explicación ambigua en `NFCReader.begin`. La disponibilidad NFC no identifica el entorno de ejecución.

La corrección separa entorno compilado, disponibilidad y errores de sesión, y agrega un diagnóstico compartible incluso sin tarjeta. No se atribuye el estado negativo automáticamente a la firma ni se intenta forzar una sesión cuando Core NFC no la ofrece.

**La ejecución #9 terminó correctamente: pasaron las 24 pruebas de dominio, la compilación Release, la verificación del IPA y los tres escenarios de interfaz.** El IPA de 0.2.1 está descargado y verificado, y la PR #2 se integró en `main` con el mismo árbol de código validado. La instalación firmada y la lectura de una SUBE física siguen pendientes.

### Procedencia actual: ejecución #9

| Dato | Valor confirmado |
| --- | --- |
| Repositorio y PR | [AnnonyA/Pulso](https://github.com/AnnonyA/Pulso), [PR #2](https://github.com/AnnonyA/Pulso/pull/2). |
| Ejecución | [GitHub Actions #9](https://github.com/AnnonyA/Pulso/actions/runs/46057433338). |
| Commit de origen | [3910fc244c2a032863e97359fd23f9f3128f58fb](https://github.com/AnnonyA/Pulso/commit/3910fc244c2a032863e97359fd23f9f3128f58fb). |
| Árbol de origen | `3166636322b594ddcede62a8e54b01db065a6dec`. |
| Versión / build inspeccionados | **0.2.1 / 3**. |
| Compilador | Xcode 26.6 / Apple Swift 6.3.3. |
| Plataforma y arquitectura | iPhoneOS, ejecutable Mach-O arm64. |
| Sistema mínimo / SDK | iOS **26.0** / iPhoneOS **26.5**. |
| Simulador de interfaz | iPhone 11 / iOS 26.5, build 23F77. |
| Configuración y firma | Release, **sin firmar**; necesita firma posterior y un perfil que permita NFC TAG. |
| Artifact del IPA | [Pulso-iOS26-unsigned-9](https://github.com/AnnonyA/Pulso/actions/runs/46057433338/artifacts/15226814351). |
| Integración en main | **Completada** mediante squash de la PR #2: [4bf7560e23f2190b6c486757d0a9a9776d13e544](https://github.com/AnnonyA/Pulso/commit/4bf7560e23f2190b6c486757d0a9a9776d13e544). |

Se verificó que el árbol del commit integrado coincide exactamente con el de la rama probada: `3166636322b594ddcede62a8e54b01db065a6dec`. La actualización posterior de estas notas y capturas modifica únicamente documentación; no cambia el código de la app ni los scripts y pruebas de esa ejecución.

### Integridad de los archivos de 0.2.1

| Archivo | Tamaño | SHA-256 |
| --- | --- | --- |
| Pulso-unsigned.ipa | 552.380 bytes | `0757c424d4e45483eb43bd6d04b202a1509c34e68a7f94edb636125e1d14ca32` |
| ZIP del artifact del IPA | 560.654 bytes | `bd19d1cdd80cf530e2fcd9ef46f77474b10c14294e1d5603128d68a78f69fc18` |
| ZIP del artifact de interfaz | 5.457.873 bytes | `95631b0f7c0c505742b0ba0ccdd017f2cd41ed68914c892627a05e1265a6213d` |

Las huellas corresponden a los archivos de la ejecución #9. Volver a compilar o firmar el IPA puede cambiar su huella.

### Estado de las comprobaciones de 0.2.1

| Comprobación | Estado observado |
| --- | --- |
| Pruebas de dominio | **24 de 24 aprobadas.** |
| Compilación Release, empaquetado y verificación del IPA | **Aprobados.** |
| Inspección del IPA descargado | **Confirmada:** versión 0.2.1, build 3, arm64, iPhoneOS, mínimo 26.0 y SDK 26.5. |
| Pruebas UI de la ejecución #9 | **3 de 3 escenarios aprobados.** |
| Capturas nativas de la ejecución #9 | **12 originales de 828 × 1792 píxeles.** |
| Captura de Diagnóstico NFC | **Inspeccionada.** Original nativo de XCTest, con procedencia documentada. |
| Merge de la PR #2 y comprobación del árbol integrado | **Completados.** Árbol idéntico al validado. |
| Permisos NFC de la instalación y lectura de una SUBE física | **No comprobados por esta ejecución.** |

Las nuevas regresiones cubren la distinción entre dispositivo físico y simulador, la conservación del error original y el diagnóstico sin tarjeta. La comprobación UI aprobada incluye acceder al diagnóstico después de un intento sin tarjeta.

La corrección elimina el mensaje falso de simulador en dispositivo físico; **no valida los entitlements de la instalación, la antena ni la detección de la SUBE del usuario, y no agrega saldo, viajes o acreditación de cargas**. El síntoma reportado permite confirmar el mensaje erróneo; no permite determinar por sí solo la causa de indisponibilidad.

### Interfaz nativa de 0.2.1: ejecución #9 aprobada

XCTest ejecutó los tres escenarios en un **simulador iPhone 11 con iOS 26.5, build 23F77**:

| Escenario | Resultado | Capturas originales |
| --- | --- | --- |
| Claro, incluido el diagnóstico NFC | **Aprobado.** | 7 |
| Oscuro | **Aprobado.** | 2 |
| Texto de accesibilidad | **Aprobado.** | 3 |

El artifact [Pulso-iPhone11-UI-9](https://github.com/AnnonyA/Pulso/actions/runs/46057433338/artifacts/15228131466) conserva las **12 capturas originales de 828 × 1792 píxeles**, los resúmenes, los resultados .xcresult y los logs. Su tamaño y SHA-256 figuran en la tabla de integridad de esta versión.

La [captura de Diagnóstico NFC](screenshots/diagnostico-nfc.png) fue inspeccionada y se conserva con su [procedencia y huella](screenshots/provenance-nfc-0.2.1.json). Es una captura de la app nativa ejecutada por XCTest en el simulador: por eso el diagnóstico identifica correctamente el entorno como **simulador**. Esta imagen verifica la presentación del diagnóstico en ese entorno; no demuestra el funcionamiento de la antena ni una lectura de SUBE física.

### Antecedente parcial de 0.2.1: ejecución #8

La [ejecución #8](https://github.com/AnnonyA/Pulso/actions/runs/46056036957), sobre el commit `d214e132c61b2c8649fa377883b2714e6a2101e0`, aprobó **24 pruebas de dominio** y el escenario **claro, incluido el diagnóstico NFC**. El escenario oscuro falló al agotar una espera de 5 segundos para la comprobación del estado de accesibilidad, aunque el registro y el árbol de accesibilidad mostraban la selección correcta. **El escenario de texto grande no se ejecutó**; no se considera aprobada esa ejecución completa.

El único cambio posterior para la ejecución #9 amplía esa espera de prueba de **5 a 15 segundos**. Conserva la misma comprobación del estado seleccionado y no cambia el código de la app. La evidencia de aprobación de esta entrega es la ejecución #9 completa, con sus tres escenarios aprobados.

## Entrega anterior: 0.2.0, build 2

**La ejecución #6 terminó correctamente: pasaron las 13 pruebas de dominio y los tres escenarios de interfaz nativa. El IPA de la versión 0.2.0, build 2, está compilado y verificado.** La instalación firmada y la lectura de una SUBE física siguen pendientes.

### Procedencia de la compilación 0.2.0

| Dato | Valor confirmado |
| --- | --- |
| Repositorio | [AnnonyA/Pulso](https://github.com/AnnonyA/Pulso). |
| Ejecución | [GitHub Actions #6](https://github.com/AnnonyA/Pulso/actions/runs/45979462687). |
| Commit de origen | [9a3592aeb4955377f7a62313e4835634e46d5871](https://github.com/AnnonyA/Pulso/commit/9a3592aeb4955377f7a62313e4835634e46d5871). |
| Versión / build | 0.2.0 / 2. |
| Compilador | Xcode 26.6 / Apple Swift 6.3.3. |
| SDK de compilación | iPhoneOS 26.5.0. |
| Simulador de interfaz | iPhone 11 / iOS 26.5, build 23F77. |
| Plataforma y arquitectura | iPhoneOS, ejecutable Mach-O arm64. |
| Sistema mínimo | iOS 26.0. |
| Configuración | Release. |
| Firma | Sin firma ni provisioning profile; requiere firma posterior con NFC TAG. |

Artifact del IPA: [Pulso-iOS26-unsigned-6](https://github.com/AnnonyA/Pulso/actions/runs/45979462687/artifacts/15188069496).

El resultado completo de la ejecución está confirmado en sus jobs y logs. Tanto el IPA como la evidencia de interfaz corresponden a la ejecución #6 y al commit de origen indicado.

La [PR #1](https://github.com/AnnonyA/Pulso/pull/1) se integró en **main** mediante el commit [7676268ed469038ebd46edf666b130f12ad11125](https://github.com/AnnonyA/Pulso/commit/7676268ed469038ebd46edf666b130f12ad11125). Se verificó que su árbol Git es exactamente el de la rama validada: `8abcf54d839b3ad048090274baae0b1163ebb0d6`. La incorporación posterior de estas notas y capturas modifica únicamente documentación; no cambia el código de la aplicación ni los scripts probados.

### Integridad de los archivos de 0.2.0

Las huellas siguientes corresponden exactamente al artifact y al IPA de la ejecución #6.

| Archivo | Tamaño |
| --- | --- |
| Pulso-unsigned.ipa | 488.325 bytes. |
| ZIP del artifact | 493.779 bytes. |

SHA-256 del IPA sin firmar:

```text
1c964df2a73f23a92b1d8f217a0d7b92d52683a4011525e8763f008fbad8d91c
```

SHA-256 del ZIP del artifact:

```text
8a4fd6a99d52ee4b9ccef90a7e5148395c0556201be1dc6777d864cc6a56f490
```

El IPA fue verificado como binario de dispositivo arm64 con mínimo iOS 26.0. Una nueva compilación puede cambiar estas huellas. Volver a firmar el IPA también cambia su huella.

### Verificaciones confirmadas de la versión 0.2.0

| Comprobación | Estado |
| --- | --- |
| Pruebas de dominio | **13 de 13 aprobadas.** |
| Compilación Release de iPhone | **Completada.** |
| Empaquetado del IPA | **Completado.** |
| Verificación de plataforma, arquitectura y mínimo iOS | **Aprobada.** |
| Pruebas UI de la ejecución #6 | **3 de 3 escenarios aprobados.** |
| Capturas nativas | **11 originales de 828 × 1792 píxeles.** |
| Revisión visual de la interfaz | **5 capturas inspeccionadas y copiadas sin editar a docs/screenshots.** |
| Instalación y lectura de una SUBE física | **Pendiente.** |

Las pruebas de dominio cubren estados del lector, ocultamiento de identificadores, exportación explícita de metadatos, serialización, compatibilidad con el historial anterior, orden y modo predeterminado, y conservación de la operación elegida al iniciar una solicitud.

También comprueban que detectar el chip no produzca un saldo, un viaje ni una acreditación ficticios: los diagnósticos mantienen los estados de indisponibilidad y señalan que no se realizó una carga.

En la versión 0.2, el callback NFC recupera la sesión y su etiqueta conectada dentro de la cola serial, en lugar de capturar esos objetos en la finalización. Los resultados hacia la interfaz conservan el modo asociado a la solicitud original.

La compilación Release no emitió las advertencias de capturas `Sendable` de la versión anterior. El único aviso de Release fue la omisión de extracción de metadatos de App Intents porque la app no utiliza ese framework.

### Interfaz nativa de 0.2.0: ejecución #6 aprobada

XCTest ejecutó los tres escenarios en un **simulador iPhone 11 con iOS 26.5, build 23F77**. Los tres terminaron correctamente:

| Escenario | Resultado | Capturas originales | Comprobaciones |
| --- | --- | --- | --- |
| Claro | **Aprobado.** | 6 | Orden de Consultar saldo, Historial y Acreditar carga; selección y títulos; error real de NFC no disponible en simulador; retorno a saldo al relanzar; menú. |
| Oscuro | **Aprobado.** | 2 | Inicio y modo predeterminado con la apariencia oscura del sistema. |
| Texto de accesibilidad | **Aprobado.** | 3 | Presentación con texto grande y cambio de Consultar saldo a Historial. |

La evidencia se conserva en [Pulso-iPhone11-UI-6](https://github.com/AnnonyA/Pulso/actions/runs/45979462687/artifacts/15189422262), con resumen de escenarios, las **11 capturas originales de 828 × 1792 píxeles**, resultados .xcresult y logs.

SHA-256 del ZIP del artifact de interfaz:

```text
8c7c664e572996a1d9ac50c659889a608e4914b74e5ea648baff58b4b9d63035
```

Se inspeccionaron estas cinco capturas representativas y se copiaron **sin editar** al repositorio:

| Pantalla | Archivo |
| --- | --- |
| Consultar saldo | [consultar-saldo.png](screenshots/consultar-saldo.png). |
| Historial | [historial.png](screenshots/historial.png). |
| Acreditar carga | [acreditar-carga.png](screenshots/acreditar-carga.png). |
| Apariencia oscura | [oscuro.png](screenshots/oscuro.png). |
| Texto de accesibilidad | [texto-grande.png](screenshots/texto-grande.png). |

[provenance.json](screenshots/provenance.json) registra los orígenes y las huellas de estas copias. Son capturas nativas de la app ejecutándose en el simulador, asociadas al commit documentado.

Las iteraciones anteriores de la versión 0.2 sirvieron para corregir límites de tiempo del entorno. La evidencia de aprobación de esta entrega es la ejecución #6 completa. Ninguna captura ni prueba del simulador demuestra el contacto con una SUBE física.

## Límites funcionales y prueba física pendiente

Pulso no necesita una cuenta de usuario ni iniciar sesión. Eso es distinto de la autorización técnica necesaria para acceder a los datos y operaciones protegidos de SUBE.

En esta versión, los tres modos intentan detectar el chip y obtener los metadatos públicos que iOS exponga. **No leen el saldo real ni los viajes protegidos, no acreditan cargas y no modifican la tarjeta.** Detectar MIFARE Plus no identifica por sí solo al emisor como SUBE; el UID no es el número impreso de la tarjeta.

Queda por comprobar con el iPhone y la SUBE del usuario:

- Instalación con una firma y un perfil que permitan NFC TAG.
- Inicio de una lectura desde cada modo, acercando una sola tarjeta a la parte posterior superior del iPhone.
- Detección del chip concreto y comportamiento frente a pérdida de contacto, cancelación y reintento.
- Interfaz, VoiceOver y tamaños de texto en el dispositivo físico.
- Consistencia de los metadatos y del diagnóstico exportado de una lectura real.

El simulador no realiza estas pruebas NFC. Una instalación correcta tampoco agrega soporte para un protocolo o modo de tarjeta que iOS no exponga.

## Registro histórico breve: versión 0.1.0

La [ejecución #1](https://github.com/AnnonyA/Pulso/actions/runs/45969338666), sobre el commit 46928c7e17f14be549e2f5b118fb59ffbb378600, produjo el primer IPA 0.1.0, build 1, y aprobó siete pruebas de dominio.

Esa compilación, su interfaz anterior, sus observaciones del compilador y su maqueta pertenecen a la versión 0.1. No son evidencia de validación de Pulso 0.2.1 y no deben confundirse con los archivos, huellas ni resultados documentados arriba.
