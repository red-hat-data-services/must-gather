FROM quay.io/openshift/origin-cli:latest

# copy all collection scripts to /usr/bin
COPY collection-scripts/* /usr/bin/

# RUN chmod +rwx /usr/bin/gather-data-science-pipelines

ENTRYPOINT /usr/bin/gather
