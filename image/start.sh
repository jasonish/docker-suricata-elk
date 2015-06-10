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
	    echo "Will use pcap on interface ${SURICATA_INTERFACE}."
	    shift 2
	    ;;
	--)
	    shift
	    break
	    ;;
    esac
done

if [ -z "${SURICATA_INTERFACE}" ]; then
    echo "Warning: No interface specified, will try eth0."
    SURICATA_INTERFACE=eth0
fi
SURICATA_ARGS="-i ${SURICATA_INTERFACE}"
export SURICATA_ARGS

if [ ! -e /data ]; then
    echo "Error: No /data volume provided."
    exit 1
fi

test -e /data/log || mkdir /data/log
test -e /data/elasticsearch || \
    install -d -o user -g user /data/elasticsearch
test -e /var/log/elasticsearch || \
    install -d -o user -m 755 /var/log/elasticsearch
test -e /var/log/nginx || mkdir /var/log/nginx
test -e /var/log/suricata || mkdir -p /var/log/suricata

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


