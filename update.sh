#!/bin/bash

cd "$(dirname "$0")"
source "updates/functions.sh"

determine_versions

if [ "$NEW_VERSION" != "$OLD_VERSION" ]; then
    build_version_list
    check_updatable
    determine_node_roles
    incremental_update
    store_version
    echo "Altai is updated"
else
    echo "Altai has been already updated"
fi
