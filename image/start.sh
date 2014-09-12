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
    install -d -o elasticsearch -g elasticsearch /data/elasticsearch
test -e /var/log/elasticsearch || \
    install -d -o elasticsearch -m 755 /var/log/elasticsearch
test -e /var/log/nginx || mkdir /var/log/nginx
test -e /var/log/suricata || mkdir -p /var/log/suricata

echo -e "\e[36m"
echo "If all goes well, point your browser at http://localhost:7777."
echo "If not running on localhost, its up to you to figure it out."
echo -e "\e[0m"

exec /usr/bin/supervisord -c /etc/supervisord.conf --nodaemon


