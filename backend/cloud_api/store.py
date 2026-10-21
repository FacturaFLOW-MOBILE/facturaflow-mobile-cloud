"""Acceso a Firestore: credenciales ADC SOLO del lado del servidor."""
from functools import lru_cache
from django.conf import settings
from google.cloud import firestore

@lru_cache(maxsize=1)
def db():
    return firestore.Client(project=settings.FIRESTORE_PROJECT, database='(default)')


def user_public(uid: str, data: dict) -> dict:
    return {'id': uid, 'fullName': data.get('fullName', ''),
            'email': data.get('email', ''), 'role': data.get('role', 'emisor')}


def invoice_to_json(snapshot) -> dict:
    d = snapshot.to_dict() or {}
    items = [s.to_dict() for s in snapshot.reference.collection('items').stream()]
    items.sort(key=lambda x: int(x.get('lineNumber', 0)))
    events = [s.to_dict() for s in snapshot.reference.collection('events').stream()]
    events.sort(key=lambda x: x.get('occurredAt', '').isoformat()
                if hasattr(x.get('occurredAt', ''), 'isoformat') else str(x.get('occurredAt', '')))
    def iso(v):
        return v.isoformat() if hasattr(v, 'isoformat') else str(v or '')
    return {
        'id': snapshot.id, 'number': d.get('number', ''),
        'supplierName': d.get('supplierName', ''),
        'supplierTaxId': d.get('supplierId', ''),
        'issueDate': iso(d.get('issueDate')),
        'items': [{'description': x.get('description', ''),
                   'quantity': int(x.get('quantity', 0)),
                   'unitPriceCents': int(x.get('unitPriceCents', 0)),
                   'taxRate': float(x.get('taxRate', 0.19))} for x in items],
        'status': d.get('status', 'borrador'),
        'createdById': d.get('createdById', ''),
        'createdByName': d.get('createdByName', ''),
        'createdAt': iso(d.get('createdAt')),
        'updatedAt': iso(d.get('updatedAt')),
        'notes': d.get('notes', ''),
        'rejectionReason': d.get('rejectionReason'),
        'history': [{'at': iso(x.get('occurredAt')),
                     'actorId': x.get('actorId', ''),
                     'actorName': x.get('actorName', ''),
                     'status': x.get('status', 'borrador'),
                     'description': x.get('description', ''),
                     'comment': x.get('comment')} for x in events],
    }
