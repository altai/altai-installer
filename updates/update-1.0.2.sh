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
PACKAGES_EXCLUDE_COMPUTE="
usbredir
qemu-kvm
qemu-img
vgabios
"

function prein_common() {
    yum -y downgrade python-amqplib-0.6.1
}

function prein_master() {
    # newer python-jinja2 provides python-jinja2-26
    yum -y reinstall python-jinja2 || true
}

function postin_master() {
    if ! grep -q CONFIGURED_HOSTNAME /etc/focus/local_settings.py; then
        configured_hostname=$(python -c 'import json; c = json.load(open("/opt/altai/altai-node.json")); print c.get("master-configured-hostname", "http://%s" % c["master-ip-public"])')
        echo "CONFIGURED_HOSTNAME = '$configured_hostname'" >> /etc/focus/local_settings.py
    fi
    mysql_root_pwd=$(python -c 'import json; c = json.load(open("/opt/altai/altai-node.json")); print c["mysql-root-password"]')
    mysql -uroot -p"$mysql_root_pwd" focus < /etc/focus/configured_hostnames.sql
}

source "$(dirname "$0")/functions.sh"
standard_update "$@"
