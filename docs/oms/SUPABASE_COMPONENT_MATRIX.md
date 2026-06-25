# Matriz de Componentes Supabase para OMS

| Componente | Estado | Uso en OMS |
| --- | --- | --- |
| Postgres | Requerido | Modelo normalizado `oms`, `ref`, `legacy`, `staging` |
| PostgREST | Requerido | API de lectura/escritura controlada por RLS |
| Auth | Requerido | JWT y usuarios para frontend/backend |
| Storage | Requerido | Documentos, importaciones legacy y adjuntos |
| Realtime | Opcional inicial | Eventos de casos, estados y notificaciones |
| Edge Functions | Opcional inicial | Health checks, jobs ligeros, webhooks |
| Studio | Requerido en local | Inspeccion y administracion de schemas |
| Kong | Requerido en self-hosted | Gateway unico local |
| PgBouncer | Recomendado | Pooling para backend Node.js |
| Analytics/Vector | Opt-in | No requerido para primera version OMS |

## Buckets iniciales

- `oms-documents`: documentos funcionales del caso.
- `oms-legacy-imports`: archivos de importacion desde legacy.

Ambos son privados. El acceso debe pasar por backend o URLs firmadas.
