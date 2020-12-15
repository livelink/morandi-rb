IMAGE_NAME=morandirb
CONTAINER_NAME=morandirb

.PHONY: all run shell stop clean

all: clean build run

build: Dockerfile
	docker build -t ${IMAGE_NAME}:latest .

run:
	docker run -it --rm --name ${CONTAINER_NAME} -v ${PWD}:/app ${IMAGE_NAME}:latest

shell:
	docker exec -it ${CONTAINER_NAME} /bin/bash

stop:
	docker container stop ${CONTAINER_NAME}

clean:
	docker ps -q --filter name=${CONTAINER_NAME} | grep -q . && docker container stop ${CONTAINER_NAME} || exit 0
	docker image ls -q ${IMAGE_NAME} | grep -q . && docker image rm ${IMAGE_NAME} || exit 0
