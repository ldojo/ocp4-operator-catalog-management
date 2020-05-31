#!/bin/bash
set -x

#be sure to set the REPO_URL variable

REG_CREDS=${XDG_RUNTIME_DIR}/containers/auth.json


for CATALOG in redhat-operators certified-operators community-operators
do
  oc adm catalog build --manifest-dir=manifests --appregistry-org=$CATALOG --insecure -a ${REG_CREDS}
done

