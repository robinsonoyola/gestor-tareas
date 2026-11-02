-- ASE Work: add supporting indexes for every public foreign key.
BEGIN;

DO $indexes$
DECLARE
 relation record;
BEGIN
 FOR relation IN
  SELECT
   source_schema.nspname AS schema_name,
   source.relname AS table_name,
   c.conname AS constraint_name,
   string_agg(quote_ident(attribute.attname),',' ORDER BY key_column.position) AS columns_sql
  FROM pg_constraint c
  JOIN pg_class source ON source.oid=c.conrelid
  JOIN pg_namespace source_schema ON source_schema.oid=source.relnamespace
  CROSS JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS key_column(attribute_number,position)
  JOIN pg_attribute attribute ON attribute.attrelid=c.conrelid AND attribute.attnum=key_column.attribute_number
  WHERE c.contype='f' AND source_schema.nspname='public'
   AND NOT EXISTS(
    SELECT 1
    FROM pg_index i
    WHERE i.indrelid=c.conrelid
     AND i.indisvalid
     AND i.indisready
     AND i.indpred IS NULL
     AND i.indnkeyatts>=cardinality(c.conkey)
     AND NOT EXISTS(
      SELECT 1
      FROM generate_subscripts(c.conkey,1) position
      WHERE i.indkey[position-1]<>c.conkey[position]
     )
   )
  GROUP BY source_schema.nspname,source.relname,c.conname
  ORDER BY source.relname,c.conname
 LOOP
  EXECUTE format(
   'CREATE INDEX %I ON %I.%I (%s)',
   'ase_fk_'||substr(md5(relation.table_name||':'||relation.constraint_name),1,20),
   relation.schema_name,
   relation.table_name,
   relation.columns_sql
  );
 END LOOP;
END $indexes$;

COMMIT;
