"""Migración inicial de FacturaFlow.

Enfoque *database-first*: aplica el DDL autoritativo de
`docs/taller6/schema.sql`. Mantener una sola fuente de verdad evita que el
esquema documentado y el que Django crea puedan divergir.
"""

from pathlib import Path

from django.db import migrations

SCHEMA_SQL = (
    Path(__file__).resolve().parent.parent.parent.parent
    / "docs"
    / "taller6"
    / "schema.sql"
)

DROP_SQL = "DROP SCHEMA IF EXISTS facturaflow CASCADE;"


def _forward_sql() -> str:
    return SCHEMA_SQL.read_text(encoding="utf-8")


class Migration(migrations.Migration):
    initial = True

    dependencies: list[tuple[str, str]] = []

    operations = [
        migrations.RunSQL(sql=_forward_sql(), reverse_sql=DROP_SQL),
    ]
