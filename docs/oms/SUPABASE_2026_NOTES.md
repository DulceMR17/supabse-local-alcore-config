# Notas Supabase 2026 para este repo

Estas notas explican decisiones tomadas para mantener este repo compatible con el estado actual de Supabase local/self-hosted.

## CLI y migraciones

Supabase documenta el flujo local con `supabase/config.toml`, migraciones en `supabase/migrations`, seed en `supabase/seed.sql` y aplicacion local con `supabase db reset`.

Este repo conserva `docker-compose.yml` para self-hosted educativo y agrega `supabase/` para que OMS tenga migraciones versionadas.

## Self-hosted

Supabase anuncio cambios recientes para self-hosted:

- Postgres 17 pasa a ser el camino nuevo para defaults self-hosted.
- Studio cambia el rol de conexion desde `supabase_admin` hacia `postgres`.
- Analytics y Vector pasan a opt-in en self-hosted.

Por compatibilidad con el compose existente, este PR no fuerza upgrade de imagen Postgres. La actualizacion de imagen debe hacerse en un cambio separado, probando datos, Studio, Meta, Auth, Storage y PostgREST.

## Data API y RLS

Nuevas tablas no siempre deben exponerse automaticamente. Para OMS se deja una postura conservadora:

- `ref` puede leerse por usuarios autenticados.
- `legacy` y `staging` son internos.
- `oms` queda con RLS habilitado pero sin politicas amplias hasta definir roles funcionales.

## Node y frontend

Para React/Node moderno, mantener Node actualizado. El frontend nunca debe recibir `service_role`.
