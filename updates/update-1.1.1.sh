#!/bin/bash

PACKAGES_INSTALL_MASTER="
nova-db-clean
"

source "$(dirname "$0")/functions.sh"
standard_update
