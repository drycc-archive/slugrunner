SHORT_NAME := slugrunner

export GO15VENDOREXPERIMENT=1

IMAGE_PREFIX ?= drycc

include versioning.mk

SHELL_SCRIPTS = $(wildcard rootfs/bin/*) $(wildcard rootfs/installer/*) $(wildcard rootfs/runner/*) $(wildcard _scripts/*.sh)

# The following variables describe the containerized development environment
# and other build options
DEV_ENV_IMAGE := drycc/go-dev
DEV_ENV_WORK_DIR := /go/src/${REPO_PATH}
DEV_ENV_CMD := docker run --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR} ${DEV_ENV_IMAGE}
DEV_ENV_CMD_INT := docker run -it --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR} ${DEV_ENV_IMAGE}

all: build docker-build docker-push

bootstrap:
	@echo Nothing to do.

docker-build:
	docker build ${DOCKER_BUILD_FLAGS} -t ${IMAGE} -f rootfs/Dockerfile.${STACK} rootfs
	docker tag ${IMAGE} ${MUTABLE_IMAGE}

deploy: docker-build docker-push kube-pod

kube-pod: kube-service
	kubectl create -f ${POD}

kube-secrets:
	- kubectl -s http://172.17.8.102:8080 create -f ${SEC}

secrets:
	perl -pi -e "s|access-key-id: .+|access-key-id: ${key}|g" ${SEC}
	perl -pi -e "s|access-secret-key: .+|access-secret-key: ${secret}|g" ${SEC}
	echo ${key} ${secret}

kube-service: kube-secrets
	- kubectl create -f ${SVC}
	- kubectl create -f manifests/drycc-minio-secretUser.yaml

kube-clean:
	- kubectl delete rc drycc-${SHORT_NAME}-rc

kube-mc:
	kubectl create -f manifests/drycc-mc-pod.yaml

mc:
	docker build ${DOCKER_BUILD_FLAGS} -t ${DRYCC_REGISTRY}drycc/minio-mc:latest mc
	docker push ${DRYCC_REGISTRY}drycc/minio-mc:latest
	perl -pi -e "s|image: [a-z0-9.:]+\/|image: ${DRYCC_REGISTRY}|g" manifests/drycc-mc-pod.yaml

test: test-style test-unit test-functional

test-unit:
	@echo "Implement unit tests in _tests directory"

test-functional:
	@echo "Implement functional tests in _tests directory"

test-style:
	${DEV_ENV_CMD} shellcheck $(SHELL_SCRIPTS)

.PHONY: all bootstrap build docker-compile kube-up kube-down deploy mc kube-mc test test-style test-unit test-functional
