# Estado de la entrega: Pulso 0.2.0

Actualizado el 27 de noviembre de 2026.

**La ejecución #6 terminó correctamente: pasaron las 13 pruebas de dominio y los tres escenarios de interfaz nativa. El IPA de la versión 0.2.0, build 2, está compilado y verificado.** La instalación firmada y la lectura de una SUBE física siguen pendientes.

## Procedencia de esta compilación

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

## Integridad de los archivos

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

## Verificaciones confirmadas de la versión 0.2

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

## Interfaz nativa: ejecución #6 aprobada

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

Esa compilación, su interfaz anterior, sus observaciones del compilador y su maqueta pertenecen a la versión 0.1. No son evidencia de validación de Pulso 0.2 y no deben confundirse con los archivos, huellas ni resultados documentados arriba.
