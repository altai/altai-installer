#!/bin/bash

SERVICES_COMPUTE="
nova-compute
"
SERVICES_MASTER="
focus
zabbix-notifier
instance-notifier
nova-billing-heart
nova-billing-os-amqp
nova-dns
odb
glance-api
glance-registry
keystone
nova-novncproxy
nova-api
nova-consoleauth
nova-network
nova-objectstore
nova-scheduler
"

function postin_compute() {
    compute_ip_private=$(python -c 'import json; print json.load(open("/opt/altai/altai-node.json"))["compute-ip-private"]')
    sed -i "s/vncserver_proxyclient_address.*/vncserver_proxyclient_address = $compute_ip_private/" /etc/nova/nova.conf
}


source "$(dirname "$0")/functions.sh"
standard_update "$@"
