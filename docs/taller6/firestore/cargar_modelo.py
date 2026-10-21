"""Implementa el modelo de FacturaFlow en Cloud Firestore.

Traduce el modelo relacional validado en PostgreSQL (docs/taller6/schema.sql)
al paradigma documental de Firestore, conservando las mismas entidades,
relaciones y reglas de negocio.

Correspondencia relacional -> documental
---------------------------------------
    app_user       ->  /users/{userId}
    supplier       ->  /suppliers/{supplierId}
    invoice        ->  /invoices/{invoiceId}
    invoice_item   ->  /invoices/{invoiceId}/items/{itemId}      (subcolección)
    invoice_event  ->  /invoices/{invoiceId}/events/{eventId}    (subcolección)
    auth_session   ->  /sessions/{sessionId}

Las líneas y los eventos se modelan como subcolecciones porque su ciclo de
vida depende de la factura: en el modelo relacional la llave foránea declara
ON DELETE CASCADE, y en Firestore la pertenencia jerárquica expresa la misma
dependencia.

El script BORRA por completo las colecciones users, suppliers, invoices y
sessions antes de cargar los datos de demostración. Por eso, sin el
indicador --confirmar-borrado no se conecta ni escribe nada.

Uso:
    python cargar_modelo.py                       # solo informa; no escribe
    python cargar_modelo.py --confirmar-borrado   # borra y recarga la demo
"""

from __future__ import annotations

import argparse
import sys
from datetime import date, datetime, timedelta, timezone

from google.cloud import firestore

PROJECT_ID = "facturaflow-mcc-2026"
COLECCIONES = ("users", "suppliers", "invoices", "sessions")

# ---------------------------------------------------------------------
# Salvaguarda: una ejecución accidental no puede borrar datos reales
# ---------------------------------------------------------------------
parser = argparse.ArgumentParser(description="Carga el modelo de FacturaFlow en Cloud Firestore.")
parser.add_argument(
    "--confirmar-borrado",
    action="store_true",
    help=f"borra {', '.join(COLECCIONES)} en {PROJECT_ID} y carga los datos de demostración",
)
if not parser.parse_args().confirmar_borrado:
    print(f"Este script BORRA {', '.join(COLECCIONES)} en el proyecto {PROJECT_ID}")
    print("y carga en su lugar los datos de demostración. No se escribió nada.")
    print("Para ejecutarlo:  python cargar_modelo.py --confirmar-borrado")
    sys.exit(2)

db = firestore.Client(project=PROJECT_ID)


def now() -> datetime:
    return datetime.now(timezone.utc)


def iso(d: date) -> str:
    return d.isoformat()


# ---------------------------------------------------------------------
# Limpieza de una ejecución previa, para que la carga sea idempotente
# ---------------------------------------------------------------------
def borrar_coleccion(ref, lote: int = 50) -> int:
    borrados = 0
    docs = list(ref.limit(lote).stream())
    while docs:
        for d in docs:
            for sub in d.reference.collections():
                borrados += borrar_coleccion(sub, lote)
            d.reference.delete()
            borrados += 1
        docs = list(ref.limit(lote).stream())
    return borrados


print("Limpiando datos de ejecuciones previas...")
total = sum(borrar_coleccion(db.collection(c)) for c in COLECCIONES)
print(f"  {total} documentos eliminados\n")

# ---------------------------------------------------------------------
# /users — equivale a la tabla app_user
# ---------------------------------------------------------------------
print("Creando /users ...")
usuarios = {
    "u-ana": {
        "fullName": "Ana Torres",
        "email": "ana@facturaflow.demo",
        "role": "emisor",
        "isActive": True,
        "createdAt": now(),
        "updatedAt": now(),
    },
    "u-carlos": {
        "fullName": "Carlos Ruiz",
        "email": "carlos@facturaflow.demo",
        "role": "contador",
        "isActive": True,
        "createdAt": now(),
        "updatedAt": now(),
    },
    "u-lucia": {
        "fullName": "Lucía Peña",
        "email": "lucia@facturaflow.demo",
        "role": "administrador",
        "isActive": True,
        "createdAt": now(),
        "updatedAt": now(),
    },
}
for uid, datos in usuarios.items():
    db.collection("users").document(uid).set(datos)
    print(f"  /users/{uid}  ({datos['role']})")

# ---------------------------------------------------------------------
# /suppliers — equivale a la tabla supplier
# El NIT es el identificador del documento: Firestore no tiene restricción
# UNIQUE, pero usar la clave natural como ID garantiza la unicidad.
# ---------------------------------------------------------------------
print("\nCreando /suppliers ...")
proveedores = {
    "900123456-7": {"taxId": "900123456-7", "name": "Papelería La 45", "createdAt": now()},
    "901555222-1": {"taxId": "901555222-1", "name": "Transportes Andinos S.A.S.", "createdAt": now()},
    "830998877-3": {"taxId": "830998877-3", "name": "Servicios Contables Delta", "createdAt": now()},
}
for sid, datos in proveedores.items():
    db.collection("suppliers").document(sid).set(datos)
    print(f"  /suppliers/{sid}  ({datos['name']})")

