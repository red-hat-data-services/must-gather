# current latest is point to 4.16.0
FROM quay.io/openshift/origin-must-gather:4.20.0

# copy original gather from base image to gather_original
RUN mv /usr/bin/gather /usr/bin/gather_original

# copy all collection scripts to /usr/bin, including gather
COPY collection-scripts/* /usr/bin/

ENTRYPOINT ["/usr/bin/gather"]

