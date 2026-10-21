-- =====================================================================
-- FacturaFlow Mobile Cloud — Batería de pruebas del modelo de datos
-- Actividad Evaluable 06
--
-- Cada prueba imprime PASA o falla la transacción. Las pruebas que deben
-- fallar se envuelven en un bloque que captura la excepción esperada.
-- =====================================================================

SET search_path TO facturaflow, public;

\echo '================ PRUEBA 2: existencia de tablas ================'
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'facturaflow' AND table_type = 'BASE TABLE'
ORDER BY table_name;

\echo '================ PRUEBA 3: llaves primarias ===================='
SELECT tc.table_name, kcu.column_name, tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name = tc.constraint_name
 AND kcu.table_schema = tc.table_schema
WHERE tc.table_schema = 'facturaflow' AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY tc.table_name;

\echo '================ PRUEBA 4: llaves foraneas ====================='
SELECT
    tc.table_name            AS tabla_origen,
    kcu.column_name          AS columna,
    ccu.table_name           AS tabla_destino,
    ccu.column_name          AS columna_destino,
    rc.delete_rule           AS al_borrar
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name = tc.constraint_name AND kcu.table_schema = tc.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints rc
  ON rc.constraint_name = tc.constraint_name AND rc.constraint_schema = tc.table_schema
WHERE tc.table_schema = 'facturaflow' AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, kcu.column_name;

\echo '================ PRUEBA 6: insercion de datos =================='
INSERT INTO app_user (id, full_name, email, password_hash, role) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Ana Torres',  'ana@facturaflow.demo',    'hash-demo', 'emisor'),
  ('22222222-2222-2222-2222-222222222222', 'Carlos Ruiz', 'carlos@facturaflow.demo', 'hash-demo', 'contador');

INSERT INTO supplier (id, tax_id, name) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', '900123456-7', 'Papeleria La 45'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '901555222-1', 'Transportes Andinos S.A.S.');

INSERT INTO invoice (id, number, supplier_id, issue_date, status, created_by_id, notes) VALUES
  ('bbbbbbbb-0000-0000-0000-000000000001', 'FE-1001',
   'aaaaaaaa-0000-0000-0000-000000000001', DATE '2026-10-01', 'borrador',
   '11111111-1111-1111-1111-111111111111', 'Pendiente de adjuntar la orden de compra.');

INSERT INTO invoice_item (invoice_id, line_number, description, quantity, unit_price_cents, tax_rate) VALUES
  ('bbbbbbbb-0000-0000-0000-000000000001', 1, 'Resma de papel carta',   12, 1850000,  0.1900),
  ('bbbbbbbb-0000-0000-0000-000000000001', 2, 'Toner impresora laser',   2, 24500000, 0.1900);

