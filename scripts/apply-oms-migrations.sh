#!/usr/bin/env bash
set -euo pipefail

DATABASE_URL="${1:-${DATABASE_URL:-}}"

if [[ -z "$DATABASE_URL" ]]; then
  echo "Uso: $0 postgres://usuario:password@host:puerto/base" >&2
  echo "Tambien puedes exportar DATABASE_URL antes de ejecutar make apply-oms." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for migration in supabase/migrations/*.sql; do
  echo "Aplicando $migration"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$migration"
done

echo "Migraciones OMS aplicadas."
