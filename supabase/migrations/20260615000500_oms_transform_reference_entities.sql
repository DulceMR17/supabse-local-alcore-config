
INSERT INTO oms.organization (
    tax_id,
    name,
    organization_type,
    attributes,
    legacy_source_id,
    legacy_table,
    legacy_pk
)
SELECT DISTINCT
    COALESCE(record_data ->> 'rif', record_data ->> 'ctg_emp_rif', record_data ->> 'vus_ecEMP_rif') AS tax_id,
    COALESCE(record_data ->> 'nombre', record_data ->> 'ctg_emp_nombre', record_data ->> 'vus_ecEMP_nombre', legacy_table) AS name,
    'legacy',
    jsonb_build_object('raw', record_data),
    src.id,
    raw.legacy_table,
    raw.legacy_pk
FROM staging.legacy_raw_record raw
JOIN oms.legacy_source src ON src.code = raw.legacy_source_code
WHERE raw.legacy_table ~ '(empresas|ctg_empresas)'
  AND COALESCE(record_data ->> 'nombre', record_data ->> 'ctg_emp_nombre', record_data ->> 'vus_ecEMP_nombre', legacy_table) IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO oms.person (
    document_number,
    full_name,
    email,
    phone,
    attributes,
    legacy_source_id,
    legacy_table,
    legacy_pk
)
SELECT DISTINCT
    COALESCE(record_data ->> 'cui', record_data ->> 'cedula', record_data ->> 'ci') AS document_number,
    COALESCE(record_data ->> 'nombre', record_data ->> 'full_name', record_data ->> 'vus_ecper_nombre', legacy_table) AS full_name,
    COALESCE(record_data ->> 'email', record_data ->> 'mail'),
    COALESCE(record_data ->> 'telefono', record_data ->> 'phone'),
    jsonb_build_object('raw', record_data),
    src.id,
    raw.legacy_table,
    raw.legacy_pk
FROM staging.legacy_raw_record raw
JOIN oms.legacy_source src ON src.code = raw.legacy_source_code
WHERE raw.legacy_table ~ '(personas|usuarios|evaluators|tecnicos|inspectores)'
  AND COALESCE(record_data ->> 'nombre', record_data ->> 'full_name', record_data ->> 'vus_ecper_nombre', legacy_table) IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO oms.product (
    registration_code,
    name,
    product_type,
    attributes,
    legacy_source_id,
    legacy_table,
    legacy_pk
)
SELECT DISTINCT
    COALESCE(record_data ->> 'registro', record_data ->> 'reg', record_data ->> 'ctg_pro_registro') AS registration_code,
    COALESCE(record_data ->> 'nombre', record_data ->> 'ctg_pro_nombre', record_data ->> 'producto', legacy_table) AS name,
    substring(raw.legacy_table from '_(ec|ef|lc|mm|pa|pb|pc|pn|qc|fv)'),
    jsonb_build_object('raw', record_data),
    src.id,
    raw.legacy_table,
    raw.legacy_pk
FROM staging.legacy_raw_record raw
JOIN oms.legacy_source src ON src.code = raw.legacy_source_code
WHERE raw.legacy_table ~ '(productos|ctg_productos)'
  AND COALESCE(record_data ->> 'nombre', record_data ->> 'ctg_pro_nombre', record_data ->> 'producto', legacy_table) IS NOT NULL
ON CONFLICT DO NOTHING;

