
WITH source_rows AS (
    SELECT
        raw.id AS raw_id,
        src.id AS legacy_source_id,
        raw.legacy_source_code,
        raw.legacy_table,
        raw.legacy_pk,
        raw.record_data,
        COALESCE(
            raw.record_data ->> 'vus_ec_numsol',
            raw.record_data ->> 'vus_ef_numsol',
            raw.record_data ->> 'vus_lc_numsol',
            raw.record_data ->> 'vus_mm_numsol',
            raw.record_data ->> 'vus_pa_numsol',
            raw.record_data ->> 'vus_pb_numsol',
            raw.record_data ->> 'vus_pc_numsol',
            raw.record_data ->> 'vus_pn_numsol',
            raw.record_data ->> 'vus_qc_numsol',
            raw.record_data ->> 'vus_fv_numsol',
            raw.record_data ->> 'vus_al_numsol',
            raw.record_data ->> 'vus_in_numsol',
            raw.record_data ->> 'adm_con_numsol',
            raw.record_data ->> 'lab_con_numsol'
        ) AS request_number,
        substring(raw.legacy_table from '_(ec|ef|lc|mm|pa|pb|pc|pn|qc|fv|al|in)') AS service_code
    FROM staging.legacy_raw_record raw
    JOIN oms.legacy_source src ON src.code = raw.legacy_source_code
    WHERE raw.legacy_table ~ '^(vus_tramites|adm_control|lab_control)_(ec|ef|lc|mm|pa|pb|pc|pn|qc|fv|al|in)([0-9])?$'
),
inserted AS (
    INSERT INTO oms.case_request (
        legacy_source_id,
        service_line_id,
        request_number,
        procedure_code,
        status_code,
        lifecycle_state,
        legacy_table,
        legacy_pk,
        core_payload,
        form_payload
    )
    SELECT
        source_rows.legacy_source_id,
        service_line.id,
        source_rows.request_number,
        source_rows.service_code,
        COALESCE(source_rows.record_data ->> 'status', source_rows.record_data ->> 'adm_con_rf_status'),
        CASE
            WHEN source_rows.legacy_table ~ '[1235]$' THEN 'archived'
            ELSE 'active'
        END,
        source_rows.legacy_table,
        source_rows.legacy_pk,
        jsonb_build_object(
            'legacy_source', source_rows.legacy_source_code,
            'legacy_table', source_rows.legacy_table,
            'service_code', source_rows.service_code
        ),
        jsonb_build_object(
            'schema_version', source_rows.service_code || '.legacy.v1',
            'source_table', source_rows.legacy_table,
            'raw', source_rows.record_data
        )
    FROM source_rows
    LEFT JOIN oms.service_line service_line
        ON service_line.code = source_rows.service_code
    WHERE source_rows.request_number IS NOT NULL
    ON CONFLICT DO NOTHING
    RETURNING id, legacy_source_id, legacy_table, legacy_pk
)
INSERT INTO legacy.record_mapping (
    legacy_source_id,
    legacy_table,
    legacy_pk,
    target_schema,
    target_table,
    target_id,
    validation_status
)
SELECT
    legacy_source_id,
    legacy_table,
    legacy_pk,
    'oms',
    'case_request',
    id::text,
    'pending'
FROM inserted
ON CONFLICT DO NOTHING;
