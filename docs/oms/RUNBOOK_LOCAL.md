# Runbook Local Supabase OMS

## Requisitos

- Docker compatible con Docker Compose.
- `psql` instalado para aplicar migraciones manuales.
- Supabase CLI opcional para flujo `supabase start`, `supabase db reset` y `supabase db push`.

## Flujo con Docker Compose self-hosted

1. Crear `.env` local:

```bash
cp .env.example .env
```

2. Editar `.env` con secretos locales. No subir `.env`.

3. Validar estructura:

```bash
make check
```

4. Levantar stack:

```bash
make up
make ps
```

5. Aplicar modelo OMS:

```bash
export DATABASE_URL='postgres://postgres:TU_PASSWORD@127.0.0.1:5432/postgres'
make apply-oms
make validate-oms
```

## Flujo con Supabase CLI

Supabase CLI genera y usa `supabase/config.toml`. La documentacion oficial indica que `supabase/config.toml` se genera con `supabase init`, que las migraciones viven en `supabase/migrations` y que `supabase db reset` aplica migraciones y seeds locales.

```bash
supabase start
supabase db reset
```

## Endpoints locales esperados

### Docker Compose self-hosted

- Gateway Kong: `http://localhost:8000`
- REST: `http://localhost:8000/rest/v1`
- Auth: `http://localhost:8000/auth/v1`
- Storage: `http://localhost:8000/storage/v1`
- Realtime: `http://localhost:8000/realtime/v1`
- PostgreSQL: `localhost:5432`

### Supabase CLI

- API: `http://127.0.0.1:54321`
- Studio: `http://127.0.0.1:54323`
- PostgreSQL: `localhost:54322`

## Validacion minima

```sql
select schemaname, tablename
from pg_tables
where schemaname in ('oms', 'ref', 'legacy', 'staging')
order by schemaname, tablename;
```

Debe existir el modelo normalizado con schemas `oms`, `ref`, `legacy` y `staging`.
