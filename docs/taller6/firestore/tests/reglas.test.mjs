// Pruebas de las reglas de seguridad de Cloud Firestore.
//
// Se ejecutan contra el emulador local, nunca contra la base real:
//   npm test
//
// Cada prueba comprueba una regla concreta. Las que deben rechazarse usan
// assertFails, de modo que fallarían si la regla no existiera.

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  query,
  where,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const NIT = '900123456-8';
const BORRADOR_ANA = `${NIT}_FE-1001`;
const ENVIADA_ANA = `${NIT}_FE-1002`;
const RECHAZADA_ANA = `${NIT}_FE-1003`;
const ENVIADA_LUCIA = `${NIT}_FE-2001`;
const BORRADOR_OTRO = `${NIT}_FE-3001`;

let env;

const como = (uid) => env.authenticatedContext(uid).firestore();
const anonimo = () => env.unauthenticatedContext().firestore();

function factura(numero, autor, status, extra = {}) {
  return {
    number: numero,
    supplierId: NIT,
    supplierName: 'Papelería La 45',
    createdById: autor,
    createdByName: autor,
    issueDate: '2026-10-01',
    status,
    notes: '',
    rejectionReason: null,
    subtotalCents: 100000,
    taxCents: 19000,
    totalCents: 119000,
    updatedAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
    ...extra,
  };
}

describe('Reglas de seguridad de Cloud Firestore', () => {

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-facturaflow',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await env.cleanup();
});

// Estado inicial de cada prueba, sembrado sin reglas (como el Admin SDK).
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/ana'), { fullName: 'Ana Torres', email: 'ana@x.co', role: 'emisor' });
    await setDoc(doc(db, 'users/otro'), { fullName: 'Otro Emisor', email: 'otro@x.co', role: 'emisor' });
    await setDoc(doc(db, 'users/carlos'), { fullName: 'Carlos Ruiz', email: 'carlos@x.co', role: 'contador' });
    await setDoc(doc(db, 'users/lucia'), { fullName: 'Lucía Peña', email: 'lucia@x.co', role: 'administrador' });
    await setDoc(doc(db, `suppliers/${NIT}`), { taxId: NIT, name: 'Papelería La 45' });

    await setDoc(doc(db, `invoices/${BORRADOR_ANA}`), factura('FE-1001', 'ana', 'borrador'));
    await setDoc(doc(db, `invoices/${ENVIADA_ANA}`), factura('FE-1002', 'ana', 'enviada'));
    await setDoc(
      doc(db, `invoices/${RECHAZADA_ANA}`),
      factura('FE-1003', 'ana', 'rechazada', { rejectionReason: 'Falta la orden de compra' }),
    );
    await setDoc(doc(db, `invoices/${ENVIADA_LUCIA}`), factura('FE-2001', 'lucia', 'enviada'));
    await setDoc(doc(db, `invoices/${BORRADOR_OTRO}`), factura('FE-3001', 'otro', 'borrador'));

    await setDoc(doc(db, `invoices/${BORRADOR_ANA}/items/line-1`), {
      lineNumber: 1, description: 'Resma', quantity: 2, unitPriceCents: 50000, taxRate: 0.19,
    });
    await setDoc(doc(db, `invoices/${BORRADOR_ANA}/events/ev-001`), {
      actorId: 'ana', actorName: 'Ana Torres', status: 'borrador',
      description: 'Factura creada', comment: null,
      occurredAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
    });
  });
});

