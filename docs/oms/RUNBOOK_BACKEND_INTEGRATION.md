# Integracion OMS Backend con Supabase

## Variables que necesita el backend

El backend Node.js debe recibir variables por entorno, nunca hardcodeadas.

```bash
SUPABASE_URL=http://localhost:8000
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
DATABASE_URL=postgres://postgres:password@localhost:5432/postgres
```

Para frontend React usar solo `SUPABASE_URL` y `SUPABASE_ANON_KEY`. No exponer `SUPABASE_SERVICE_ROLE_KEY`.

## Schemas de consumo

- `oms`: entidades transaccionales normalizadas.
- `ref`: catalogos normalizados.
- `legacy`: trazabilidad de registros migrados.
- `staging`: carga cruda temporal desde legacy.

## Flujo de migracion de datos

1. Extraer cada tabla legacy hacia `staging.legacy_raw_record`.
2. Guardar `legacy_source_code`, `legacy_table`, `legacy_pk` y `record_data`.
3. Ejecutar transformaciones hacia `oms.*` y `ref.*`.
4. Registrar equivalencias en `legacy.record_mapping`.
5. Validar con `supabase/tests/001_migration_quality_checks.sql`.

## Patron de consulta para reemplazar legacy

### Antes

```sql
select *
from vus_tramites_ec
where vus_ec_numsol = :numero;
```

### Ahora

```js
const { data, error } = await supabase
  .schema('oms')
  .from('case_request')
  .select(`
    id,
    request_number,
    procedure_code,
    status_code,
    lifecycle_state,
    form_payload,
    core_payload
  `)
  .eq('legacy_table', 'vus_tramites_ec')
  .eq('request_number', numero)
  .maybeSingle();
```

Los campos variables de la tabla legacy se leen desde `form_payload.raw` o el contenedor JSONB indicado por `docs/oms/legacy_to_canonical_mapping.csv`.

## Reglas para JSONB

- Campos de busqueda, trazabilidad, estado y relaciones deben estar como columnas tipadas.
- Formularios extensos y campos variables se preservan en JSONB.
- Para actualizar JSONB, construir un patch controlado desde backend; no permitir que el frontend mande objetos arbitrarios sin validacion.
- Para busquedas frecuentes dentro de JSONB, crear indice GIN o promover el campo a columna tipada si pasa a ser critico.

## Seguridad

- Habilitar RLS antes de exponer schemas a clientes.
- No usar `service_role` en React.
- Para vistas expuestas, preferir `security_invoker = true` en Postgres 15+.
- Las politicas de `UPDATE` deben tener `USING` y `WITH CHECK`.
- Validar permisos por rol funcional, no solo con `TO authenticated`.
