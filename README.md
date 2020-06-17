

To disable the default catalog sources:
```
oc patch OperatorHub cluster --type json     -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

Ex:
```
oc process -f operator-registry-template.yaml -p NAME=citi -p MANIFEST_ARCHIVE_URL="http://${MANIFEST_ARCHIVE_URL}/artifactory/ocp-catalog/ocp-catalog-1.0.2.tar.gz" -p CURL_FETCH_CREDS="-uadmin:password" -p IMAGE=${MANIFEST_ARCHIVE_URL}/docker-local/citi-ose-operator-registry:v4.3 | oc create -f -
```

