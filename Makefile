include .env

.DEFAULT_GOAL=build

volumes:
	@docker volume inspect $(DATA_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DATA_VOLUME_HOST)
	@docker volume inspect $(DB_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DB_VOLUME_HOST)

secrets/postgres.env:
	@echo "Generating postgres password in $@"
	@echo "POSTGRES_PASSWORD=$(shell openssl rand -hex 32)" > $@

secrets/oauth.env:
	@echo "You need to provide Google OAuth Credentials"
	exit 1

check-files: secrets/postgres.env secrets/oauth.env

init:
	docker-compose -f docker-compose-ssl-init.yml build

user:
	docker build -t $(DOCKER_NOTEBOOK_IMAGE) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		user-environ

build: check-files volumes
	docker-compose build

.PHONY: volumes check-files user build
