FROM registry.redhat.io/openshift4/ose-operator-registry:v4.3 AS builder

FROM registry.access.redhat.com/ubi8/ubi

COPY --from=builder /bin/initializer /bin/initializer
#COPY --from=builder /registry/bundles.db /bundles.db
COPY --from=builder /usr/bin/registry-server /bin/registry-server
COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe

COPY scripts /tmp/scripts

RUN chmod 775 /tmp/scripts/initialize

EXPOSE 50051


#ENTRYPOINT ["/tmp/scripts/initialize", "$EAR_OPERATOR_MANIFESTS_URL"]

CMD ["/tmp/scripts/initialize", "$EAR_OPERATOR_MANIFESTS_URL"]
