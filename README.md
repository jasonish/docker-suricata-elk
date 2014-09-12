## About

A Docker image with Suricata and the ELK (Elastic Search, Logstash,
Kibana).

## NOTE

Unlike most Docker containers, this one uses host networking.  At this
time it will attempt to bind the following ports:

 - 7777: The web interface to expose Kibana and EveBox
 - 9200: Elastic Search

This is to allow Suricata access to your physical interfaces while
running inside the Docker container.  A more "Docker" approach would
probably be to break this one container into two, one for Suricata,
and one for ELK.

## Running

As this is a Docker container you need to be running Docker on Linux.
Please refer to the Docker documentation at https://docs.docker.com/
for installation help.  Note that if running in a virtual machine you
should allocate at least 2GB of memory.

 - git clone https://github.com/jasonish/docker-suricata-elk.git
 - cd docker-suricata-elk
 - ./launcher start -i INTERFACE

Then assuming your running on your localhost, point your browser at
http://localhost:7200.

The container is completely stateless with all persistent data stored
in ./data.  This includes the Elastic Search database and all log
files.

To get a shell into the running container (may require sudo):

 - ./launcher enter

## Building

If you wish to rebuild the image yourself simply run:

 - make build
