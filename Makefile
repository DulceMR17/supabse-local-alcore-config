.PHONY: help check compose-config up down logs ps db-shell apply-oms validate-oms

COMPOSE ?= docker compose
PSQL ?= psql
DATABASE_URL ?= postgres://postgres:postgres@127.0.0.1:5432/postgres

help:
	@echo "Comandos disponibles:"
	@echo "  make check           Valida estructura, docker compose y archivos OMS"
	@echo "  make compose-config  Renderiza docker-compose.yml"
	@echo "  make up              Levanta el stack self-hosted"
	@echo "  make down            Detiene el stack"
	@echo "  make logs            Muestra logs"
	@echo "  make ps              Lista contenedores"
	@echo "  make db-shell        Abre psql usando DATABASE_URL"
	@echo "  make apply-oms       Aplica migraciones OMS con psql"
	@echo "  make validate-oms    Ejecuta checks SQL OMS con psql"

check:
	./scripts/check-oms-supabase.sh

compose-config:
	$(COMPOSE) config

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

db-shell:
	$(PSQL) "$(DATABASE_URL)"

apply-oms:
	./scripts/apply-oms-migrations.sh "$(DATABASE_URL)"

validate-oms:
	$(PSQL) "$(DATABASE_URL)" -v ON_ERROR_STOP=1 -f supabase/tests/001_migration_quality_checks.sql
