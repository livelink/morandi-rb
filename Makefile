IMAGE_NAME=morandirb
CONTAINER_NAME=morandirb

.PHONY: all run shell stop clean

all: clean build run

build: Dockerfile
	docker buildx build -t ${IMAGE_NAME}:latest . --load

run:
	docker run -it --rm --name ${CONTAINER_NAME} -v ${PWD}:/app ${IMAGE_NAME}:latest bash -c "bundle exec rake compile && bundle exec guard"

shell:
	docker exec -it ${CONTAINER_NAME} /bin/bash

stop:
	docker container stop ${CONTAINER_NAME}

clean:
	docker ps -q --filter name=${CONTAINER_NAME} | grep -q . && docker container stop ${CONTAINER_NAME} || true
	docker image ls -q ${IMAGE_NAME} | grep -q . && docker image rm ${IMAGE_NAME} || true

docs:
	docker run -it --rm --name ${CONTAINER_NAME} -v ${PWD}:/app ${IMAGE_NAME}:latest yard doc lib/morandi.rb
