# current latest is point to 4.20.0
FROM quay.io/openshift/origin-must-gather:4.21.0

# Install kubectl for xKS environments
ARG KUBECTL_VERSION=v1.31.4
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# copy original gather from base image to gather_original
RUN mv /usr/bin/gather /usr/bin/gather_original

# copy all collection scripts to /usr/bin
COPY collection-scripts /usr/bin

ENTRYPOINT ["/usr/bin/gather"]
