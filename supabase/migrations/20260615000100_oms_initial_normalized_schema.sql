
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS oms;
CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS legacy;

CREATE TABLE IF NOT EXISTS oms.legacy_source (
    id smallserial PRIMARY KEY,
    code text NOT NULL UNIQUE,
    name text NOT NULL,
    description text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS oms.service_line (
    id bigserial PRIMARY KEY,
    code text NOT NULL,
    name text NOT NULL,
    area text NOT NULL,
    description text,
    active boolean NOT NULL DEFAULT true,
    UNIQUE (code, area)
);

CREATE TABLE IF NOT EXISTS ref.catalog_type (
    id bigserial PRIMARY KEY,
    code text NOT NULL UNIQUE,
    name text NOT NULL,
    description text
);

CREATE TABLE IF NOT EXISTS ref.catalog_item (
    id bigserial PRIMARY KEY,
    catalog_type_id bigint NOT NULL REFERENCES ref.catalog_type(id),
    code text,
    name text NOT NULL,
    description text,
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
    active boolean NOT NULL DEFAULT true,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb,
    UNIQUE (catalog_type_id, code)
);

CREATE TABLE IF NOT EXISTS oms.person (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_type text,
    document_number text,
    full_name text,
    email text,
    phone text,
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_person_document
ON oms.person (document_type, document_number)
WHERE document_type IS NOT NULL AND document_number IS NOT NULL;

CREATE TABLE IF NOT EXISTS oms.organization (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_id text,
    name text NOT NULL,
    organization_type text,
    email text,
    phone text,
    address text,
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_organization_tax_id ON oms.organization (tax_id);
CREATE INDEX IF NOT EXISTS idx_organization_name ON oms.organization (name);

CREATE TABLE IF NOT EXISTS oms.product (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    registration_code text,
    name text NOT NULL,
    product_type text,
    status_code text,
    owner_organization_id uuid REFERENCES oms.organization(id),
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_product_registration_code ON oms.product (registration_code);
CREATE INDEX IF NOT EXISTS idx_product_attributes_gin ON oms.product USING gin (attributes jsonb_path_ops);

CREATE TABLE IF NOT EXISTS oms.user_account (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid REFERENCES oms.person(id),
    username text,
    email text,
    status_code text,
    roles jsonb NOT NULL DEFAULT '[]'::jsonb,
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_user_account_username
ON oms.user_account (username)
WHERE username IS NOT NULL;

CREATE TABLE IF NOT EXISTS oms.case_request (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_source_id smallint NOT NULL REFERENCES oms.legacy_source(id),
    service_line_id bigint REFERENCES oms.service_line(id),
    request_number text NOT NULL,
    procedure_code text,
    status_code text,
    lifecycle_state text NOT NULL DEFAULT 'active',
    current_stage text,
    applicant_person_id uuid REFERENCES oms.person(id),
    applicant_organization_id uuid REFERENCES oms.organization(id),
    assigned_user_id uuid REFERENCES oms.user_account(id),
    submitted_at timestamptz,
    updated_at timestamptz,
    closed_at timestamptz,
    legacy_table text NOT NULL,
    legacy_pk jsonb NOT NULL,
    core_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    form_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_case_request_legacy
ON oms.case_request (legacy_source_id, legacy_table, (legacy_pk::text));

CREATE INDEX IF NOT EXISTS idx_case_request_lookup
ON oms.case_request (request_number, procedure_code, status_code);

CREATE INDEX IF NOT EXISTS idx_case_request_form_payload_gin
ON oms.case_request USING gin (form_payload jsonb_path_ops);

CREATE TABLE IF NOT EXISTS oms.case_administrative_control (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid REFERENCES oms.case_request(id) ON DELETE CASCADE,
    control_number text,
    status_code text,
    evaluator_user_id uuid REFERENCES oms.user_account(id),
    opened_at timestamptz,
    closed_at timestamptz,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_case_administrative_control_case
ON oms.case_administrative_control (case_request_id, status_code);

CREATE INDEX IF NOT EXISTS idx_case_administrative_control_payload_gin
ON oms.case_administrative_control USING gin (payload jsonb_path_ops);

CREATE TABLE IF NOT EXISTS oms.case_party (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid NOT NULL REFERENCES oms.case_request(id) ON DELETE CASCADE,
    role_code text NOT NULL,
    person_id uuid REFERENCES oms.person(id),
    organization_id uuid REFERENCES oms.organization(id),
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (person_id IS NOT NULL OR organization_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_case_party_case_role ON oms.case_party (case_request_id, role_code);

CREATE TABLE IF NOT EXISTS oms.case_product (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid NOT NULL REFERENCES oms.case_request(id) ON DELETE CASCADE,
    product_id uuid REFERENCES oms.product(id),
    role_code text,
    attributes jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS oms.case_event (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid NOT NULL REFERENCES oms.case_request(id) ON DELETE CASCADE,
    event_type text NOT NULL,
    status_code text,
    stage_code text,
    title text,
    description text,
    actor_user_id uuid REFERENCES oms.user_account(id),
    occurred_at timestamptz,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_case_event_case_time ON oms.case_event (case_request_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_case_event_payload_gin ON oms.case_event USING gin (payload jsonb_path_ops);

CREATE TABLE IF NOT EXISTS oms.case_document (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid NOT NULL REFERENCES oms.case_request(id) ON DELETE CASCADE,
    document_type_code text,
    name text,
    status_code text,
    required boolean,
    received_at timestamptz,
    reviewed_at timestamptz,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS oms.case_file (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid NOT NULL REFERENCES oms.case_request(id) ON DELETE CASCADE,
    file_name text,
    file_type text,
    storage_uri text,
    checksum text,
    uploaded_at timestamptz,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS oms.form_definition (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL,
    version text NOT NULL,
    service_line_id bigint REFERENCES oms.service_line(id),
    name text NOT NULL,
    schema_json jsonb NOT NULL,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (code, version)
);

CREATE TABLE IF NOT EXISTS oms.form_submission (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid NOT NULL REFERENCES oms.case_request(id) ON DELETE CASCADE,
    form_definition_id uuid REFERENCES oms.form_definition(id),
    submitted_by uuid REFERENCES oms.user_account(id),
    submitted_at timestamptz,
    answers jsonb NOT NULL,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_form_submission_answers_gin
ON oms.form_submission USING gin (answers jsonb_path_ops);

CREATE TABLE IF NOT EXISTS oms.case_checklist_response (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid NOT NULL REFERENCES oms.case_request(id) ON DELETE CASCADE,
    checklist_code text,
    item_code text,
    result_code text,
    observations text,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS oms.lab_control (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    case_request_id uuid REFERENCES oms.case_request(id) ON DELETE CASCADE,
    control_number text,
    status_code text,
    started_at timestamptz,
    completed_at timestamptz,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS oms.lab_test_result (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_control_id uuid REFERENCES oms.lab_control(id) ON DELETE CASCADE,
    test_code text,
    result_code text,
    result_value text,
    unit text,
    performed_at timestamptz,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS oms.lab_report (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_control_id uuid REFERENCES oms.lab_control(id) ON DELETE CASCADE,
    report_number text,
    status_code text,
    issued_at timestamptz,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS oms.lab_review (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_control_id uuid REFERENCES oms.lab_control(id) ON DELETE CASCADE,
    reviewer_user_id uuid REFERENCES oms.user_account(id),
    status_code text,
    reviewed_at timestamptz,
    observations text,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS oms.surveillance_notice (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    notice_number text,
    notice_type text,
    status_code text,
    product_id uuid REFERENCES oms.product(id),
    organization_id uuid REFERENCES oms.organization(id),
    issued_at timestamptz,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    legacy_source_id smallint REFERENCES oms.legacy_source(id),
    legacy_table text,
    legacy_pk jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS legacy.record_mapping (
    id bigserial PRIMARY KEY,
    legacy_source_id smallint NOT NULL REFERENCES oms.legacy_source(id),
    legacy_table text NOT NULL,
    legacy_pk jsonb NOT NULL,
    target_schema text NOT NULL,
    target_table text NOT NULL,
    target_id text NOT NULL,
    migration_batch text,
    migrated_at timestamptz NOT NULL DEFAULT now(),
    validation_status text NOT NULL DEFAULT 'pending',
    validation_notes text
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_record_mapping_legacy_target
ON legacy.record_mapping (legacy_source_id, legacy_table, (legacy_pk::text), target_schema, target_table);

CREATE INDEX IF NOT EXISTS idx_record_mapping_target
ON legacy.record_mapping (target_schema, target_table, target_id);

INSERT INTO oms.legacy_source (code, name, description)
VALUES
    ('ventanilla', 'VENTANILLA', 'Base legacy de ventanilla'),
    ('administrativo_evaluador', 'ADMINISTRATIVO-EVALUADOR', 'Base legacy administrativo/evaluador'),
    ('monitoreo_vigilancia', 'MONITOREO-VIGILANCIA', 'Base legacy monitoreo/vigilancia')
ON CONFLICT (code) DO NOTHING;
