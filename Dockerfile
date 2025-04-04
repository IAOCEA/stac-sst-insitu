FROM python:3.12-slim-bookworm as base

# install postgres and postgis
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y sudo postgresql postgis supervisor python3-pip python3 zstd

# add a dedicated user
RUN useradd --uid 1000 -U -G ssl-cert,postgres pgstac

# setup the python environment
COPY ./requirements.txt requirements.txt
RUN pip install --upgrade pip
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# setup environment variables
# - pgstac settings needed to connect to the database
ENV PGUSER pgstac
ENV PGPASSWORD pgstac
ENV PGDATABASE postgis
ENV PGHOST 127.0.0.1
ENV PGPORT 5432

# - postgres settings needed to connect to the database
ENV POSTGRES_USER pgstac
ENV POSTGRES_PASS pgstac
ENV POSTGRES_DBNAME postgis
ENV POSTGRES_DB postgis
ENV POSTGRES_HOST 0.0.0.0
ENV POSTGRES_PORT 5432
ENV POSTGRES_HOST_READER 0.0.0.0
ENV POSTGRES_HOST_WRITER 0.0.0.0

# - application settings
ENV APP_HOST 0.0.0.0
ENV APP_PORT 9588

RUN mkdir -p /app; chown pgstac:pgstac /app
# configure and populate the database
COPY --chown=pgstac contents/ /app/contents/
COPY --chown=pgstac ingest.py /app
COPY --chown=pgstac --chmod=0755 setup-database.sh /app
WORKDIR /app
RUN ./setup-database.sh

# run the postgresql database and the stac server
COPY --chown=pgstac supervisord.conf /etc/supervisor/supervisord.conf
COPY --chown=pgstac --chmod=0755 run-supervisor.sh /app
COPY --chown=pgstac --chmod=0755 run-postgresql.sh /app
COPY --chown=pgstac --chmod=0755 run-stacserver.sh /app
RUN chown -R pgstac:pgstac /var/run/postgresql \
    && chown -R pgstac:pgstac /var/lib/postgresql/

USER pgstac
ENTRYPOINT ["/app/run-supervisor.sh"]
