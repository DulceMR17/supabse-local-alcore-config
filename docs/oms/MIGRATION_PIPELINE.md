# Pipeline de Migracion Legacy a OMS Normalizado

## Flujo recomendado

1. Exportar tablas legacy por base origen.
2. Cargar registros a `staging.legacy_raw_record`.
3. Ejecutar migraciones de transformacion.
4. Registrar equivalencias en `legacy.record_mapping`.
5. Validar conteos y constraints.
6. Exponer consumo nuevo desde `oms.*` y `ref.*`.

## Contrato de staging

Cada fila legacy debe entrar asi:

```sql
insert into staging.legacy_raw_record (
  legacy_source_code,
  legacy_table,
  legacy_pk,
  record_data,
  record_hash
) values (
  'ventanilla',
  'vus_tramites_ec',
  '{"vus_ec_id": 123}',
  '{"vus_ec_numsol": "EC-001", "vus_ec_obs": "texto"}',
  'hash-opcional'
);
```

## Equivalencia legacy-normalizado

`legacy.record_mapping` permite resolver una pantalla vieja hacia el registro nuevo:

```sql
select target_schema, target_table, target_id
from legacy.record_mapping
where legacy_table = 'vus_tramites_ec'
  and legacy_pk = '{"vus_ec_id": 123}'::jsonb;
```

## Validaciones

```bash
make validate-oms
```

## Criterio de aceptacion

- Todas las tablas legacy tienen target documentado.
- Todos los campos legacy tienen columna normalizada o ruta JSONB.
- No hay constraints invalidas.
- Los formularios grandes quedan verticalizados en JSONB con `jsonbPath` trazable.
