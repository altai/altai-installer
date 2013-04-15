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
keystone-ldap
"
PACKAGES_ERASE_MASTER="
odb
"
PACKAGES_EXCLUDE_COMPUTE="
usbredir
qemu-kvm
qemu-img
vgabios
"

function prein_master() {
    # newer python-jinja2 provides python-jinja2-26
    yum -y reinstall python-jinja2 || true
}

function postin_common() {
    sed -i 's/^scheduler_driver\b.*$/# do not oversell RAM\nram_allocation_ratio = 1.0\nscheduler_driver = nova.scheduler.filter_scheduler.FilterScheduler\n/' /etc/nova/nova.conf
}

function postin_master() {
    sed -i '/^network_driver\b/d' /etc/nova/nova.conf
    echo 'network_driver = nova_dns.nova_network_driver.NovaDnsNetworkDriver' >> /etc/nova/nova.conf
    # dnsmasq processes will be restarted by nova-network with new arguments
    killall dnsmasq
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
standard_update "$@"
