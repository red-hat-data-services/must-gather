GATHER_IMG ?= quay.io/$(USER)/must-gather
GATHER_IMG_VERSION ?=dev
IMAGE_BUILDER ?= podman

build-must-gather:
	${IMAGE_BUILDER} build . -f Dockerfile -t ${GATHER_IMG}:${GATHER_IMG_VERSION}

push-must-gather:
	${IMAGE_BUILDER} push ${GATHER_IMG}:${GATHER_IMG_VERSION}

build-and-push-must-gather: build-must-gather push-must-gather
