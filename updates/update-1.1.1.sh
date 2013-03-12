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
PACKAGES_INSTALL_MASTER="
nova-db-clean
"
PACKAGES_EXCLUDE_COMPUTE="
usbredir
"

function prein_master() {
    # newer python-jinja2 provides python-jinja2-26
    yum -y reinstall python-jinja2 || true
}

source "$(dirname "$0")/functions.sh"
standard_update "$@"
