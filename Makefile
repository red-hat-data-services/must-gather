GATHER_IMG ?= must-gather
GATHER_IMG_VERSION ?= stable
IMAGE_BUILDER ?= podman

build-must-gather:
	${IMAGE_BUILDER} build . -t ${GATHER_IMG}:${GATHER_IMG_VERSION}

push-must-gather:
	${IMAGE_BUILDER} push ${GATHER_IMG}

build-and-push-must-gather: build-must-gather push-must-gather
