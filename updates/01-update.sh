#!/bin/bash

function is_master() {
    rpm -q python-focus &>/dev/null
}

if is_master; then
    sed -i 's/CONFIGURED_HOSTNAME/CONFIGURED_URL/' /etc/focus/local_settings.py

    SERVICES="focus nova-billing-heart nova-billing-os-amqp instance-notifier"
    PACKAGES="python-focus python-openstackclient-base nova-billing keystone-ldap"
    for srv in odb $SERVICES; do
        service $srv stop
    done
    yum erase -y odb
    yum install -y $PACKAGES
    for srv in $SERVICES; do
        service $srv start
        chkconfig --add $srv
    done
fi

if rpm -q openstack-nova-compute &>/dev/null; then
    if ! grep -q allow_resize_to_same_host /etc/nova/nova.conf; then
        echo 'allow_resize_to_same_host = true' >> /etc/nova/nova.conf
        service nova-compute restart
    fi
fi
