#!/usr/bin/env bash

set -euo pipefail

createuser --username "${POSTGRES_USER}" barman
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    GRANT EXECUTE ON FUNCTION pg_start_backup(text, boolean, boolean) to barman;
    GRANT EXECUTE ON FUNCTION pg_stop_backup() to barman;
    GRANT EXECUTE ON FUNCTION pg_stop_backup(boolean, boolean) to barman;
    GRANT EXECUTE ON FUNCTION pg_switch_wal() to barman;
    GRANT EXECUTE ON FUNCTION pg_create_restore_point(text) to barman;
    GRANT pg_read_all_settings TO barman;
    GRANT pg_read_all_stats TO barman;
EOSQL

createuser --username "${POSTGRES_USER}" --replication streaming_barman

{
    echo "# allows barman access from all hosts"
    echo "host  all             barman              all trust"
    echo "host  replication     streaming_barman    all trust"
} >> "${PGDATA}/pg_hba.conf"

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    SELECT pg_reload_conf();
EOSQL