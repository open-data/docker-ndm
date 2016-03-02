#!/bin/sh
export PROJECT_NAME=stcndm

export SOLR_COMPOSE=docker-compose.solr.yml
export SOLR_CONTAINER=${PROJECT_NAME}_solr_1
export POSTGRES_COMPOSE=docker-compose.postgres.yml
export POSTGRES_CONTAINER=${PROJECT_NAME}_postgres_1

export CONFIG = ../development.ini
export VENV_PATH = ../venv

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
	. ${VENV_PATH}/bin/activate && \
		paster --plugin=ckan db init -c ${CONFIG}

load-postgres-data:
	docker exec -it --user=postgres ${POSTGRES_CONTAINER} bash -c \
		'psql "$$CKAN_DB" < /tmp/postgres-data/stcndm_ckan.sql'
	docker exec -it --user=postgres ${POSTGRES_CONTAINER} bash -c \
		'psql "$$CKAN_DATASTORE_DB" < /tmp/postgres-data/stcndm_ckan_datastore.sql'

set-permissions-postgress:
	. ${VENV_PATH}/bin/activate && \
	paster --plugin=ckan datastore set-permissions -c ${CONFIG} | \
	sudo -u postgres psql -h localhost -p 5433

up-postgres:
	docker-compose -f ${POSTGRES_COMPOSE} -p ${PROJECT_NAME} up -d

stop-postgres:
	docker-compose -f ${POSTGRES_COMPOSE} -p ${PROJECT_NAME} stop

down-postgres:
	docker-compose -f ${POSTGRES_COMPOSE} -p ${PROJECT_NAME} down

# Solr Config
build-solr: up-solr
	docker exec -it --user=solr ${SOLR_CONTAINER} mkdir	\
		/opt/solr/server/solr/configsets/stcndm
	docker exec -it --user=solr ${SOLR_CONTAINER} cp -R \
	 	/media/stcnmd_solr_conf \
	 	/opt/solr/server/solr/configsets/stcndm/conf/
	docker exec -it --user=solr ${SOLR_CONTAINER} cp -R \
		/opt/solr/server/solr/configsets/data_driven_schema_configs/conf/lang \
		/opt/solr/server/solr/configsets/stcndm/conf/lang
	docker exec -it --user=solr ${SOLR_CONTAINER} cp \
		/opt/solr/server/solr/configsets/stcndm/conf/schema-dev.xml \
		/opt/solr/server/solr/configsets/stcndm/conf/schema.xml
	docker exec -it --user=solr ${SOLR_CONTAINER} cp \
		/opt/solr/server/solr/configsets/stcndm/conf/solrconfig-dev.xml \
		/opt/solr/server/solr/configsets/stcndm/conf/solrconfig.xml
	docker exec -it --user=solr ${SOLR_CONTAINER} bin/solr create \
		-c stcndm -d /opt/solr/server/solr/configsets/stcndm/conf

rebuild-solr: down-solr build-solr

up-solr:
	docker-compose -f ${SOLR_COMPOSE} -p ${PROJECT_NAME}  up -d

stop-solr:
	docker-compose -f ${SOLR_COMPOSE} -p ${PROJECT_NAME} stop

down-solr:
	docker-compose -f ${SOLR_COMPOSE} -p ${PROJECT_NAME} down

load-solr-index:
	docker cp ./solr-index/data \
		${SOLR_CONTAINER}:/opt/solr/server/solr/stcndm/
	docker exec -it --user=root ${SOLR_CONTAINER} chown \
		-R solr:solr /opt/solr/server/solr/stcndm/data
	docker-compose -f ${SOLR_COMPOSE} -p ${PROJECT_NAME} restart
