-- =====================================================================
-- Generador del diccionario de datos
-- Lee el catálogo real de PostgreSQL (information_schema / pg_catalog) y
-- emite el diccionario en Markdown. Al extraerse de la base implementada,
-- queda garantizada la coherencia entre documento y esquema (Criterio 4).
-- =====================================================================
\pset format unaligned
\pset tuples_only on
\pset footer off

SELECT '## Tabla `' || c.relname || '`' || E'\n\n' ||
       COALESCE(obj_description(c.oid, 'pg_class'), '') || E'\n\n' ||
       '| # | Campo | Tipo | Long./Prec. | PK | FK | Nulo | Predeterminado | Restricciones | Descripción |' || E'\n' ||
       '|---|-------|------|-------------|----|----|------|----------------|---------------|-------------|' || E'\n' ||
       string_agg(
           '| ' || a.attnum || ' | `' || a.attname || '` | ' ||
           format_type(a.atttypid, NULL) || ' | ' ||
           COALESCE(
               CASE
                   WHEN t.typname IN ('varchar','bpchar') AND a.atttypmod > 0
                       THEN (a.atttypmod - 4)::text
                   WHEN t.typname = 'numeric' AND a.atttypmod > 0
                       THEN ((a.atttypmod - 4) >> 16)::text || ',' || ((a.atttypmod - 4) & 65535)::text
                   WHEN t.typname = 'int2' THEN '16 bits'
                   WHEN t.typname = 'int4' THEN '32 bits'
                   WHEN t.typname = 'int8' THEN '64 bits'
                   WHEN t.typname = 'uuid' THEN '128 bits'
                   ELSE '—'
               END, '—') || ' | ' ||
           CASE WHEN pk.attname IS NOT NULL THEN 'Sí' ELSE '' END || ' | ' ||
           COALESCE(fk.ref, '') || ' | ' ||
           CASE WHEN a.attnotnull THEN 'No' ELSE 'Sí' END || ' | ' ||
           COALESCE('`' || pg_get_expr(ad.adbin, ad.adrelid) || '`', '—') || ' | ' ||
           COALESCE(ck.list, '—') || ' | ' ||
           COALESCE(col_description(c.oid, a.attnum), '—') || ' |',
           E'\n' ORDER BY a.attnum)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
JOIN pg_type t ON t.oid = a.atttypid
LEFT JOIN pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum
LEFT JOIN LATERAL (
    SELECT a2.attname
    FROM pg_constraint pc
    JOIN pg_attribute a2 ON a2.attrelid = pc.conrelid AND a2.attnum = ANY (pc.conkey)
    WHERE pc.conrelid = c.oid AND pc.contype = 'p' AND a2.attnum = a.attnum
) pk ON TRUE
LEFT JOIN LATERAL (
    SELECT '`' || cf.relname || '.' ||
           (SELECT a3.attname FROM pg_attribute a3
             WHERE a3.attrelid = pc.confrelid AND a3.attnum = pc.confkey[1]) || '`' AS ref
    FROM pg_constraint pc
    JOIN pg_class cf ON cf.oid = pc.confrelid
    WHERE pc.conrelid = c.oid AND pc.contype = 'f' AND a.attnum = ANY (pc.conkey)
    LIMIT 1
) fk ON TRUE
LEFT JOIN LATERAL (
    SELECT string_agg(replace(pg_get_constraintdef(pc.oid), '|', '\|'), '; ') AS list
    FROM pg_constraint pc
    WHERE pc.conrelid = c.oid
      AND pc.contype IN ('c','u')
      AND a.attnum = ANY (pc.conkey)
) ck ON TRUE
WHERE n.nspname = 'facturaflow' AND c.relkind = 'r'
GROUP BY c.oid, c.relname
ORDER BY c.relname;
