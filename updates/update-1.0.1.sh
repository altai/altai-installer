#!/bin/bash

SERVICES_START_MASTER="
focus
instance-notifier
zabbix-notifier
nova-billing-heart
nova-billing-os-amqp
"
SERVICES_STOP_MASTER="
$SERVICES_START_MASTER
"
PACKAGES_INSTALL_MASTER="
python-focus
instance-notifier
nova-fping-ext
python-openstackclient-base-essex
zabbix-notifier
"
PACKAGES_ERASE_MASTER="
"
SERVICES_START_COMPUTE="
nova-compute
"
SERVICES_STOP_COMPUTE="
$SERVICES_START_COMPUTE
"

function postin_common() {
    mv /etc/altai-release /etc/altai-install-info.json
}


function postin_compute() {
    compute_ip_private=$(python -c 'import json; print json.load(open("/etc/altai-install-info.json"))["compute-ip-private"]')
    sed -i "s/vncserver_proxyclient_address.*/vncserver_proxyclient_address = $compute_ip_private/" /etc/nova/nova.conf
}


source "$(dirname "$0")/functions.sh"
standard_update
