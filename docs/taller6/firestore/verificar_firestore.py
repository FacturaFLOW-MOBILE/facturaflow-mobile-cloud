"""Verificación del modelo implementado en Cloud Firestore.

Comprueba que las colecciones existen en la nube, que las relaciones entre
documentos se resuelven y que las reglas de negocio de los Issues #40, #41
y #42 se cumplen sobre los datos cargados.

Uso:  python verificar_firestore.py
"""

from __future__ import annotations

from google.cloud import firestore

PROJECT_ID = "facturaflow-mcc-2026"
MIN_MOTIVO = 10

db = firestore.Client(project=PROJECT_ID)

ok = 0
fail = 0


def check(label: str, cond: bool, detalle: str = "") -> None:
    global ok, fail
    if cond:
        ok += 1
        print(f"  PASA  {label}" + (f" — {detalle}" if detalle else ""))
    else:
        fail += 1
        print(f"  FALLA {label}" + (f" — {detalle}" if detalle else ""))


print("=" * 70)
print("PRUEBA 1 — Conexión a Cloud Firestore")
print("=" * 70)
check("Cliente conectado al proyecto", db.project == PROJECT_ID, db.project)

print()
print("=" * 70)
print("PRUEBA 2 — Colecciones existentes en la nube")
print("=" * 70)
colecciones = sorted(c.id for c in db.collections())
check("Las 4 colecciones raíz existen",
      {"users", "suppliers", "invoices", "sessions"}.issubset(set(colecciones)),
      ", ".join(colecciones))

print()
print("=" * 70)
print("PRUEBA 7 — Consulta de documentos")
print("=" * 70)
usuarios = list(db.collection("users").stream())
proveedores = list(db.collection("suppliers").stream())
facturas = list(db.collection("invoices").stream())
check("Usuarios cargados", len(usuarios) == 3, f"{len(usuarios)} documentos")
check("Proveedores cargados", len(proveedores) == 3, f"{len(proveedores)} documentos")
check("Facturas cargadas", len(facturas) == 3, f"{len(facturas)} documentos")

print()
print("=" * 70)
print("PRUEBA 5 — Relaciones entre documentos")
print("=" * 70)
f1 = db.collection("invoices").document("900123456-7_FE-1001").get()
check("Factura recuperada por id compuesto", f1.exists, f1.id)
d1 = f1.to_dict()

prov = db.collection("suppliers").document(d1["supplierId"]).get()
check("Referencia a proveedor se resuelve", prov.exists and prov.to_dict()["name"] == "Papelería La 45",
      prov.to_dict()["name"] if prov.exists else "no existe")

usr = db.collection("users").document(d1["createdById"]).get()
check("Referencia a usuario se resuelve", usr.exists and usr.to_dict()["fullName"] == "Ana Torres",
      usr.to_dict()["fullName"] if usr.exists else "no existe")

items = list(f1.reference.collection("items").stream())
check("Subcolección de ítems", len(items) == 2, f"{len(items)} líneas")

eventos = list(f1.reference.collection("events").stream())
check("Subcolección de eventos", len(eventos) >= 1, f"{len(eventos)} eventos")

print()
print("=" * 70)
print("PRUEBA 7b — Cálculo de totales")
print("=" * 70)
subtotal = sum(i.to_dict()["quantity"] * i.to_dict()["unitPriceCents"] for i in items)
check("Subtotal coincide con el almacenado", d1["subtotalCents"] == subtotal,
      f"{d1['subtotalCents']} centavos")
check("Total = subtotal + IVA", d1["totalCents"] == d1["subtotalCents"] + d1["taxCents"],
      f"{d1['totalCents']} centavos")

print()
print("=" * 70)
print("PRUEBA 14 — Reglas de negocio de los Issues del Corte II")
print("=" * 70)

# Issue #41 — el mismo número en dos proveedores distintos convive.
mismas = [f for f in facturas if f.to_dict()["number"] == "FE-1001"]
nits = {f.to_dict()["supplierId"] for f in mismas}
check("Issue #41 — FE-1001 existe en dos proveedores distintos",
      len(mismas) == 2 and len(nits) == 2, ", ".join(sorted(nits)))

# Issue #41 — el id compuesto impide el duplicado dentro del proveedor.
ids = [f.id for f in facturas]
check("Issue #41 — los ids (NIT_numero) son únicos", len(ids) == len(set(ids)),
      f"{len(ids)} facturas, {len(set(ids))} ids distintos")

# Issue #40 — todo motivo almacenado supera el mínimo.
rechazadas = [f.to_dict() for f in facturas if f.to_dict()["status"] == "rechazada"]
check("Issue #40 — hay una factura rechazada", len(rechazadas) == 1)
check("Issue #40 — el motivo supera los 10 caracteres",
      all(len((r["rejectionReason"] or "").strip()) >= MIN_MOTIVO for r in rechazadas),
      f"{len(rechazadas[0]['rejectionReason'])} caracteres" if rechazadas else "")

# Issue #42 — el motivo existe si y solo si el estado es 'rechazada'.
coherentes = all(
    (f.to_dict()["rejectionReason"] is not None) == (f.to_dict()["status"] == "rechazada")
    for f in facturas
)
check("Issue #42 — motivo presente solo en facturas rechazadas", coherentes)

# Issue #42 — la bitácora conserva el motivo tras una reapertura.
f_rech = db.collection("invoices").document("830998877-3_FE-2001")
evs = [e.to_dict() for e in f_rech.collection("events").stream()]
check("Issue #42 — el historial conserva el comentario del rechazo",
      any(e.get("comment") for e in evs), f"{len(evs)} eventos registrados")

print()
print("=" * 70)
print("PRUEBA 7c — Consulta con filtro (índice automático)")
print("=" * 70)
enviadas = list(db.collection("invoices").where(filter=firestore.FieldFilter("status", "==", "enviada")).stream())
check("Filtro por estado 'enviada'", len(enviadas) == 1, f"{len(enviadas)} resultado(s)")

por_emisor = list(db.collection("invoices").where(filter=firestore.FieldFilter("createdById", "==", "u-ana")).stream())
check("Filtro por emisor 'u-ana'", len(por_emisor) == 3, f"{len(por_emisor)} resultado(s)")

print()
print("=" * 70)
print(f"RESULTADO: {ok} aserciones PASA, {fail} FALLA")
print("=" * 70)
raise SystemExit(1 if fail else 0)
