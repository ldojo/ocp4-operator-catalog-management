ARG OPERATOR_REGISTRY_BASE_IMAGE=registry.redhat.io/openshift4/ose-operator-registry:v4.3
ARG UBI_OR_BASE_IMAGE=registry.redhat.io/ubi8
FROM ${OPERATOR_REGISTRY_BASE_IMAGE} AS builder

FROM ${UBI_OR_BASE_IMAGE}

LABEL maintainer="Lev Shulman <lshulman@redhat.com>"


COPY --from=builder /bin/initializer /bin/initializer
COPY --from=builder /usr/bin/registry-server /bin/registry-server
COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe

COPY scripts /opt/scripts

RUN chmod a+x /opt/scripts/* && yum install wget -y && \
   wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/local/bin/jq && \
   chmod +x /usr/local/bin/jq 

EXPOSE 50051


ENTRYPOINT ["/opt/scripts/initialize", "$MANIFEST_ARCHIVE_URL"]
