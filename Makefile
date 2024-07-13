# Makefile for building and running Next.js app with Docker

IMAGE_NAME := nextjs-app-deploy
DOCKER_COMPOSE := docker-compose

.PHONY: help build run stop down

help:
	@echo "Available targets:"
	@echo "  build       - Build Docker images"
	@echo "  run         - Run Docker containers"
	@echo "  stop        - Stop Docker containers"
	@echo "  down        - Stop and remove Docker containers"

build:
	$(DOCKER_COMPOSE) build

up:
	$(DOCKER_COMPOSE) up -d

stop:
	$(DOCKER_COMPOSE) stop

down:
	$(DOCKER_COMPOSE) down