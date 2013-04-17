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

function postin_master() {
    # NOTE(imelnikov): see nova-dns change I3f7f4736ceb6cdb0a7a0241e99db45f3c57da7d8
    mysql_root_password=$(python -c 'import json; print json.load(open("/opt/altai/altai-node.json"))["mysql-root-password"]')
    mysql -u root --password="$mysql_root_password" dns -e 'DROP INDEX nametype_index ON records;' || true
}

source "$(dirname "$0")/functions.sh"
standard_update "$@"
