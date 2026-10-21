"""Sesiones con tokens opacos aleatorios y hash SHA-256 almacenado en Firestore."""
import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from functools import wraps
from django.http import JsonResponse
from google.cloud.firestore_v1.base_query import FieldFilter
from .store import db, user_public

TTL = timedelta(hours=8)

def now():
    return datetime.now(timezone.utc)


def token_hash(token):
    return hashlib.sha256(token.encode('utf-8')).hexdigest()


def new_session(user_id):
    token = secrets.token_urlsafe(32)
    db().collection('sessions').add({
        'userId': user_id, 'tokenHash': token_hash(token),
        'issuedAt': now(), 'expiresAt': now() + TTL, 'revokedAt': None,
    })
    return token


def current_session(request):
    header = request.headers.get('Authorization', '')
    if not header.startswith('Bearer ') or not header[7:].strip():
        return None
    digest = token_hash(header[7:].strip())
    matches = db().collection('sessions').where(
        filter=FieldFilter('tokenHash', '==', digest)).limit(1).stream()
    session = next(matches, None)
    if session is None:
        return None
    record = session.to_dict() or {}
    expiry = record.get('expiresAt')
    if record.get('revokedAt') is not None or not expiry or expiry <= now():
        return None
    user = db().collection('users').document(record['userId']).get()
    if not user.exists or not (user.to_dict() or {}).get('isActive', True):
        return None
    return session, user_public(user.id, user.to_dict())


def require_auth(view):
    @wraps(view)
    def handler(request, *args, **kwargs):
        try:
            result = current_session(request)
        except Exception:
            return JsonResponse({'detail': 'Error al validar sesión con el servidor cloud.'}, status=503)
        if result is None:
            return JsonResponse({'detail': 'Sesión inválida o expirada.'}, status=401)
        request.cloud_session, request.cloud_user = result
        return view(request, *args, **kwargs)
    return handler
