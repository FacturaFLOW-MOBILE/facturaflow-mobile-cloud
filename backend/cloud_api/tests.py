"""Pruebas que no acceden a la base real ni escriben datos."""
from django.test import SimpleTestCase
from .views import ApiError, monetary, validate_draft
from .security import token_hash

class DomainTests(SimpleTestCase):
    def test_valid_invoice_draft(self):
        data, items = validate_draft({
            'number': 'fe-3001', 'supplierTaxId': '900123456-7',
            'supplierName': 'Proveedor X', 'issueDate': '2026-10-20',
            'items': [{'description': 'Servicio', 'quantity': 2,
                       'unitPriceCents': 10000, 'taxRate': 0.19}],
        })
        self.assertEqual(data['number'], 'FE-3001')
        self.assertEqual(monetary(items)['totalCents'], 23800)

    def test_invalid_item_rejected(self):
        with self.assertRaises(ApiError):
            validate_draft({'number':'FE-3001','supplierTaxId':'900123456-7',
                'supplierName':'Proveedor','issueDate':'2026-10-20',
                'items':[{'description':'A','quantity':0,'unitPriceCents':100}]})

    def test_session_token_is_hashed(self):
        self.assertEqual(len(token_hash('secret-example')), 64)
        self.assertNotIn('secret-example', token_hash('secret-example'))