INSERT INTO invoice_event (invoice_id, actor_id, status, description) VALUES
  ('bbbbbbbb-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   'borrador', 'Factura creada');

SELECT 'PASA — 2 usuarios, 2 proveedores, 1 factura, 2 items, 1 evento' AS prueba_6;

\echo '================ PRUEBA 7: consulta con JOIN y totales ========='
SELECT
    i.number,
    s.name                AS proveedor,
    s.tax_id              AS nit,
    u.full_name           AS creada_por,
    i.status,
    t.subtotal_cents,
    t.tax_cents,
    t.total_cents
FROM invoice i
JOIN supplier s        ON s.id = i.supplier_id
JOIN app_user u        ON u.id = i.created_by_id
JOIN invoice_totals t  ON t.invoice_id = i.id;

\echo '================ PRUEBA 10a: FK invalida debe fallar ==========='
DO $$
BEGIN
    INSERT INTO invoice (number, supplier_id, issue_date, created_by_id)
    VALUES ('FE-X', '00000000-0000-0000-0000-000000000000', CURRENT_DATE,
            '11111111-1111-1111-1111-111111111111');
    RAISE EXCEPTION 'FALLA — se acepto un supplier_id inexistente';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'PASA — integridad referencial: rechaza supplier_id inexistente';
END $$;

\echo '================ PRUEBA 14a: Issue #41 numero+NIT =============='
DO $$
BEGIN
    -- Mismo numero, OTRO proveedor: debe permitirse.
    INSERT INTO invoice (number, supplier_id, issue_date, created_by_id)
    VALUES ('FE-1001', 'aaaaaaaa-0000-0000-0000-000000000002', CURRENT_DATE,
            '11111111-1111-1111-1111-111111111111');
    RAISE NOTICE 'PASA — dos proveedores distintos pueden usar FE-1001';
END $$;

DO $$
BEGIN
    -- Mismo numero y MISMO proveedor: debe rechazarse.
    INSERT INTO invoice (number, supplier_id, issue_date, created_by_id)
    VALUES ('FE-1001', 'aaaaaaaa-0000-0000-0000-000000000001', CURRENT_DATE,
            '11111111-1111-1111-1111-111111111111');
    RAISE EXCEPTION 'FALLA — se acepto numero duplicado para el mismo proveedor';
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'PASA — rechaza FE-1001 repetida en el mismo proveedor';
END $$;

\echo '================ PRUEBA 14b: Issue #40 motivo >= 10 ============'
DO $$
BEGIN
    UPDATE invoice
       SET status = 'rechazada', rejection_reason = '.'
     WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'FALLA — se acepto un motivo de un solo caracter';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASA — rechaza un motivo de rechazo demasiado corto';
END $$;

\echo '================ PRUEBA 8: actualizacion (rechazo valido) ======'
UPDATE invoice
   SET status = 'rechazada', rejection_reason = 'Falta la orden de compra firmada'
 WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001';

INSERT INTO invoice_event (invoice_id, actor_id, status, description, comment)
VALUES ('bbbbbbbb-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222',
        'rechazada', 'Rechazada por Carlos Ruiz', 'Falta la orden de compra firmada');

SELECT number, status, rejection_reason FROM invoice
WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001';

\echo '================ PRUEBA 14c: Issue #42 reabrir limpia motivo ==='
DO $$
BEGIN
    -- Volver a borrador conservando el motivo debe ser imposible.
    UPDATE invoice SET status = 'borrador'
     WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'FALLA — un borrador conservo el motivo del rechazo';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASA — no permite un borrador con motivo de rechazo';
END $$;

-- La reapertura correcta limpia el motivo en la misma sentencia.
UPDATE invoice
   SET status = 'borrador', rejection_reason = NULL
 WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001';

SELECT 'PASA — reabierta: ' || status || ', motivo=' ||
       COALESCE(rejection_reason, 'NULL') AS prueba_14c
FROM invoice WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001';

\echo '================ PRUEBA 10b: historial sobrevive (Issue #42) ==='
SELECT occurred_at, status, description, comment
FROM invoice_event
WHERE invoice_id = 'bbbbbbbb-0000-0000-0000-000000000001'
ORDER BY occurred_at;

\echo '================ PRUEBA 14d: validaciones de item =============='
DO $$
BEGIN
    INSERT INTO invoice_item (invoice_id, line_number, description, quantity, unit_price_cents)
    VALUES ('bbbbbbbb-0000-0000-0000-000000000001', 9, 'Cantidad invalida', 0, 1000);
    RAISE EXCEPTION 'FALLA — se acepto quantity = 0';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASA — rechaza quantity <= 0';
END $$;

\echo '================ PRUEBA 14e: email unico ======================='
DO $$
BEGIN
    INSERT INTO app_user (full_name, email, password_hash, role)
    VALUES ('Duplicada', 'ana@facturaflow.demo', 'hash', 'emisor');
    RAISE EXCEPTION 'FALLA — se acepto un correo duplicado';
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'PASA — rechaza correo duplicado';
END $$;

\echo '================ PRUEBA 9: borrado en cascada =================='
SELECT count(*) AS items_antes FROM invoice_item
WHERE invoice_id = 'bbbbbbbb-0000-0000-0000-000000000001';

DELETE FROM invoice WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001';

SELECT count(*) AS items_despues FROM invoice_item
WHERE invoice_id = 'bbbbbbbb-0000-0000-0000-000000000001';

\echo '================ PRUEBA 10c: RESTRICT protege catalogos ========'
DO $$
BEGIN
    DELETE FROM supplier WHERE id = 'aaaaaaaa-0000-0000-0000-000000000002';
    RAISE EXCEPTION 'FALLA — se borro un proveedor con facturas';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'PASA — RESTRICT impide borrar un proveedor con facturas';
END $$;

\echo '================ RESUMEN ======================================='
SELECT
    (SELECT count(*) FROM app_user)      AS usuarios,
    (SELECT count(*) FROM supplier)      AS proveedores,
    (SELECT count(*) FROM invoice)       AS facturas,
    (SELECT count(*) FROM invoice_item)  AS items,
    (SELECT count(*) FROM invoice_event) AS eventos;
