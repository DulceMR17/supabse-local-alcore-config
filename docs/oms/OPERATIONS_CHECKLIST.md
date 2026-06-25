# Checklist Operativo OMS Supabase

## Antes de levantar local

- Copiar `.env.example` a `.env`.
- Generar secretos locales fuertes para `POSTGRES_PASSWORD`, `JWT_SECRET`, `SERVICE_ROLE_KEY`, `SECRET_KEY_BASE` y `PG_META_CRYPTO_KEY`.
- Confirmar que `.env` no esta trackeado por Git.
- Ejecutar `make check`.

## Antes de aplicar migraciones

- Confirmar que la base destino es local o staging.
- Respaldar si hay datos importantes.
- Ejecutar `make apply-oms`.
- Ejecutar `make validate-oms`.
- Revisar `legacy.record_mapping` despues de transformaciones.

## Antes de conectar `oms-backend`

- Confirmar `SUPABASE_URL`.
- Confirmar `SUPABASE_ANON_KEY` solo para clientes publicos.
- Confirmar `SUPABASE_SERVICE_ROLE_KEY` solo en backend.
- Confirmar `DATABASE_URL` solo en backend/ops.
- Verificar que RLS este habilitado y que no existan grants abiertos accidentalmente.

## Antes de produccion

- Definir matriz de roles funcionales.
- Crear politicas RLS por rol y ownership real.
- Activar SMTP real para Auth.
- Definir retencion de Storage.
- Configurar backups y restauracion.
- Definir observabilidad de logs.
- Ejecutar pruebas de carga para endpoints criticos.
