#! /bin/sh

ARGS=$(getopt -o "i:" -- "$@")
if [ $? -ne 0 ]; then
    exit 1
fi
eval set -- "${ARGS}"

while true; do
    case "$1" in
	-i)
	    SURICATA_INTERFACE=$2
	    shift 2
	    ;;
	--)
	    shift
	    break
	    ;;
    esac
done

# Return the first interface that is not the loopback or the docker interface.
function find_interface() {
    ifconfig -a | egrep -o '^[a-z0-9]+' | grep -v docker | grep -v lo | head -n1
}

if [ -z "${SURICATA_INTERFACE}" ]; then
    SURICATA_INTERFACE=$(find_interface)
    if [ -z "${SURICATA_INTERFACE}" ]; then
	echo "Failed to find interface to run Suricata on. Exiting."
	exit 1
    fi
    echo "No interface specified, will try ${SURICATA_INTERFACE}"
fi
SURICATA_ARGS="--af-packet=${SURICATA_INTERFACE}"
export SURICATA_ARGS

if [ ! -e /data ]; then
    echo "Error: No /data volume provided."
    exit 1
fi

test -e /data/elasticsearch || \
    install -d -o user -g user /data/elasticsearch

# Fix permissions.
if [ "$(id -u user)" != "${HOST_UID}" ]; then
    echo "Setting account user to uid ${HOST_UID}."
    usermod --non-unique --uid ${HOST_UID} user
fi

if [ "$(stat --format %u /data/elasticsearch)" != "$(id -u user)" ]; then
    echo "Fixing permissions: /data/elasticsearch."
    chown -R user:user /data/elasticsearch
fi
if [ "$(stat --format %u /var/log/elasticsearch)" != "$(id -u user)" ]; then
    echo "Fixing permissions: /var/log/elasticsearch."
    chown -R user:user /var/log/elasticsearch
fi

echo -e "\e[36m"
echo "If all goes well, point your browser at http://localhost:7777."
echo "If not running on localhost, its up to you to figure it out."
echo -e "\e[0m"

exec /usr/bin/supervisord -c /etc/supervisord.conf --nodaemon
