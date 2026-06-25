-- Seed minimum canonical references.

INSERT INTO oms.legacy_source (code, name, description)
VALUES
    ('ventanilla', 'VENTANILLA', 'Base legacy de ventanilla'),
    ('administrativo_evaluador', 'ADMINISTRATIVO-EVALUADOR', 'Base legacy administrativo/evaluador'),
    ('monitoreo_vigilancia', 'MONITOREO-VIGILANCIA', 'Base legacy monitoreo/vigilancia')
ON CONFLICT (code) DO NOTHING;

INSERT INTO oms.service_line (code, name, area, description)
VALUES
    ('ec', 'EC', 'ventanilla', 'Tipo de tramite EC'),
    ('ef', 'EF', 'ventanilla', 'Tipo de tramite EF'),
    ('lc', 'LC', 'ventanilla', 'Tipo de tramite LC'),
    ('mm', 'MM', 'ventanilla', 'Tipo de tramite MM'),
    ('pa', 'PA', 'ventanilla', 'Tipo de tramite PA'),
    ('pb', 'PB', 'ventanilla', 'Tipo de tramite PB'),
    ('pc', 'PC', 'ventanilla', 'Tipo de tramite PC'),
    ('pn', 'PN', 'ventanilla', 'Tipo de tramite PN'),
    ('qc', 'QC', 'ventanilla', 'Tipo de tramite QC'),
    ('fv', 'FV', 'ventanilla', 'Tipo de tramite FV'),
    ('al', 'AL', 'monitoreo_vigilancia', 'Alerta o tramite AL'),
    ('in', 'IN', 'monitoreo_vigilancia', 'Inspeccion o tramite IN')
ON CONFLICT (code, area) DO NOTHING;

INSERT INTO ref.catalog_type (code, name, description)
VALUES
    ('case_status', 'Estados de caso', 'Estados canonicos de solicitudes'),
    ('party_role', 'Roles de participantes', 'Roles de personas y organizaciones en casos'),
    ('document_type', 'Tipos de documento', 'Documentos requeridos o revisados'),
    ('product_type', 'Tipos de producto', 'Clasificacion canonica de productos'),
    ('legacy_catalog', 'Catalogos legacy', 'Catalogos simples migrados desde tablas ctg_*')
ON CONFLICT (code) DO NOTHING;

