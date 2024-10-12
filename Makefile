all: build

build:
	@docker compose build

start:
	@docker compose up

stop:
	@docker compose down

restart: stop run

clean: stop
	@docker compose down -v
	@docker compose down --rmi all

re: clean all

.PHONY: build run stop clean
