GATHER_IMG ?= must-gather
IMAGE_BUILDER ?= docker

build-must-gather:
	${IMAGE_BUILDER} build . -t ${GATHER_IMG}

push-must-gather:
	${IMAGE_BUILDER} push ${GATHER_IMG}

build-and-push-must-gather: build-must-gather push-must-gather
