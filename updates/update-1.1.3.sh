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

function postin_common() {
    # we did not do this for master-only nodes on 1.1.0 update
    if ! grep -q allow_resize_to_same_host /etc/nova/nova.conf; then
        echo 'allow_resize_to_same_host = true' >> /etc/nova/nova.conf
    fi

    if ! grep -q force_resize_to_same_host /etc/nova/nova.conf; then

    local allow_resize_to_same_host=$(/opt/altai/tools/nova-get-flag \
                                      nova.flags allow_resize_to_same_host)
        if [ "$allow_resize_to_same_host" = "True" ] ; then
            sed -i 's/^\(allow_resize_to_same_host.*\)$/\1\nforce_resize_to_same_host = true/' /etc/nova/nova.conf
        fi
    fi
}

source "$(dirname "$0")/functions.sh"
standard_update "$@"
