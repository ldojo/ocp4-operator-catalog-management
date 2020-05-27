# ocp-operator-catalog-pipeline

start artifactory container:
```
podman run --name artifactory -d -v /opt/jfrog/artifactory:/var/opt/jfrog/artifactory --ulimit nofile=90000:90000 -p 8081:8081 docker.bintray.io/jfrog/artifactory-pro:6.16.2
```

to push files to the artifactory:
```
curl -uadmin:AP75wUAsRv7ZX8nS8zDCa4Xbz5v -T redhat-operators.tar.gz "http://10.0.0.14:8081/artifactory/ocp-catalog/redhat-operators-5-27-20.tar.gz"
```

patch to add insecure registry if needed:
```
oc patch --type=merge --patch='{
"spec": {
    "registrySources": {
      "insecureRegistries": [
      "10.0.0.14:8081"
      ]
    }
  }
}' image.config.openshift.io/cluster
```


To disable the default catalog sources:
```
oc patch OperatorHub cluster --type json     -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": false}]'
```

Make sure the pull secret is in place for artifactory:
```
oc create secret docker-registry artifactory-secret --docker-server=10.0.0.14:8081 --docker-username=admin --docker-password=password --docker-email=lshulman@redhat.com
oc secrets link default artifactory-secret --for=pull
```


Ex:
```
oc process -f operator-registry-template.yaml -p NAME=citi -p EAR_OPERATOR_MANIFESTS_URL="http://10.0.0.14:8081/artifactory/ocp-catalog/ocp-catalog-1.0.2.tar.gz" -p IMAGE=10.0.0.14:8081/docker-local/citi-ose-operator-registry:v4.3 | oc create -f -
```

