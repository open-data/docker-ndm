#!/bin/sh
CONFIGSETS=/opt/solr/server/solr/configsets
mkdir $CONFIGSETS/stcndm
cp -R /media/solr_conf $CONFIGSETS/$CKAN_SOLR_CORE/conf/
cp -R $CONFIGSETS/data_driven_schema_configs/conf/lang $CONFIGSETS/$CKAN_SOLR_CORE/conf/lang
cp $CONFIGSETS/$CKAN_SOLR_CORE/conf/schema-dev.xml $CONFIGSETS/$CKAN_SOLR_CORE/conf/schema.xml
cp $CONFIGSETS/$CKAN_SOLR_CORE/conf/solrconfig-dev.xml $CONFIGSETS/$CKAN_SOLR_CORE/conf/solrconfig.xml
bin/solr create -c $CKAN_SOLR_CORE -d $CONFIGSETS/$CKAN_SOLR_CORE/conf
