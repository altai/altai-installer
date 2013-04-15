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
qemu-kvm
qemu-img
vgabios
"

function postin_common() {
    echo 'osapi_compute_extension = nova_userinfo.userinfo.UserInfo
block_migration_flag = VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER, VIR_MIGRATE_NON_SHARED_INC, VIR_MIGRATE_LIVE
libvirt_inject_partition = -1' >> /etc/nova/nova.conf
}

source "$(dirname "$0")/functions.sh"
standard_update "$@"
