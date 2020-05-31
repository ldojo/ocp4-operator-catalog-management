#!/bin/bash
set -x

#be sure to set the REPO_URL variable

REG_CREDS=${XDG_RUNTIME_DIR}/containers/auth.json

rm operatorhub-mapping.txt

for CATALOG in redhat-operators certified-operators community-operators
do
	 CATALOG_IMAGE=${REPO_URL}/docker-local/${CATALOG}:v4.4
	oc adm catalog mirror --manifests-only ${REPO_URL}/docker-local/${CATALOG}:v4.4 test.io --insecure -a ${REG_CREDS} 
	cat ${CATALOG}-manifests/mapping.txt | sort -u >> operatorhub-mapping.txt
done


