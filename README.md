
## Purpose of this project

The mechanism provided here was born out of the challenge of managing OperatorHub Operator contents across various Openshift 4 environments in a disconnected/restricted network environment. In an disconnected enterprise software shop with Openshift 4 as a platform, there may be a need to curate the contents of the OperatorHub Operator listing. For example, perhaps Operators need to first be "certified" internally within the enterprise shop, and therefore the Operators that would be available between DEV/STAGE/PROD OPenshift clusters may need to vary. Red Hat provides [solid tooling to achieve this](https://docs.openshift.com/container-platform/4.3/operators/olm-restricted-networks.html). This tooling is  centered around building an Operator Registry Catalog image with the target Operators list, to be deployed alongside a `CatalogSource` in the `openshift-marketplace` namespace. 

The tooling works well. However, it implies that some infrastructure is needed to perform the build to update an Operator catalog in an Openshift Cluster, either manually, or scripted with automation. For example, an environment with the Openshift `oc` tool and `podman` would be needed to perform the operator catalog image build. If scripted into an automated pipeline, such as Jenkins, the pipeline would need to be configured/provisioned to have these tools enabled. The mechanism described here circumvents that need by managing the contents on an operator catalog via simple tar.gz archives of package manifests. Given that software shops most often have some kind of internal artifact repository hosted like [Artifactory](https://jfrog.com/artifactory/) or [Nexus](https://www.sonatype.com/product-nexus-repository), allowing users to manage basic tar.gz archive files instead of building/managing catalog images may better align with their Software Development Cycle. 

### Here is an example:








To disable the default catalog sources:
```
oc patch OperatorHub cluster --type json     -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

Ex:
```
oc process -f operator-registry-template.yaml -p NAME=citi -p MANIFEST_ARCHIVE_URL="http://${MANIFEST_ARCHIVE_URL}/artifactory/ocp-catalog/ocp-catalog-1.0.2.tar.gz" -p CURL_FETCH_CREDS="-uadmin:password" -p IMAGE=${MANIFEST_ARCHIVE_URL}/docker-local/citi-ose-operator-registry:v4.3 | oc create -f -
```

