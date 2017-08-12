#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE recruitx_backend_prod;
    GRANT ALL PRIVILEGES ON DATABASE recruitx_backend_prod TO postgres;
EOSQL
