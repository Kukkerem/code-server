.DEFAULT_GOAL := start
CONTAINER_NAME := monostream
LOCAL_DIR := $$HOME/.local/share/code-server
WORKSPACE := $$HOME/workspace
LOCAL_IMAGE_NAME := monostream-server
DOCKER_NAME := kukker
REMOTE_IMAGE_NAME := $(DOCKER_NAME)/code-server

.PHONY: start stop delete purge restart build build_without_cache push start_remote restart_remote set_ssh set_kubectl restart_all_local restart_all_remote config

build_without_cache:
	docker build --no-cache -t $(LOCAL_IMAGE_NAME) --network=host .

build:
	docker build -t $(LOCAL_IMAGE_NAME) --network=host .

prepare:
	mkdir -p $(LOCAL_DIR)
	mkdir -p $(WORKSPACE)
	chmod -R 0777 $(WORKSPACE)

start: prepare
	# docker run --name $(CONTAINER_NAME) -v /var/run/docker.sock:/var/run/docker.sock -d -p 0.0.0.0:8443:8443 -v "$(LOCAL_DIR):/home/coder/.local/share/code-server:z" -v "$(WORKSPACE):/home/coder/project:z" $(IMAGE_NAME) --allow-http --no-auth
	docker run -d --name $(CONTAINER_NAME) --network=host -v /var/run/docker.sock:/var/run/docker.sock -v "$(WORKSPACE):/home/coder/project:z" $(LOCAL_IMAGE_NAME) --allow-http --no-auth

set_ssh:
	docker exec $(CONTAINER_NAME) mkdir -p /home/coder/.ssh
	cat ~/.ssh/id_rsa | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/id_rsa'
	cat ~/.ssh/id_rsa.pub | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/id_rsa.pub'
	cat ~/.ssh/authorized_keys | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/authorized_keys'
	cat ~/.ssh/known_hosts | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/known_hosts'
	docker exec $(CONTAINER_NAME) sudo chmod 0700 /home/coder/.ssh
	docker exec $(CONTAINER_NAME) sudo chmod 0600 /home/coder/.ssh/id_rsa
	docker exec $(CONTAINER_NAME) sudo chown -R coder:coder /home/coder/.ssh

set_kubectl:
	docker exec $(CONTAINER_NAME) mkdir -p /home/coder/.kube
	cat ~/.kube/config | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.kube/config'

config:
	cat ~/.gitconfig | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.gitconfig'

restart_all_local: restart set_ssh set_kubectl config
restart_all_remote: restart_remote set_ssh set_kubectl config

stop:
	docker stop $(CONTAINER_NAME) | true

delete: stop
	docker rm $(CONTAINER_NAME) | true

purge: delete
	rm -rf $(LOCAL_DIR) | true

restart: purge start

reboot: build delete start

push:
	docker login
	docker tag $(LOCAL_IMAGE_NAME) $(REMOTE_IMAGE_NAME)
	docker push $(REMOTE_IMAGE_NAME):latest

start_remote: prepare
	docker pull $(REMOTE_IMAGE_NAME)
	docker run -d --name $(CONTAINER_NAME) --network=host -v /var/run/docker.sock:/var/run/docker.sock -v "$(WORKSPACE):/home/coder/project:z" $(REMOTE_IMAGE_NAME) --allow-http --no-auth

restart_remote: purge start_remote
