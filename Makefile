include .env

.DEFAULT_GOAL=build

volumes:
	@podman volume inspect $(DATA_VOLUME_HOST) >/dev/null 2>&1 || podman volume create $(DATA_VOLUME_HOST)
	@podman volume inspect $(DB_VOLUME_HOST) >/dev/null 2>&1 || podman volume create $(DB_VOLUME_HOST)

secrets/postgres.env:
	@echo "Generating postgres password in $@"
	@echo "POSTGRES_PASSWORD=$(shell openssl rand -hex 32)" > $@

secrets/oauth.env:
	@echo "You need to provide Google OAuth Credentials"
	exit 1

hub-build:
	podman build -f containerfile -t jupyterhub-hub \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		hub

user-build:
	podman build -f containerfile -t $(DOCKER_NOTEBOOK_IMAGE) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		user

dev-build: volumes secrets/postgres.env hub-build user-build
	podman build -f containerfile -t jupyterhub-rp-dev \
		--build-arg DOMAIN_NAME=$(DOMAIN_NAME) \
		reverseproxy/dev

dev: dev-build
	podman play kube dev.yaml

ssl-init-build:
	podman build -f containerfile --build-arg DOMAIN_NAME=$(DOMAIN_NAME) -t jupyterhub-ssl-init:latest reverseproxy/ssl-init 

ssl-init: ssl-init-build
	./ssl-init.sh

prod-build: volumes secrets/postgres.env secrets/oauth.env hub-build user-build

prod: prod-build
	podman play kube prod.yaml

clean:

.PHONY: volumes hub-build user-build dev-build dev ssl-init-build ssl-init prod-build prod clean
