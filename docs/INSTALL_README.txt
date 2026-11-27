PULSO 0.2 - iPhone / iOS 26.0 o posterior

REPOSITORIO Y COMPILACION

El repositorio ya existe: https://github.com/AnnonyA/Pulso
Desde Windows, abri:
https://github.com/AnnonyA/Pulso/actions/workflows/ios.yml

Elegi una ejecucion correcta para el commit que queres instalar, o usa
Run workflow sobre main. Descarga Pulso-iOS26-unsigned-N y extrae el ZIP.
No hace falta crear otro repositorio ni instalar Xcode en Windows.

El paquete contiene Pulso-unsigned.ipa, un ejecutable arm64 para iPhone.
Esta SIN FIRMAR y no incluye un provisioning profile de Apple.

FIRMA Y PERMISO NFC

Antes de instalar, usa tu metodo de firma autorizado. La identidad final
de la app, su firma y el provisioning profile deben corresponder.
Tanto el perfil como los entitlements firmados deben permitir:

  com.apple.developer.nfc.readersession.formats = ["TAG"]

NFC-entitlements.plist describe el permiso requerido. El archivo por si
solo no lo concede. Si el firmador elimina esa capacidad, la interfaz
puede abrir pero el lector no funcionara. Comproba las capacidades de tu
cuenta y perfil; no todos los metodos de firma las permiten.

Pulso usa Core NFC. No usa Apple Pay, HCE ni emulacion NFC & SE.

LOS TRES MODOS

1. Consultar saldo: modo predeterminado cada vez que abris la app.
2. Historial: se refiere a viajes, no al registro local de escaneos.
3. Acreditar carga.

En esta version, los tres modos intentan detectar el chip y leer los
metadatos publicos que iOS exponga. TODAVIA NO leen el saldo ni los viajes
protegidos, y NO acreditan cargas ni modifican la tarjeta.

SIN CUENTA NO SIGNIFICA SIN PROTECCION DE LA TARJETA

Pulso no pide usuario, contrasena ni inicio de sesion. Eso es distinto de
la autenticacion tecnica de la tarjeta y de la integracion autorizada
necesaria para acceder a las operaciones protegidas de SUBE. Esta version
no implementa ese acceso. Detectar el chip no lo habilita.

COMO PROBAR EN EL IPHONE 11

1. Usa iOS 26.0 o posterior y una instalacion con permiso NFC valido.
2. Abri Pulso y completa la bienvenida si aparece.
3. Elegi Consultar saldo, Historial o Acreditar carga.
4. Toca Iniciar lectura: se abre directamente el lector de iOS.
5. Apoya una sola SUBE junto al borde posterior superior del iPhone y
   mantenela quieta. Separa otras tarjetas y accesorios que interfieran.
6. Si se detecta, veras que la operacion protegida sigue sin estar
   disponible. Ver datos del chip muestra la familia y los metadatos.
7. Para compartir, usa Compartir diagnostico. El UID completo se oculta
   por defecto; incluirlo requiere una eleccion aparte.

La app permite guardar hasta 50 lecturas locales y borrarlas. El menu
Historial de lecturas NFC contiene escaneos, NO viajes. La fecha de una
lectura es el momento del escaneo, no la fecha de un viaje.

LIMITES DE LA DETECCION

- Detectar una tarjeta no demuestra que sea una SUBE autentica.
- El UID del chip no es el numero impreso de SUBE.
- Algunas tarjetas o modos no son accesibles mediante Core NFC.
- Instalar o firmar la app no agrega protocolos que iOS no admita.
- No se muestran saldos estimados, viajes ficticios ni cargas realizadas.

PRUEBAS Y CAPTURAS DE INTERFAZ

El workflow esta configurado para tres escenarios reales de XCTest en
un simulador iPhone 11 con iOS 26: apariencia clara con los tres modos
y reinicio, apariencia oscura, y texto grande de accesibilidad.

Los resultados se guardan aparte en Pulso-iPhone11-UI-N. Revisa el estado
de la etapa y ui-test-summary.json antes de afirmar que las pruebas
pasaron. Ese artifact tambien puede existir para diagnosticar un fallo.
La presencia de capturas no demuestra una lectura NFC fisica.

El simulador no puede leer tu SUBE. La comprobacion real requiere tu
iPhone y tu tarjeta, incluso si el build y todas las pruebas pasan.

INTEGRIDAD DEL ARCHIVO

build-info.json registra plataforma, arquitectura, version y minimo iOS.
SHA256SUMS.txt contiene la huella del IPA sin firmar. En PowerShell:

  Get-FileHash .\Pulso-unsigned.ipa -Algorithm SHA256

La huella cambia al volver a firmar el IPA.
