#!/bin/bash
#
#  www.datasentinel.io
#

#-------------------------------------------------------------------------------------------
# Name: deploy_datasentinel_function.sh
#
# Purpose
# -------
# Iterate over every regular PostgreSQL database in the cluster (excluding
# template0/1 and the maintenance database `postgres`), create or replace the
# `datasentinel_analytics` function from a SQL file, and grant EXECUTE on that
# function to the user `datasentinel`.
#
# Prerequisites
# -------------
# • Run as a superuser or a role with:
#     - CONNECT privilege on every target database
#     - CREATE privilege in the schema where the function lives
#     - Ability to GRANT EXECUTE on that function
#
# How it works
# ------------
# 1. Connect to the `postgres` maintenance DB.
# 2. Query `pg_database` for all non-template, connectable databases except
#    `postgres`.
# 3. For each database:
#      a. Run the SQL file that (re)creates the function.
#      b. Execute GRANT EXECUTE … TO datasentinel.
#
#
# Usage
# -----
#   chmod +x deploy_datasentinel_function.sh
#   ./deploy_datasentinel_function.sh $1
#
#  $1 is the optional first positional argument that lets you specify the PostgreSQL port number, 
#  overriding the script’s default of 5432.
#
###############################################################################
FUNCFILE="./datasentinel_analytics.sql"
PORT="${1:-5432}"

TARGET_USER="datasentinel"

set -euo pipefail

# Fetch every normal DB except 'postgres' and the templates
DBLIST=$(psql -p ${PORT} -At -d postgres \
    -c "SELECT datname
          FROM pg_database
         WHERE datallowconn
           AND NOT datistemplate
           AND datname <> 'postgres'")

for db in ${DBLIST}; do
  echo ">>> Installing function in database: ${db}"
  psql -p ${PORT} -v ON_ERROR_STOP=1 -d "${db}" -f "${FUNCFILE}"
  psql -p ${PORT} -v ON_ERROR_STOP=1 -d "${db}" \
       -c "GRANT EXECUTE ON FUNCTION datasentinel_analytics(text,text,text,text) TO ${TARGET_USER};"
done

echo -e "\nDone: function deployed and privilege granted in all databases.\n"
