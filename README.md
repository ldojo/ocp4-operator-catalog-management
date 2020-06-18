
## Specifications

This mechanism has been tested with Openshift 4.3 and 4.4. It is assumed to also work with Openshift 4.(x < 3), but has not been tested.

## Purpose of this project

The mechanism provided here was born out of the challenge of managing OperatorHub Operator Catalog contents across various Openshift 4 environments in a disconnected/restricted network environment. In an disconnected enterprise software shop with Openshift 4 as a platform, there may be a need to curate the contents of the OperatorHub Operator listing. For example, perhaps Operators need to first be "certified" internally within the enterprise shop, and therefore the Operators that would be available between DEV/STAGE/PROD OPenshift clusters may need to vary. Red Hat provides [solid tooling to achieve this](https://docs.openshift.com/container-platform/4.3/operators/olm-restricted-networks.html). This tooling is  centered around building an Operator Registry Catalog image with the target Operators list, to be deployed alongside a `CatalogSource` in the `openshift-marketplace` namespace. 

The tooling works well. However, it implies that some infrastructure is needed to perform the build to update an Operator catalog in an Openshift Cluster, either manually, or scripted with automation. For example, an environment with the Openshift `oc` tool and `podman` would be needed to perform the operator catalog image build. If scripted into an automated pipeline, such as Jenkins, the pipeline would need to be configured/provisioned to have these tools enabled. The mechanism described here circumvents that need by managing the contents on an operator catalog via simple tar.gz archives of package manifests. Given that software shops most often have some kind of internal artifact repository hosted like [Artifactory](https://jfrog.com/artifactory/) or [Nexus](https://www.sonatype.com/product-nexus-repository), allowing users to manage basic tar.gz archive files instead of building/managing catalog images may better align with their Software Development Cycle. 



### Here is an example:

#### Pre-reqs
First we build our Operator catalog image and push it to a dedicated container registry that makes sense for your environment The Openshift 4 clusters where you'll be deploying this Operator catalog image will need to be pre-configured with pull secrets to be able to pull this image accordingly. 

To build the image, build against the provided Dockerfile:
```
podman build -t your-repo/designated-path/operator-catalog:vX.Y.Z . 
```
Note that the Dockerfile is parameterized with [two ARGs](https://github.com/ldojo/ocp4-operator-catalog-pipeline/blob/master/Dockerfile#L1):
```
ARG OPERATOR_REGISTRY_BASE_IMAGE=registry.redhat.io/openshift4/ose-operator-registry:v4.3
ARG UBI_OR_BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
```
You can of course change those as args to the docker/podman build, particularly if you've mirrored those two images in your own disconnected or network restricted environment. The `registry.redhat.io/openshift4/ose-operator-registry:v4.3` image is used as a "builder" image to extract some needed binaries from, and the `registry.access.redhat.com/ubi8/ubi` is used as the base image for the build.

With the image built, push it to the proper docker registry where an Openshift deployment will be able to pull it. 

NOTE: we do this pre-req step to build the ose-operator-registry image only *once*. Once it is deployed, we don't need to rebuild it. It acts as a "container" for the operator listing the OperatorHub interface will provide, but we won't need to rebuild it to change the listing of operators. We point the container to the proper tar.gz package manifest archive to fetch and load instead. 

#### Day 1: 

Suppose you want to start with an Operator catalog of all of the current Red Hat Operators. You can fetch all of the "redhat-operators" category package manifests like so, to a directory named `redhat-manifests`:
```
oc adm catalog build --appregistry-org=redhat-operators --manifest-dir=./redhat-manifests
```

The result will be a list of directories inside the `redhat-manifests` dir, one for each operator. Each operator directory contains "package manifests", which are basically the CusterServiceVersion and CustomResourceDefinition Yaml files fo that operator. Thes Yaml content is all that Openshift needs to be able to install the Operator, and manage it via OLM. For more information on what CSVs and CRDs and what the Operator Lifecycle Manager workflow is, see the [official docs](https://docs.openshift.com/container-platform/4.3/operators/understanding_olm/olm-understanding-olm.html)

Next, we are going to tar/gz our `redhat-manifests` directory:
```
tar zcvf operator-catalog-v1.0.0.tar.gz redhat-manifests
```

and then push that archive to a location in your Artifactory/nexus repo that makes sense. For example, uploading this file to an Artifactory Generic repository with `curl` would look something like this:

curl -umyuser:mypassword -T operator-catalog-v1.0.0.tar.gz "http://artifactory-host:<port>/artifactory/ocp-catalog-dev/operator-catalog-v1.0.0.tar.gz"

We are now ready to deploy are operator list (note that it is assumed that any `CatalogSource`s on the target Openshift 4 cluster are disabled or removed):

```
oc project openshift-marketplace;

#lets set up some shell variables for readability

#the Openshift template that is instantiated below will create a CatalogSource, a Deployment, and a Service. They will be named according to this variable
NAME=catalog-dev

#this is the same URL as we pushed our tar.gz archive to in our earlier step above
MANIFEST_ARCHIVE_URL=http://artifactory-host:<port>/artifactory/ocp-catalog-dev/operator-catalog-v1.0.0.tar.gz
#the mechanism will fetch $MANIFEST_ARCHIVE_URL via curl, and if your artifact repo needs credentials to do so, set them here. Leave "" if no credentials are needed
CURL_FETCH_CREDS=""

#this is the location of the operator catalog image that we pushed to in our Pre-reqs step above. make sure Pods in the openshift-marketplace namespace can pull this image beforehand
OP_CATALOG_IMAGE=your-repo/designated-path/operator-catalog:vX.Y.Z
```

With that in palce, lets deploy:
```
oc process -f operator-registry-template.yaml -p NAME=${NAME} -p MANIFEST_ARCHIVE_URL="${MANIFEST_ARCHIVE_URL}" -p CURL_FETCH_CREDS="${CURL_FETCH_CREDS}" -p IMAGE=${OP_CATALOG_IMAGE} | oc create -f -
```

You should see a Service, CatalogSource, and Deployment (with corresponding Pod) spin up in the `openshift-marketplace`. 
Once the Pod is up and running, go to the OperatorHub menu item in your Openshift UI Console, and you should see your Operator listing there


#### Day 2: Update the Catalog

With day one behind us, and all redhat-operators available in the Openshift 4 cluster , suppose you realize you need to curate the list of Operators a bit. Perhaps there is a newer version of the AMQ Operator out, and you want to update... or, you just want to pair down the list considerably for deployment into a different (STAGE/PROD) Openshift 4 cluster. To do this, we:
1. change the contents of redhat-manifests, and build a new tar.gz file (notice the filename is different with *1.0.1* instead of *1.0.0*)
```
tar zcvf operator-catalog-v1.0.1.tar.gz redhat-manifests
```

2. as before, push the file to your artifact repo (for example, for Artifactory):
```
curl -umyuser:mypassword -T operator-catalog-v1.0.1.tar.gz "http://artifactory-host:<port>/artifactory/ocp-catalog-dev/operator-catalog-v1.0.1.tar.gz"
```

3. If the operator catalog is already running in the target Openshift Cluster, as we deployed in on Day 1, there is no need to delete the CatalogSource/Deployment/Service we created -- just update the Deployment's MANIFEST_ARCHIVE_URL environment variable via CLI or UI Console. The Rolling Deployment will spin up a new pod pointing to our new tar.gz file, and load the new listing. If you're deploying to a new Openshift Cluster where the catalog has not bee deployed yet, just run the same command but pointing to the v1.0.1 archive with 
```
MANIFEST_ARCHIVE_URL=http://artifactory-host:<port>/artifactory/ocp-catalog-dev/operator-catalog-v1.0.1.tar.gz
oc process -f operator-registry-template.yaml -p NAME=${NAME} -p MANIFEST_ARCHIVE_URL="${MANIFEST_ARCHIVE_URL}" -p CURL_FETCH_CREDS="${CURL_FETCH_CREDS}" -p IMAGE=${OP_CATALOG_IMAGE} | oc create -f -
```

Note that to make an Operator Catalog update, we didn't have to build any images -- just a new tar.gz file to point to. 

### OCP4 Operator Catalog Management Utilities (for mirroring images)
For some helpful APIs for managing Operator package manifest tar.gz archives, such as listing all image references in a tar.gz archive, or image mirroring capabilities, see the complementary [OCP4 Operator Catalog Management Utils](https://github.com/ldojo/ocp4-operator-catalog-management-utils) project
