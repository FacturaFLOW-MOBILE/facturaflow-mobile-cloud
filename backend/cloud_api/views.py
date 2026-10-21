"""Contrato HTTP de lib/data/remote/remote_repositories.dart. Sin Firebase SDK en Flutter."""
import json
import re
from datetime import date
from functools import wraps
from django.contrib.auth.hashers import check_password
from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from google.api_core.exceptions import AlreadyExists, FailedPrecondition, GoogleAPICallError
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore_v1._helpers import LastUpdateOption
from .security import new_session, now, require_auth
from .store import db, invoice_to_json


class ApiError(Exception):
    def __init__(self, message, status=400):
        super().__init__(message)
        self.status = status


def methods(*allowed):
    def wrapper(view):
        @csrf_exempt
        @wraps(view)
        def call(request, *args, **kwargs):
            if request.method not in allowed:
                return JsonResponse({'detail': 'Método no permitido.'}, status=405)
            try:
                return view(request, *args, **kwargs)
            except ApiError as exc:
                return JsonResponse({'detail': str(exc)}, status=exc.status)
            except (AlreadyExists, FailedPrecondition):
                return JsonResponse({'detail': 'Conflicto: el registro ya existe o cambió.'}, status=409)
            except GoogleAPICallError:
                return JsonResponse({'detail': 'No se pudo acceder a Firestore.'}, status=503)
        return call
    return wrapper


def payload(request):
    if len(request.body) > 100_000 or request.content_type != 'application/json':
        raise ApiError('Se requiere JSON y tamaño máximo de 100 KB.', 415)
    try:
        data = json.loads(request.body)
        if not isinstance(data, dict):
            raise ValueError('Objeto requerido')
        return data
    except (ValueError, UnicodeError):
        raise ApiError('JSON inválido.')


def ensure(condition, message, status=400):
    if not condition:
        raise ApiError(message, status)


def accessible(doc, actor):
    data = doc.to_dict() or {}
    return actor['role'] in ('contador', 'administrador') or data.get('createdById') == actor['id']


def editable(doc, actor):
    d = doc.to_dict() or {}
    return d.get('status') in ('borrador', 'rechazada') and actor['role'] in ('emisor', 'administrador') and (
        d.get('createdById') == actor['id'] or actor['role'] == 'administrador')


def invoice_doc(invoice_id):
    doc = db().collection('invoices').document(invoice_id).get()
    ensure(doc.exists, 'Factura no encontrada.', 404)
    return doc


def validate_draft(data):
    number = str(data.get('number', '')).strip().upper()
    supplier = str(data.get('supplierTaxId', '')).strip()
    name = str(data.get('supplierName', '')).strip()
    issue_date = str(data.get('issueDate', ''))[:10]
    notes = str(data.get('notes', '')).strip()
    ensure(bool(re.fullmatch(r'[A-Z0-9][A-Z0-9.\-_]{2,39}', number)), 'Número de factura inválido.')
    ensure(bool(re.fullmatch(r'[0-9.\-]{5,20}', supplier)), 'NIT del proveedor inválido.')
    ensure(0 < len(name) <= 160, 'Nombre del proveedor obligatorio (máx. 160).')
    try:
        date.fromisoformat(issue_date)
    except ValueError:
        raise ApiError('Fecha de factura inválida.')
    ensure(len(notes) <= 2000, 'Notas demasiado largas.')
    raw_items = data.get('items')
    ensure(isinstance(raw_items, list) and 0 < len(raw_items) <= settings.MAX_ITEMS,
           f'Ingresa entre 1 y {settings.MAX_ITEMS} ítems.')
    items = []
    for pos, item in enumerate(raw_items, 1):
        ensure(isinstance(item, dict), 'Ítem inválido.')
        description = str(item.get('description', '')).strip()
        qty, unit, tax = item.get('quantity'), item.get('unitPriceCents'), item.get('taxRate', 0.19)
        ensure(0 < len(description) <= 255, 'Descripción del ítem obligatoria.')
        ensure(type(qty) is int and qty > 0 and qty < 100000, 'Cantidad inválida.')
        ensure(type(unit) is int and 0 < unit < 10**13, 'Precio unitario inválido.')
        ensure(type(tax) in (float, int) and 0 <= tax <= 1, 'Impuesto inválido.')
        items.append({'lineNumber': pos, 'description': description,
                      'quantity': qty, 'unitPriceCents': unit, 'taxRate': float(tax)})
    return {'number': number, 'supplierId': supplier, 'supplierName': name,
            'issueDate': issue_date, 'notes': notes}, items