# ---------------------------------------------------------------------
# /invoices — equivale a la tabla invoice
#
# El ID del documento codifica la pareja (NIT, número), que es la clave
# de unicidad establecida por el Issue #41. Así Firestore impide el
# duplicado por construcción, igual que la restricción UNIQUE compuesta.
# ---------------------------------------------------------------------
print("\nCreando /invoices con sus subcolecciones ...")


def crear_factura(
    supplier_id: str,
    number: str,
    created_by: str,
    issue_date: date,
    items: list[dict],
    status: str = "borrador",
    notes: str = "",
    rejection_reason: str | None = None,
    events: list[dict] | None = None,
) -> str:
    inv_id = f"{supplier_id}_{number}"
    subtotal = sum(i["quantity"] * i["unitPriceCents"] for i in items)
    impuesto = sum(round(i["quantity"] * i["unitPriceCents"] * i["taxRate"]) for i in items)

    db.collection("invoices").document(inv_id).set({
        "number": number,
        "supplierId": supplier_id,
        "supplierName": proveedores[supplier_id]["name"],
        "issueDate": iso(issue_date),
        "status": status,
        "createdById": created_by,
        "createdByName": usuarios[created_by]["fullName"],
        "notes": notes,
        "rejectionReason": rejection_reason,
        "subtotalCents": subtotal,
        "taxCents": impuesto,
        "totalCents": subtotal + impuesto,
        "createdAt": now(),
        "updatedAt": now(),
    })

    for n, item in enumerate(items, start=1):
        db.collection("invoices").document(inv_id).collection("items").document(f"line-{n}").set({
            "lineNumber": n,
            "description": item["description"],
            "quantity": item["quantity"],
            "unitPriceCents": item["unitPriceCents"],
            "taxRate": item["taxRate"],
        })

    for n, ev in enumerate(events or [{"actorId": created_by, "status": "borrador",
                                       "description": "Factura creada", "comment": None}], start=1):
        db.collection("invoices").document(inv_id).collection("events").document(f"ev-{n:03d}").set({
            "actorId": ev["actorId"],
            "actorName": usuarios[ev["actorId"]]["fullName"],
            "status": ev["status"],
            "description": ev["description"],
            "comment": ev.get("comment"),
            "occurredAt": now(),
        })

    print(f"  /invoices/{inv_id}  ({status}, {len(items)} ítems, total {subtotal + impuesto} centavos)")
    return inv_id


crear_factura(
    "900123456-7", "FE-1001", "u-ana", date(2026, 10, 1),
    [
        {"description": "Resma de papel carta", "quantity": 12, "unitPriceCents": 1_850_000, "taxRate": 0.19},
        {"description": "Tóner impresora láser", "quantity": 2, "unitPriceCents": 24_500_000, "taxRate": 0.19},
    ],
    notes="Pendiente de adjuntar la orden de compra.",
)

# Issue #41: el MISMO número en OTRO proveedor es legítimo y convive.
crear_factura(
    "901555222-1", "FE-1001", "u-ana", date(2026, 10, 2),
    [{"description": "Flete Bogotá - Medellín", "quantity": 1, "unitPriceCents": 128_000_000, "taxRate": 0.19}],
    status="enviada",
    events=[
        {"actorId": "u-ana", "status": "borrador", "description": "Factura creada", "comment": None},
        {"actorId": "u-ana", "status": "enviada", "description": "Enviada a revisión", "comment": None},
    ],
)

# Factura rechazada: el motivo cumple el mínimo de 10 caracteres (Issue #40).
crear_factura(
    "830998877-3", "FE-2001", "u-ana", date(2026, 9, 28),
    [{"description": "Asesoría tributaria mensual", "quantity": 1, "unitPriceCents": 320_000_000, "taxRate": 0.19}],
    status="rechazada",
    rejection_reason="El NIT del proveedor no coincide con el RUT.",
    events=[
        {"actorId": "u-ana", "status": "borrador", "description": "Factura creada", "comment": None},
        {"actorId": "u-ana", "status": "enviada", "description": "Enviada a revisión", "comment": None},
        {"actorId": "u-carlos", "status": "rechazada", "description": "Rechazada por Carlos Ruiz",
         "comment": "El NIT del proveedor no coincide con el RUT."},
    ],
)

# ---------------------------------------------------------------------
# /sessions — equivale a la tabla auth_session
# ---------------------------------------------------------------------
print("\nCreando /sessions ...")
db.collection("sessions").document("sess-demo-001").set({
    "userId": "u-ana",
    "tokenHash": "sha256:9f2c4e1b8a7d635fa0c9e4b7d2a158e3c6b0f94d7e2a815c",
    "issuedAt": now(),
    "expiresAt": now() + timedelta(hours=8),
    "revokedAt": None,
})
print("  /sessions/sess-demo-001")

print("\n" + "=" * 62)
print("Modelo implementado en Cloud Firestore")
print(f"Proyecto: {PROJECT_ID}")
print("=" * 62)
sys.exit(0)
