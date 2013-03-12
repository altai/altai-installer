#!/bin/bash

SERVICES_START_MASTER="
nova-api
nova-consoleauth
nova-network
nova-novncproxy
nova-objectstore
nova-scheduler
"
SERVICES_STOP_MASTER="
$SERVICES_START_MASTER
"
SERVICES_START_COMPUTE="
nova-compute
"
SERVICES_STOP_COMPUTE="
$SERVICES_START_COMPUTE
"
PACKAGES_INSTALL_MASTER="
openstack-nova-api
nova-db-clean
"
PACKAGES_INSTALL_COMPUTE="
openstack-nova-compute
"

source "$(dirname "$0")/functions.sh"
standard_update
