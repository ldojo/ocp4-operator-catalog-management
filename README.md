# ocp-operator-catalog-pipeline

Ex:
```
oc process -f operator-registry-template.yaml -p NAME=citi -p EAR_OPERATOR_MANIFESTS_URL="http://10.0.0.14:8081/artifactory/ocp-catalog/ocp-catalog-1.0.2.tar.gz" -p IMAGE=10.0.0.14:8081/docker-local/citi-ose-operator-registry:v4.3 | oc create -f -
```