def add_event(batch, invoice_ref, actor, status, description, comment=None):
    event = invoice_ref.collection('events').document()
    batch.set(event, {'actorId': actor['id'], 'actorName': actor['fullName'],
                      'status': status, 'description': description,
                      'comment': comment, 'occurredAt': now()})


def monetary(items):
    sub = sum(x['quantity'] * x['unitPriceCents'] for x in items)
    tax = sum(round(x['quantity'] * x['unitPriceCents'] * x['taxRate']) for x in items)
    return {'subtotalCents': sub, 'taxCents': tax, 'totalCents': sub + tax}


@methods('GET')
def health(request):
    try:
        next(db().collection('invoices').limit(1).stream(), None)
        return JsonResponse({'status': 'ok', 'database': 'connected', 'project': settings.FIRESTORE_PROJECT})
    except Exception:
        return JsonResponse({'status': 'unavailable', 'database': 'disconnected'}, status=503)


@methods('POST')
def login(request):
    data = payload(request)
    email = str(data.get('email', '')).strip().lower()
    password = data.get('password', '')
    ensure(email and isinstance(password, str), 'Correo y contraseña requeridos.')
    user = next(db().collection('users').where(filter=FieldFilter('email', '==', email)).limit(1).stream(), None)
    generic = 'Correo o contraseña incorrectos.'
    if user is None or not (user.to_dict() or {}).get('isActive', True):
        raise ApiError(generic, 401)
    cred = db().collection('credentials').document(user.id).get()
    if not cred.exists or not check_password(password, (cred.to_dict() or {}).get('passwordHash', '!')):
        raise ApiError(generic, 401)
    role = (user.to_dict() or {}).get('role', 'emisor')
    ensure(role in ('emisor', 'contador', 'administrador'), 'Rol inválido.', 403)
    return JsonResponse({'token': new_session(user.id), 'user': {
        'id': user.id, 'fullName': user.get('fullName'),
        'email': user.get('email'), 'role': role}})


@methods('GET')
@require_auth
def me(request):
    return JsonResponse(request.cloud_user)


@methods('POST')
@require_auth
def logout(request):
    request.cloud_session.reference.update({'revokedAt': now()})
    return JsonResponse({'message': 'Sesión cerrada.'})


@methods('GET', 'POST')
@require_auth
def invoices(request):
    actor = request.cloud_user
    if request.method == 'GET':
        query = db().collection('invoices')
        if actor['role'] == 'emisor':
            query = query.where(filter=FieldFilter('createdById', '==', actor['id']))
        results = [invoice_to_json(doc) for doc in query.limit(100).stream()]
        results.sort(key=lambda x: x['updatedAt'], reverse=True)
        return JsonResponse(results, safe=False)
    ensure(actor['role'] in ('emisor', 'administrador'), 'Tu rol no permite crear facturas.', 403)
    data, items = validate_draft(payload(request))
    invoice_id = data['supplierId'] + '_' + data['number']
    parent = db().collection('invoices').document(invoice_id)
    supplier = db().collection('suppliers').document(data['supplierId'])
    if not supplier.get().exists:
        try:
            supplier.create({'taxId': data['supplierId'], 'name': data['supplierName'], 'createdAt': now()})
        except AlreadyExists:
            pass
    stamp = now()
    record = {**data, **monetary(items), 'status': 'borrador',
              'createdById': actor['id'], 'createdByName': actor['fullName'],
              'createdAt': stamp, 'updatedAt': stamp, 'rejectionReason': None}
    batch = db().batch()
    batch.create(parent, record)
    for idx, item in enumerate(items, 1):
        batch.set(parent.collection('items').document(f'line-{idx}'), item)
    add_event(batch, parent, actor, 'borrador', 'Factura creada')
    batch.commit()
    return JsonResponse(invoice_to_json(parent.get()), status=201)


