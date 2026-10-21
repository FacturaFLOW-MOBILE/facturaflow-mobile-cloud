# Pruebas de las reglas de seguridad de Firestore

Ejecutan `../firestore.rules` contra el emulador local de Firestore. No se
conectan al proyecto en la nube ni tocan sus datos: `demo-facturaflow` es un
identificador de demostración, y el emulador no permite que un proyecto con
prefijo `demo-` acceda a recursos reales.

## Requisitos

- Node.js 18 o superior
- Java 21 o superior (lo exige el emulador de firebase-tools 15)
- Firebase CLI: `npm install -g firebase-tools`

## Ejecución

```bash
npm ci
npm test
```

`npm test` inicia el emulador, ejecuta `reglas.test.mjs` con `node --test` y
lo apaga al terminar. Antes de cada prueba se vacía la base del emulador y se
cargan cuatro perfiles —dos emisores (Ana y Otro), un contador (Carlos) y una
administradora (Lucía)— y cinco facturas en distintos estados.

## Qué cubren

| Grupo | Qué se verifica |
|---|---|
| Lectura y aislamiento entre usuarios | Un emisor no ve las facturas de otro, ni sus ítems ni su historial (hallazgo #2 de la revisión del PR #61) |
| Issue #41 | El id `{NIT}_{número}` impide el duplicado dentro del proveedor |
| Issue #40 | Un rechazo exige un motivo de al menos 10 caracteres |
| Issue #42 | El motivo solo existe mientras la factura está rechazada |
| Flujo de estados y separación de funciones | Nadie aprueba su propia factura; el revisor no altera el contenido; el número y el proveedor son inmutables |
| Bitácora de auditoría | Los eventos se firman con el usuario autenticado, reflejan el estado real, usan la hora del servidor y no se modifican |
| Borrado | Solo se borra un borrador propio; un proveedor nunca se borra |
| Perfiles y proveedores | Nadie se cambia el rol ni crea perfiles; el NIT debe estar bien formado |

Cada prueba que espera un rechazo usa `assertFails`, de modo que fallaría si
la regla correspondiente no existiera.
