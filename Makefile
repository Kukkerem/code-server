DEFAULT_GOAL := start
CONTAINER_NAME := monostream
LOCAL_DIR := $$HOME/.local/share/code-server
WORKSPACE := $$HOME/workspace
LOCAL_IMAGE_NAME := monostream-server
DOCKER_NAME := kukker
SERVICE_NAME := code-server
REMOTE_IMAGE_NAME := $(DOCKER_NAME)/$(SERVICE_NAME)

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
	docker run -d --name $(CONTAINER_NAME) --network=host -v /var/run/docker.sock:/var/run/docker.sock --security-opt seccomp=unconfined -v "$(WORKSPACE):/home/coder/project:z" $(LOCAL_IMAGE_NAME) --host 0.0.0.0 --cert

set_ssh:
	docker exec $(CONTAINER_NAME) mkdir -p /home/coder/.ssh
	cat ~/.ssh/id_rsa | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/id_rsa'
	cat ~/.ssh/config | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/config' | true
	cat ~/.ssh/id_rsa.pub | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/id_rsa.pub'
	cat ~/.ssh/authorized_keys | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/authorized_keys'
	cat ~/.ssh/known_hosts | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.ssh/known_hosts'
	docker exec $(CONTAINER_NAME) chmod 0700 /home/coder/.ssh
	docker exec $(CONTAINER_NAME) chmod 0600 /home/coder/.ssh/id_rsa
	docker exec $(CONTAINER_NAME) chmod 0600 /home/coder/.ssh/config | true
	docker exec $(CONTAINER_NAME) chown -R coder:coder /home/coder/.ssh

set_kubectl:
	docker exec $(CONTAINER_NAME) mkdir -p /home/coder/.kube
	cat ~/.kube/config | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.kube/config'

config:
	cat ~/.gitconfig | docker exec -i $(CONTAINER_NAME) sh -c 'cat > /home/coder/.gitconfig'
	docker exec $(CONTAINER_NAME) go get -u github.com/ramya-rao-a/go-outline

restart_all_local: restart set_ssh set_kubectl config
restart_all_remote: restart_remote set_ssh set_kubectl config

stop:
	docker stop $(CONTAINER_NAME) | true

delete: stop
	docker rm $(CONTAINER_NAME) --volumes | true

purge: delete
	rm -rf $(LOCAL_DIR) | true

restart: purge start

reboot: build delete start

push:
	docker login
	docker tag $(LOCAL_IMAGE_NAME) $(REMOTE_IMAGE_NAME)
	docker push $(REMOTE_IMAGE_NAME):latest

pull:
	docker pull $(REMOTE_IMAGE_NAME)

start_remote: prepare pull
	docker run -d --name $(CONTAINER_NAME) --network=host --security-opt seccomp=unconfined -v /var/run/docker.sock:/var/run/docker.sock -v "$(WORKSPACE):/home/coder/project:z" -e PASSWORD=1234 $(REMOTE_IMAGE_NAME) --host 0.0.0.0 --cert

restart_remote: purge start_remote

swarm_start: prepare pull
	docker stack deploy --compose-file docker-compose.yml code-server

swarm_upgrade: pull
	docker service update --force --image $(REMOTE_IMAGE_NAME) code-server_server

swarm_delete:
	-docker stack rm code-server

swarm_config:
	$(eval SWARM_CONTAINER_NAME := $(shell docker ps -q -f name=$(SERVICE_NAME)))
	@echo $(SWARM_CONTAINER_NAME)

	$(MAKE) CONTAINER_NAME=$(SWARM_CONTAINER_NAME) set_ssh
	$(MAKE) CONTAINER_NAME=$(SWARM_CONTAINER_NAME) set_kubectl
	$(MAKE) CONTAINER_NAME=$(SWARM_CONTAINER_NAME) config