@methods('GET', 'PATCH', 'DELETE')
@require_auth
def invoice_detail(request, invoice_id):
    doc = invoice_doc(invoice_id)
    actor = request.cloud_user
    ensure(accessible(doc, actor), 'Acceso denegado.', 403)
    if request.method == 'GET':
        return JsonResponse(invoice_to_json(doc))
    ensure(editable(doc, actor), 'La factura no puede modificarse con tu rol y estado.', 403)
    if request.method == 'DELETE':
        ensure(doc.get('status') == 'borrador', 'Solo se eliminan borradores.', 400)
        batch = db().batch()
        for sub in ('items', 'events'):
            for child in doc.reference.collection(sub).stream():
                batch.delete(child.reference)
        batch.delete(doc.reference, option=LastUpdateOption(doc.update_time))
        batch.commit()
        return JsonResponse({}, status=200)
    data, items = validate_draft(payload(request))
    ensure(data['number'] == doc.get('number') and data['supplierId'] == doc.get('supplierId'),
           'Para modificar NIT o consecutivo crea una nueva factura.', 400)
    existing = list(doc.reference.collection('items').stream())
    desired = {f'line-{n}' for n in range(1, len(items)+1)}
    batch = db().batch()
    for child in existing:
        if child.id not in desired:
            batch.delete(child.reference)
    for idx, item in enumerate(items, 1):
        batch.set(doc.reference.collection('items').document(f'line-{idx}'), item)
    batch.update(doc.reference, {**data, **monetary(items), 'updatedAt': now()},
                 option=LastUpdateOption(doc.update_time))
    batch.commit()
    return JsonResponse(invoice_to_json(doc.reference.get()))


@methods('POST')
@require_auth
def invoice_transition(request, invoice_id, action):
    actor = request.cloud_user
    doc = invoice_doc(invoice_id)
    ensure(accessible(doc, actor), 'Acceso denegado.', 403)
    old = doc.get('status')
    text = {'submit': 'Enviada a revisión', 'approve': f'Aprobada por {actor["fullName"]}',
            'reject': f'Rechazada por {actor["fullName"]}',
            'reopen': 'Reabierta para corrección'}
    ensure(action in text, 'Acción desconocida.', 404)
    body = payload(request) if request.body else {}
    comment = body.get('comment') if action == 'approve' else None
    reason = str(body.get('reason', '')).strip() if action == 'reject' else None
    if action == 'submit':
        ensure(editable(doc, actor), 'No puedes enviar esta factura.', 403)
        ensure(any(doc.reference.collection('items').limit(1).stream()), 'Agrega al menos un ítem.')
        target = 'enviada'
    elif action in ('approve', 'reject'):
        ensure(actor['role'] in ('contador', 'administrador') and old == 'enviada',
               'Solo un revisor puede procesar facturas enviadas.', 403)
        ensure(doc.get('createdById') != actor['id'], 'No puedes revisar tu propia factura.', 403)
        if action == 'reject':
            ensure(len(reason) >= 10, 'El rechazo requiere al menos 10 caracteres.')
        target = 'aprobada' if action == 'approve' else 'rechazada'
    else:
        ensure(old == 'rechazada' and editable(doc, actor), 'No puedes reabrir esta factura.', 403)
        target = 'borrador'
    batch = db().batch()
    batch.update(doc.reference, {'status': target, 'rejectionReason': reason,
                                 'updatedAt': now()}, option=LastUpdateOption(doc.update_time))
    add_event(batch, doc.reference, actor, target, text[action], reason if action == 'reject' else comment)
    batch.commit()
    return JsonResponse(invoice_to_json(doc.reference.get()))
