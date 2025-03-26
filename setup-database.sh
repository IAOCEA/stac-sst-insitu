#!/usr/bin/env bash

# start and configure postgresql
echo "-- starting postgresql";
service postgresql start
pg_isready || exit 1

# setup database access
echo "-- initialize database";
echo "CREATE USER pgstac WITH LOGIN PASSWORD 'pgstac' SUPERUSER;" | sudo -u postgres psql
sudo -u postgres createdb pgstac

# intialize the database
echo "-- initializing database";
echo "CREATE DATABASE postgis;" | sudo -u postgres psql
dsn="postgresql://${POSTGRES_USER}:${POSTGRES_PASS}@127.0.0.1:5432/postgis"
pypgstac migrate --dsn="$dsn"

# stop postgresql
service postgresql stop
