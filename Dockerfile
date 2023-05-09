FROM quay.io/openshift/origin-cli:latest

# copy all collection scripts to /usr/bin
COPY collection-scripts/* /usr/bin/

RUN chmod +x /usr/bin/gather-data-science-pipelines
USER 10001
ENTRYPOINT /usr/bin/gather
