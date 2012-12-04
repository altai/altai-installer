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
    if ! grep -q CONFIGURED_HOSTNAME /etc/focus/local_settings.py; then
        configured_hostname=$(python -c 'import json; c = json.load(open("/opt/altai/master-node.json")); print c.get("master-configured-hostname", "http://%s" % c["master-ip-public"])')
        echo "CONFIGURED_HOSTNAME = '$configured_hostname'" >> /etc/focus/local_settings.py
    fi
    if [[ $(grep INVITATIONS_DATABASE_URI /etc/focus/local_settings.py) =~ .*//([^:]+):([^@]+)@([^/]+)/.* ]]
        mysql -u"${BASH_REMATCH[1]}" -p"${BASH_REMATCH[2]}" -h"${BASH_REMATCH[3]}" focus < /etc/focus/configured_hostnames.sql
    else
        echo "Please apply run /etc/focus/configured_hostnames.sql for focus invitations database"
    fi
    for srv in $master_services; do
        service $srv start
        chkconfig --add $srv
    done
else
    service nova-compute stop
    yum install -y openstack-nova-compute
    service nova-compute start
    chkconfig --add nova-compute
fi
