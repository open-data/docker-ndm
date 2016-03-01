#!/bin/sh
export NDM_SOLR_COMPOSE=docker-compose.solr.yml
export NDM_SOLR_CONTAINER=dockerndm_solr_1
export NDM_POSTGRES_COMPOSE=docker-compose.postgres.yml
export NDM_POSTGRES_CONTAINER=dockerndm_postgres_1

export NDM_CONFIG = ../development.ini
export NDM_VENV_PATH = ../venv

default: up

init: build init-db-postgres set-permissions-postgress load-postgres-data load-solr-index

build: build-postgres build-solr

rebuild: rebuild-postgres rebuild-solr

up: up-postgres up-solr

stop: stop-postgres stop-solr

down: down-postgres down-solr

# Postgres config
build-postgres: up-postgres

rebuild-postgres: down-postgres build-postgres

init-db-postgres:
	. ${NDM_VENV_PATH}/bin/activate && \
		paster --plugin=ckan db init -c ${NDM_CONFIG}

load-postgres-data:
	docker exec -it --user=postgres ${NDM_POSTGRES_CONTAINER} bash -c \
		'psql "$$CKAN_DB" < /tmp/postgres-data/stcndm_ckan.sql'
	docker exec -it --user=postgres ${NDM_POSTGRES_CONTAINER} bash -c \
		'psql "$$CKAN_DATASTORE_DB" < /tmp/postgres-data/stcndm_ckan_datastore.sql'

set-permissions-postgress:
	. ${NDM_VENV_PATH}/bin/activate && \
	paster --plugin=ckan datastore set-permissions -c ${NDM_CONFIG}

up-postgres:
	docker-compose --file=${NDM_POSTGRES_COMPOSE} up -d

stop-postgres:
	docker-compose --file=${NDM_POSTGRES_COMPOSE} stop

down-postgres:
	docker-compose --file=${NDM_POSTGRES_COMPOSE} down

# Solr Config
build-solr: up-solr
	docker exec -it --user=solr ${NDM_SOLR_CONTAINER} mkdir	\
		/opt/solr/server/solr/configsets/stcndm
	docker exec -it --user=solr ${NDM_SOLR_CONTAINER} cp -R \
	 	/media/stcnmd_solr_conf \
	 	/opt/solr/server/solr/configsets/stcndm/conf/
	docker exec -it --user=solr ${NDM_SOLR_CONTAINER} cp -R \
		/opt/solr/server/solr/configsets/data_driven_schema_configs/conf/lang \
		/opt/solr/server/solr/configsets/stcndm/conf/lang
	docker exec -it --user=solr ${NDM_SOLR_CONTAINER} cp \
		/opt/solr/server/solr/configsets/stcndm/conf/schema-dev.xml \
		/opt/solr/server/solr/configsets/stcndm/conf/schema.xml
	docker exec -it --user=solr ${NDM_SOLR_CONTAINER} cp \
		/opt/solr/server/solr/configsets/stcndm/conf/solrconfig-dev.xml \
		/opt/solr/server/solr/configsets/stcndm/conf/solrconfig.xml
	docker exec -it --user=solr ${NDM_SOLR_CONTAINER} bin/solr create \
		-c stcndm -d /opt/solr/server/solr/configsets/stcndm/conf

rebuild-solr: down-solr build-solr

up-solr:
	docker-compose --file=${NDM_SOLR_COMPOSE} up -d

stop-solr:
	docker-compose --file=${NDM_SOLR_COMPOSE} stop

down-solr:
	docker-compose --file=${NDM_SOLR_COMPOSE} down

load-solr-index:
	docker cp ./solr-index/data \
		${NDM_SOLR_CONTAINER}:/opt/solr/server/solr/stcndm/
	docker-compose --file=${NDM_SOLR_COMPOSE} restart
