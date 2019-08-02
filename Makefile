.DEFAULT_GOAL := start
CONTAINER_NAME := monostream
LOCAL_DIR := $$HOME/.local/share/code-server
WORKSPACE := $$HOME/workspace
IMAGE_NAME := monostream-server

.PHONY: start stop delete purge restart build build_without_cache

build_without_cache:
	docker build --no-cache -t $(IMAGE_NAME) .

build:
	docker build -t $(IMAGE_NAME) .

start:
	mkdir -p $(LOCAL_DIR)
	mkdir -p $(WORKSPACE)
	# docker run --name $(CONTAINER_NAME) -v /var/run/docker.sock:/var/run/docker.sock -d -p 0.0.0.0:8443:8443 -v "$(LOCAL_DIR):/home/coder/.local/share/code-server:z" -v "$(WORKSPACE):/home/coder/project:z" $(IMAGE_NAME) --allow-http --no-auth
	docker run --name $(CONTAINER_NAME) -v /var/run/docker.sock:/var/run/docker.sock -d -p 0.0.0.0:8443:8443 -v "$(WORKSPACE):/home/coder/project:z" $(IMAGE_NAME) --allow-http --no-auth

stop:
	docker stop $(CONTAINER_NAME)

delete: stop
	docker rm $(CONTAINER_NAME)

purge: delete
	rm -rf $(LOCAL_DIR)

restart:
	docker restart $(CONTAINER_NAME)

reboot: build delete start