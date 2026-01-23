FROM docker.io/alpine/git AS upstream
# Current main SHA (2025-01-23): cea9e829eb920c0d45b322a9c60e9cd67970c9e3
ARG MUST_GATHER_BRANCH=main
RUN git clone --depth 1 --branch ${MUST_GATHER_BRANCH} https://github.com/openshift/must-gather.git /upstream


FROM quay.io/openshift/origin-cli:4.20
# copy all local collection scripts to /usr/bin
COPY collection-scripts/* /usr/bin/
# copy upstream infrastructure gather scripts
COPY --from=upstream \
    /upstream/collection-scripts/gather_istio \
    /upstream/collection-scripts/gather_metallb \
    /upstream/collection-scripts/gather_sriov \
    /usr/bin/
RUN chmod +x /usr/bin/gather_*
ENTRYPOINT ["/usr/bin/gather"]
