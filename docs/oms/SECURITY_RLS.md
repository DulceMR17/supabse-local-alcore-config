# Seguridad y RLS para OMS Supabase

## Postura base

El stack queda preparado con una postura conservadora:

- RLS habilitado para tablas en `oms`, `ref`, `legacy` y `staging`.
- `legacy` y `staging` quedan como schemas internos sin acceso directo para `anon` ni `authenticated`.
- `ref.catalog_type` y `ref.catalog_item` permiten lectura a usuarios autenticados porque son catalogos de apoyo.
- Las tablas transaccionales `oms.*` no se exponen al frontend hasta definir ownership, roles funcionales y politicas por modulo.

## Por que no abrir todo

Supabase expone tablas por PostgREST cuando el schema esta habilitado en la API y existen grants. RLS controla filas, no reemplaza el diseno de permisos. Abrir `oms.*` sin reglas de negocio claras puede producir BOLA/IDOR.

## Reglas obligatorias para futuras politicas

- No usar `service_role` en frontend.
- No usar `auth.role()`; preferir `TO authenticated`.
- `TO authenticated` solo no es autorizacion suficiente.
- Las politicas `UPDATE` deben incluir `USING` y `WITH CHECK`.
- Si se crean views expuestas en Postgres 15+, usar `WITH (security_invoker = true)`.
- No usar `raw_user_meta_data` para autorizacion. Usar `app_metadata` o tablas internas.

## Siguiente paso antes de produccion

Definir una matriz de permisos por rol:

| Rol | Lectura | Escritura | Comentario |
| --- | --- | --- | --- |
| admin | Todo `oms.*` | Todo `oms.*` | Solo backend o usuarios internos autorizados |
| operador | Casos asignados | Actualiza estados/documentos | Requiere ownership por caso |
| evaluador | Casos en etapa asignada | Evaluaciones y observaciones | Requiere `assigned_user_id` o tabla de asignaciones |
| lector | Solo lectura controlada | Ninguna | Reporteria o auditoria |

Hasta cerrar esa matriz, el backend debe consumir con service role en servidor y exponer endpoints propios.
