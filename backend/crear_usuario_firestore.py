"""Crea credenciales de la app sin borrar facturas existentes.

Ejemplo:
  python crear_usuario_firestore.py --id u-ana --email ana@facturaflow.demo

No usa Firebase Authentication. Hash en /credentials, separado de /users.
"""
import argparse
import getpass
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from dotenv import load_dotenv
load_dotenv(Path(__file__).resolve().parent / '.env.firestore')
from django.conf import settings
if not settings.configured:
    settings.configure(PASSWORD_HASHERS=['django.contrib.auth.hashers.PBKDF2PasswordHasher'])
from django.contrib.auth.hashers import make_password
from google.cloud import firestore

parser = argparse.ArgumentParser()
parser.add_argument('--id', help='ID de users existente, p. ej. u-ana')
parser.add_argument('--email', required=True)
parser.add_argument('--role', choices=['emisor', 'contador', 'administrador'], default='emisor')
parser.add_argument('--name', default='')
args = parser.parse_args()
uid = args.id or uuid.uuid4().hex
password = getpass.getpass('Contraseña de FacturaFLOW (oculta): ')
confirm = getpass.getpass('Repetir contraseña: ')
if password != confirm or len(password) < 12:
    raise SystemExit('Las claves deben coincidir y tener al menos 12 caracteres.')
project = os.getenv('FIRESTORE_PROJECT', 'facturaflow-mcc-2026')
db = firestore.Client(project=project)
user_ref = db.collection('users').document(uid)
current = user_ref.get()
if current.exists:
    if (current.to_dict() or {}).get('email', '').strip().lower() != args.email.strip().lower():
        raise SystemExit('El correo no coincide con el usuario existente. Operación cancelada.')
    print('Actualizando credenciales del usuario existente:', uid)
else:
    if not args.name:
        raise SystemExit('Para usuario nuevo debes proporcionar --name.')
    existing = next(db.collection('users').where('email', '==', args.email.strip().lower()).limit(1).stream(), None)
    if existing is not None:
        raise SystemExit('Ya existe otro usuario con este correo.')
    user_ref.create({'fullName': args.name.strip(), 'email': args.email.strip().lower(),
                     'role': args.role, 'isActive': True,
                     'createdAt': datetime.now(timezone.utc),
                     'updatedAt': datetime.now(timezone.utc)})
db.collection('credentials').document(uid).set({'passwordHash': make_password(password),
                                                'updatedAt': datetime.now(timezone.utc)})
print('Usuario listo:', uid, '— proyecto:', project)
