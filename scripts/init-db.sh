#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE docuflow_test OWNER $POSTGRES_USER;
    \c docuflow_test
    CREATE EXTENSION IF NOT EXISTS vector;
EOSQL
