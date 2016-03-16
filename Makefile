#!/bin/sh
export PROJECT_NAME=stcndm

export SOLR_COMPOSE=docker-compose.solr.yml
export SOLR_CONTAINER=${PROJECT_NAME}_solr_1
export POSTGRES_COMPOSE=docker-compose.postgres.yml
export POSTGRES_CONTAINER=${PROJECT_NAME}_postgres_1

export CONFIG = ../development.ini
export VENV_PATH = ../venv

default: up

init: build init-postgres set-permissions-postgress load-postgres-data load-solr-index

build: build-postgres build-solr

rebuild: rebuild-postgres rebuild-solr

up: up-postgres up-solr

stop: stop-postgres stop-solr

down: down-postgres down-solr

# Postgres config
build-postgres: up-postgres

rebuild-postgres: down-postgres build-postgres

init-postgres:
	. ${VENV_PATH}/bin/activate && \
		paster --plugin=ckan db init -c ${CONFIG}

set-permissions-postgress:
	. ${VENV_PATH}/bin/activate && \
		paster --plugin=ckan datastore set-permissions -c ${CONFIG} | cat | \
		docker exec -i --user=postgres ${POSTGRES_CONTAINER} psql

up-postgres:
	docker-compose -f ${POSTGRES_COMPOSE} -p ${PROJECT_NAME} up -d

stop-postgres:
	docker-compose -f ${POSTGRES_COMPOSE} -p ${PROJECT_NAME} stop

down-postgres:
	docker-compose -f ${POSTGRES_COMPOSE} -p ${PROJECT_NAME} down

load-postgres-data:
	cat ./postgres-data/stcndm_ckan.sql | \
		docker exec -i --user=postgres ${POSTGRES_CONTAINER} bash -c \
		'psql "$$CKAN_POSTGRES_DB"'
	cat ./postgres-data/stcndm_ckan_datastore.sql | \
		docker exec -i --user=postgres ${POSTGRES_CONTAINER} bash -c \
		'psql "$$CKAN_DATASTORE_POSTGRES_DB"'

# Solr Config
build-solr: up-solr
	docker exec -it --user=solr ${SOLR_CONTAINER} \
		/docker-entrypoint-initsolr.d/create-core.sh

rebuild-solr: down-solr build-solr

up-solr:
	docker-compose -f ${SOLR_COMPOSE} -p ${PROJECT_NAME} up -d

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
