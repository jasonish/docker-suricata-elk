all: build

build:
	docker build -t jasonish/suricata-elk .

docker-remove-containers:
	docker ps -a -q | xargs docker rm

docker-remove-images:
	docker images -a -q | xargs docker rmi
