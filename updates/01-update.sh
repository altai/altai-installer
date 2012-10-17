#!/bin/bash

function is_master() {
    rpm -q python-focus &>/dev/null
}

master_services="focus instance-notifier
glance-api       keystone  nova-billing-heart    nova-consoleauth  nova-dns nova-novncproxy   nova-scheduler
glance-registry  nova-api  nova-billing-os-amqp  nova-compute  nova-network"

master_packages="openstack-nova openstack-glance openstack-keystone openstack-noVNC 
python-novaclient python-glanceclient python-keystoneclient
python-openstackclient-base
instance-notifier nova-dns nova-fping-ext nova-networks-ext python-focus
nova-billing"

yum downgrade -y python-amqplib-0.6.1

if is_master; then
    for srv in $master_services; do
        service $srv stop
    done
    yum install -y $master_packages
    for srv in $master_services; do
        service $srv start
    done
else
    service nova-compute stop
    yum install -y openstack-nova-compute
    service nova-compute start
fi
