#!/usr/bin/env python
"""Utilidad de linea de comandos de Django para FacturaFlow."""
import os
import sys


def main() -> None:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "facturaflow.settings")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:  # pragma: no cover
        raise ImportError(
            "No se pudo importar Django. Activa el entorno virtual e instala "
            "las dependencias con: pip install -r requirements.txt"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
