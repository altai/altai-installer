#!/bin/bash

function is_master() {
    rpm -q python-focus
}

master_services="focus instance-notifier zabbix-notifier nova-billing-heart nova-billing-os-amqp"
master_packages="python-focus instance-notifier nova-fping-ext python-openstackclient-base-essex zabbix-notifier"

if is_master; then
    for srv in $master_services; do
        service $srv stop
    done
    yum install -y $master_packages
    for srv in $master_services; do
        service $srv start
    done
fi
