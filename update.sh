#!/bin/bash

cd "$(dirname "$0")"
source "updates/functions.sh"

determine_versions

if [ "$NEW_VERSION" != "$OLD_VERSION" ]; then
    build_version_list
    determine_node_roles
    check_updatable
    incremental_update
    store_version "$NEW_VERSION"
    echo "Altai is updated"
else
    echo "Altai has been already updated"
fi
