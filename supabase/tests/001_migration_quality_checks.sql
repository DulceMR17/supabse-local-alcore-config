
SELECT
    'raw_records_by_source' AS check_name,
    legacy_source_code,
    count(*) AS records
FROM staging.legacy_raw_record
GROUP BY legacy_source_code
ORDER BY legacy_source_code;

SELECT
    'case_requests_by_source' AS check_name,
    src.code AS legacy_source,
    count(*) AS records
FROM oms.case_request req
JOIN oms.legacy_source src ON src.id = req.legacy_source_id
GROUP BY src.code
ORDER BY src.code;

SELECT
    'case_requests_missing_request_number' AS check_name,
    count(*) AS records
FROM oms.case_request
WHERE request_number IS NULL OR request_number = '';

SELECT
    'record_mapping_by_target' AS check_name,
    target_schema,
    target_table,
    validation_status,
    count(*) AS records
FROM legacy.record_mapping
GROUP BY target_schema, target_table, validation_status
ORDER BY target_schema, target_table, validation_status;

SELECT
    'unmapped_raw_records_to_case_request' AS check_name,
    raw.legacy_source_code,
    raw.legacy_table,
    count(*) AS records
FROM staging.legacy_raw_record raw
LEFT JOIN oms.legacy_source src ON src.code = raw.legacy_source_code
LEFT JOIN legacy.record_mapping map
    ON map.legacy_source_id = src.id
   AND map.legacy_table = raw.legacy_table
   AND map.legacy_pk::text = raw.legacy_pk::text
   AND map.target_table = 'case_request'
WHERE raw.legacy_table ~ '^(vus_tramites|adm_control|lab_control)_(ec|ef|lc|mm|pa|pb|pc|pn|qc|fv|al|in)([0-9])?$'
  AND map.id IS NULL
GROUP BY raw.legacy_source_code, raw.legacy_table
ORDER BY records DESC;

SELECT
    'jsonb_payload_empty' AS check_name,
    count(*) AS records
FROM oms.case_request
WHERE form_payload = '{}'::jsonb OR form_payload IS NULL;

SELECT
    'duplicate_case_requests' AS check_name,
    legacy_source_id,
    legacy_table,
    legacy_pk,
    count(*) AS duplicates
FROM oms.case_request
GROUP BY legacy_source_id, legacy_table, legacy_pk
HAVING count(*) > 1;

