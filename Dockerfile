ARG OPERATOR_REGISTRY_BASE_IMAGE=registry.redhat.io/openshift4/ose-operator-registry:v4.3
ARG UBI_OR_BASE_IMAGE=registry.access.redhat.com/ubi8/ubi

FROM ${OPERATOR_REGISTRY_BASE_IMAGE} AS builder

FROM ${UBI_OR_BASE_IMAGE}

LABEL maintainer="Lev Shulman <lshulman@redhat.com>"

COPY --from=builder /bin/initializer /bin/initializer
#COPY --from=builder /registry/bundles.db /bundles.db
COPY --from=builder /usr/bin/registry-server /bin/registry-server
COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe

COPY scripts /tmp/scripts

RUN chmod 775 /tmp/scripts/initialize

EXPOSE 50051


#ENTRYPOINT ["/tmp/scripts/initialize", "$EAR_OPERATOR_MANIFESTS_URL"]

CMD ["/tmp/scripts/initialize", "$EAR_OPERATOR_MANIFESTS_URL"]
