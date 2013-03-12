#!/bin/bash

SERVICES_START_MASTER="
focus
nova-billing-heart
nova-billing-os-amqp
instance-notifier
nova-api
nova-consoleauth
nova-dns
nova-network
nova-novncproxy
nova-objectstore
nova-scheduler
"
SERVICES_STOP_MASTER="
$SERVICES_START_MASTER
odb
"
SERVICES_START_COMPUTE="
nova-compute
"
SERVICES_STOP_COMPUTE="
$SERVICES_START_COMPUTE
"

PACKAGES_INSTALL_MASTER="
python-focus
python-openstackclient-base
nova-billing
nova-dns
openstack-nova-common

keystone-ldap
"
PACKAGES_ERASE_MASTER="
odb
"

function postin_common() {
    sed -i 's/^scheduler_driver\b.*$/# do not oversell RAM\nram_allocation_ratio = 1.0\nscheduler_driver = nova.scheduler.filter_scheduler.FilterScheduler\n/' /etc/nova/nova.conf
}

function postin_master() {
    sed -i '/^network_driver\b/d' /etc/nova/nova.conf
    echo 'network_driver = nova_dns.nova_network_driver.NovaDnsNetworkDriver' >> /etc/nova/nova.conf
    sed -i 's/CONFIGURED_HOSTNAME/CONFIGURED_URL/' /etc/focus/local_settings.py
    if ! grep -q LDAP_INTEGRATION /etc/focus/local_settings.py; then
        echo 'LDAP_INTEGRATION = False' >> /etc/focus/local_settings.py
    fi
}

function postin_compute() {
    if ! grep -q allow_resize_to_same_host /etc/nova/nova.conf; then
        echo 'allow_resize_to_same_host = true' >> /etc/nova/nova.conf
    fi
}

source "$(dirname "$0")/functions.sh"
standard_update
