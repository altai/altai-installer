#!/bin/bash

function is_master() {
    rpm -q python-focus &>/dev/null
}

SERVICES="focus nova-billing-heart nova-billing-os-amqp instance-notifier
          nova-api nova-consoleauth nova-network nova-compute
          nova-novncproxy nova-objectstore nova-scheduler"
PACKAGES="python-focus python-openstackclient-base nova-billing
          openstack-nova-common"

SERVICES=$(for srv in $SERVICES; do if [ -e "/etc/init.d/$srv" ]; then echo $srv; fi; done)
PACKAGES=$(for pkg in $PACKAGES; do if rpm -q $pkg &>/dev/null; then echo $pkg; fi; done)

for srv in odb $SERVICES; do
    service $srv stop
done

if is_master; then
    service odb stop
    yum erase -y odb
    sed -i 's/CONFIGURED_HOSTNAME/CONFIGURED_URL/' /etc/focus/local_settings.py
    yum install -y keystone-ldap
    if ! grep -q LDAP_INTEGRATION /etc/focus/local_settings.py; then
        echo 'LDAP_INTEGRATION = False' >> /etc/focus/local_settings.py
    fi
    yum install -y nova-db-clean
fi

yum install -y $PACKAGES

if rpm -q openstack-nova-compute &>/dev/null; then
    if ! grep -q allow_resize_to_same_host /etc/nova/nova.conf; then
        echo 'allow_resize_to_same_host = true' >> /etc/nova/nova.conf
    fi
fi

sed -i 's/^scheduler_driver\b.*$/# do not oversell RAM\nram_allocation_ratio = 1.0\nscheduler_driver = nova.scheduler.filter_scheduler.FilterScheduler\n/' /etc/nova/nova.conf

for srv in $SERVICES; do
    service $srv start
    chkconfig --add $srv
done
