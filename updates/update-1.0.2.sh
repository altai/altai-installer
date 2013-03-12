#!/bin/bash

SERVICES_START_MASTER="
focus
instance-notifier
glance-api
keystone
nova-billing-heart
nova-consoleauth
nova-dns
nova-novncproxy
nova-scheduler
glance-registry
nova-api
nova-billing-os-amqp
nova-compute
nova-network
"
SERVICES_STOP_MASTER="
$SERVICES_START_MASTER
"
PACKAGES_INSTALL_MASTER="
openstack-nova
openstack-glance
openstack-keystone
openstack-noVNC
python-novaclient
python-glanceclient
python-keystoneclient
python-openstackclient-base
instance-notifier
nova-dns
nova-fping-ext
nova-networks-ext
python-focus
nova-billing
"
SERVICES_START_COMPUTE="
nova-compute
"
SERVICES_STOP_COMPUTE="
$SERVICES_START_COMPUTE
"

function prein_common() {
    yum downgrade -y python-amqplib-0.6.1
}

function postin_master() {
    if ! grep -q CONFIGURED_HOSTNAME /etc/focus/local_settings.py; then
        configured_hostname=$(python -c 'import json; c = json.load(open("/opt/altai/master-node.json")); print c.get("master-configured-hostname", "http://%s" % c["master-ip-public"])')
        echo "CONFIGURED_HOSTNAME = '$configured_hostname'" >> /etc/focus/local_settings.py
    fi
    mysql_root_pwd=$(python -c 'import json; c = json.load(open("/opt/altai/master-node.json")); print c["mysql-root-password"]')
    mysql -uroot -p"$mysql_root_pwd" focus < /etc/focus/configured_hostnames.sql
}

source "$(dirname "$0")/functions.sh"
standard_update
