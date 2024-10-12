all: build

build:
        @mkdir -p ./certs
        @openssl genrsa -out ./certs/rcs.key 2048
        @openssl req -new -x509 -key ./certs/rcs.key -out ./certs/rcs.crt -days 365 -subj "/C=US/ST=State/L=City/O=Company/OU=Org/CN=localhost"
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
