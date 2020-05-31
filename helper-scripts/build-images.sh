#!/bin/bash
set -x

#be sure to set the REPO_URL variable

REG_CREDS=${XDG_RUNTIME_DIR}/containers/auth.json

	 CATALOG_IMAGE=${REPO_URL}/docker-local/redhat-operators:v4.4
	 CATALOG=redhat-operators
oc adm catalog build --appregistry-org=$CATALOG --to=$CATALOG_IMAGE --insecure -a ${REG_CREDS}

         CATALOG_IMAGE=${REPO_URL}/docker-local/certified-operators:v4.4
         CATALOG=certified-operators

oc adm catalog build --appregistry-org=$CATALOG --to=$CATALOG_IMAGE --insecure -a ${REG_CREDS}

         CATALOG_IMAGE=${REPO_URL}/docker-local/community-operators:v4.4
         CATALOG=community-operators

oc adm catalog build --appregistry-org=$CATALOG --to=$CATALOG_IMAGE --insecure -a ${REG_CREDS}




