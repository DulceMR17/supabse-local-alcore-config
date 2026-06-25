
DO $$
DECLARE
    table_record record;
BEGIN
    FOR table_record IN
        SELECT schemaname, tablename
        FROM pg_tables
        WHERE schemaname IN ('oms', 'ref', 'legacy', 'staging')
    LOOP
        EXECUTE format(
            'ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY',
            table_record.schemaname,
            table_record.tablename
        );
    END LOOP;
END $$;

REVOKE ALL ON SCHEMA legacy FROM anon, authenticated;
REVOKE ALL ON SCHEMA staging FROM anon, authenticated;
REVOKE ALL ON ALL TABLES IN SCHEMA legacy FROM anon, authenticated;
REVOKE ALL ON ALL TABLES IN SCHEMA staging FROM anon, authenticated;

GRANT USAGE ON SCHEMA ref TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA ref TO authenticated;

DROP POLICY IF EXISTS "authenticated_read_catalog_type" ON ref.catalog_type;
CREATE POLICY "authenticated_read_catalog_type"
ON ref.catalog_type
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "authenticated_read_catalog_item" ON ref.catalog_item;
CREATE POLICY "authenticated_read_catalog_item"
ON ref.catalog_item
FOR SELECT
TO authenticated
USING (active = true);

COMMENT ON SCHEMA oms IS
'OMS normalized schema. RLS is enabled; application-specific policies must be added before exposing transactional tables to clients.';

COMMENT ON SCHEMA legacy IS
'Internal migration traceability schema. Do not expose directly to frontend clients.';

COMMENT ON SCHEMA staging IS
'Internal raw legacy loading schema. Do not expose directly to frontend clients.';