// ---------------------------------------------------------------------
describe('Lectura y aislamiento entre usuarios', () => {
  test('sin autenticación no se lee nada', async () => {
    await assertFails(getDoc(doc(anonimo(), `invoices/${BORRADOR_ANA}`)));
  });

  test('el emisor lee su propia factura', async () => {
    await assertSucceeds(getDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}`)));
  });

  test('un emisor no lee la factura de otro emisor', async () => {
    await assertFails(getDoc(doc(como('otro'), `invoices/${BORRADOR_ANA}`)));
  });

  test('hallazgo de revisión #2: tampoco lee sus ítems', async () => {
    await assertFails(getDoc(doc(como('otro'), `invoices/${BORRADOR_ANA}/items/line-1`)));
  });

  test('hallazgo de revisión #2: tampoco lee su historial', async () => {
    await assertFails(getDoc(doc(como('otro'), `invoices/${BORRADOR_ANA}/events/ev-001`)));
  });

  test('el contador sí lee los ítems de cualquier factura', async () => {
    await assertSucceeds(getDoc(doc(como('carlos'), `invoices/${BORRADOR_ANA}/items/line-1`)));
  });

  test('el emisor lista solo las suyas filtrando por autor', async () => {
    const q = query(collection(como('ana'), 'invoices'), where('createdById', '==', 'ana'));
    await assertSucceeds(getDocs(q));
  });

  test('el emisor no puede listar todas sin filtro', async () => {
    await assertFails(getDocs(collection(como('ana'), 'invoices')));
  });
});

// ---------------------------------------------------------------------
describe('Issue #41 — número único por proveedor', () => {
  test('crear con id {NIT}_{número} coherente se acepta', async () => {
    const db = como('ana');
    await assertSucceeds(
      setDoc(doc(db, `invoices/${NIT}_FE-1100`), {
        ...factura('FE-1100', 'ana', 'borrador'), updatedAt: serverTimestamp(),
      }),
    );
  });

  test('un id que no corresponde al NIT y número se rechaza', async () => {
    const db = como('ana');
    await assertFails(
      setDoc(doc(db, `invoices/cualquier-id`), {
        ...factura('FE-1100', 'ana', 'borrador'), updatedAt: serverTimestamp(),
      }),
    );
  });

  test('otro emisor no puede sobrescribir una factura con el mismo número y NIT', async () => {
    const db = como('otro');
    await assertFails(
      setDoc(doc(db, `invoices/${BORRADOR_ANA}`), {
        ...factura('FE-1001', 'otro', 'borrador'), updatedAt: serverTimestamp(),
      }),
    );
  });
});

// ---------------------------------------------------------------------
describe('Issue #40 — motivo de rechazo de al menos 10 caracteres', () => {
  test('rechazar con un motivo de un carácter se rechaza', async () => {
    await assertFails(
      updateDoc(doc(como('carlos'), `invoices/${ENVIADA_ANA}`), {
        status: 'rechazada', rejectionReason: '.', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('rechazar con una justificación real se acepta', async () => {
    await assertSucceeds(
      updateDoc(doc(como('carlos'), `invoices/${ENVIADA_ANA}`), {
        status: 'rechazada',
        rejectionReason: 'Falta la orden de compra firmada',
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

// ---------------------------------------------------------------------
describe('Issue #42 — el motivo solo existe en facturas rechazadas', () => {
  test('reabrir conservando el motivo se rechaza', async () => {
    await assertFails(
      updateDoc(doc(como('ana'), `invoices/${RECHAZADA_ANA}`), {
        status: 'borrador', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('reabrir limpiando el motivo se acepta', async () => {
    await assertSucceeds(
      updateDoc(doc(como('ana'), `invoices/${RECHAZADA_ANA}`), {
        status: 'borrador', rejectionReason: null, updatedAt: serverTimestamp(),
      }),
    );
  });
});

// ---------------------------------------------------------------------
describe('Flujo de estados y separación de funciones', () => {
  test('un emisor no puede aprobar su propio borrador', async () => {
    await assertFails(
      updateDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}`), {
        status: 'aprobada', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('un emisor no puede aprobar su factura enviada', async () => {
    await assertFails(
      updateDoc(doc(como('ana'), `invoices/${ENVIADA_ANA}`), {
        status: 'aprobada', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('un administrador no revisa su propia factura', async () => {
    await assertFails(
      updateDoc(doc(como('lucia'), `invoices/${ENVIADA_LUCIA}`), {
        status: 'aprobada', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('el contador aprueba una factura ajena enviada', async () => {
    await assertSucceeds(
      updateDoc(doc(como('carlos'), `invoices/${ENVIADA_ANA}`), {
        status: 'aprobada', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('el contador no puede cambiar el contenido al revisar', async () => {
    await assertFails(
      updateDoc(doc(como('carlos'), `invoices/${ENVIADA_ANA}`), {
        status: 'aprobada', notes: 'modificada', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('el emisor envía su borrador a revisión', async () => {
    await assertSucceeds(
      updateDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}`), {
        status: 'enviada', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('no se puede cambiar el número ni el proveedor de una factura', async () => {
    await assertFails(
      updateDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}`), {
        number: 'FE-9999', updatedAt: serverTimestamp(),
      }),
    );
  });

  test('la marca de tiempo debe ser la del servidor', async () => {
    await assertFails(
      updateDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}`), {
        notes: 'edición', updatedAt: Timestamp.fromDate(new Date('2020-01-01')),
      }),
    );
  });
});

// ---------------------------------------------------------------------
describe('Bitácora de auditoría (events)', () => {
  test('crear factura, ítem y evento en un mismo lote se acepta', async () => {
    const db = como('ana');
    const id = `${NIT}_FE-1200`;
    const batch = writeBatch(db);
    batch.set(doc(db, `invoices/${id}`), { ...factura('FE-1200', 'ana', 'borrador'), updatedAt: serverTimestamp() });
    batch.set(doc(db, `invoices/${id}/items/line-1`), {
      lineNumber: 1, description: 'Servicio', quantity: 1, unitPriceCents: 100000, taxRate: 0.19,
    });
    batch.set(doc(db, `invoices/${id}/events/ev-001`), {
      actorId: 'ana', actorName: 'Ana Torres', status: 'borrador',
      description: 'Factura creada', comment: null, occurredAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
  });

  test('un emisor no puede escribir eventos en la factura de otro', async () => {
    await assertFails(
      setDoc(doc(como('otro'), `invoices/${BORRADOR_ANA}/events/ev-falso`), {
        actorId: 'otro', actorName: 'Otro', status: 'borrador',
        description: 'Evento falso', comment: null, occurredAt: serverTimestamp(),
      }),
    );
  });

  test('no se puede firmar un evento a nombre de otro usuario', async () => {
    await assertFails(
      setDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}/events/ev-002`), {
        actorId: 'carlos', actorName: 'Carlos Ruiz', status: 'borrador',
        description: 'Suplantación', comment: null, occurredAt: serverTimestamp(),
      }),
    );
  });

  test('no se puede registrar un estado distinto al de la factura', async () => {
    await assertFails(
      setDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}/events/ev-002`), {
        actorId: 'ana', actorName: 'Ana Torres', status: 'aprobada',
        description: 'Aprobación inventada', comment: null, occurredAt: serverTimestamp(),
      }),
    );
  });

  test('no se puede fechar un evento en el pasado', async () => {
    await assertFails(
      setDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}/events/ev-002`), {
        actorId: 'ana', actorName: 'Ana Torres', status: 'borrador',
        description: 'Retroactivo', comment: null,
        occurredAt: Timestamp.fromDate(new Date('2020-01-01')),
      }),
    );
  });

  test('un evento no se puede modificar', async () => {
    await assertFails(
      updateDoc(doc(como('ana'), `invoices/${BORRADOR_ANA}/events/ev-001`), {
        description: 'Reescrito',
      }),
    );
  });

  test('aprobar y registrar el evento en un mismo lote se acepta', async () => {
    const db = como('carlos');
    const batch = writeBatch(db);
    batch.update(doc(db, `invoices/${ENVIADA_ANA}`), { status: 'aprobada', updatedAt: serverTimestamp() });
    batch.set(doc(db, `invoices/${ENVIADA_ANA}/events/ev-003`), {
      actorId: 'carlos', actorName: 'Carlos Ruiz', status: 'aprobada',
      description: 'Aprobada por Carlos Ruiz', comment: null, occurredAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
  });
});

// ---------------------------------------------------------------------
describe('Borrado (equivale a ON DELETE CASCADE / RESTRICT)', () => {
  test('el dueño elimina su borrador con ítems e historial', async () => {
    const db = como('ana');
    const batch = writeBatch(db);
    batch.delete(doc(db, `invoices/${BORRADOR_ANA}/items/line-1`));
    batch.delete(doc(db, `invoices/${BORRADOR_ANA}/events/ev-001`));
    batch.delete(doc(db, `invoices/${BORRADOR_ANA}`));
    await assertSucceeds(batch.commit());
  });

  test('no se elimina una factura enviada', async () => {
    await assertFails(deleteDoc(doc(como('ana'), `invoices/${ENVIADA_ANA}`)));
  });

  test('un emisor no elimina el borrador de otro', async () => {
    await assertFails(deleteDoc(doc(como('otro'), `invoices/${BORRADOR_ANA}`)));
  });

  test('no se elimina un proveedor (RESTRICT)', async () => {
    await assertFails(deleteDoc(doc(como('lucia'), `suppliers/${NIT}`)));
  });
});

// ---------------------------------------------------------------------
describe('Perfiles y proveedores', () => {
  test('un usuario no puede cambiarse el rol', async () => {
    await assertFails(updateDoc(doc(como('ana'), 'users/ana'), { role: 'administrador' }));
  });

  test('un usuario sí puede corregir su nombre', async () => {
    await assertSucceeds(updateDoc(doc(como('ana'), 'users/ana'), { fullName: 'Ana M. Torres' }));
  });

  test('un cliente no puede crear perfiles', async () => {
    await assertFails(
      setDoc(doc(como('ana'), 'users/intruso'), { fullName: 'X', email: 'x@x.co', role: 'administrador' }),
    );
  });

  test('un proveedor con NIT mal formado se rechaza', async () => {
    await assertFails(
      setDoc(doc(como('ana'), 'suppliers/ABC-123'), { taxId: 'ABC-123', name: 'Mal formado' }),
    );
  });
});
});
