#!/bin/bash

cd "$(dirname "$0")"
source "updates/functions.sh"


# make version contain at least 3 components:
# 1 -> 1.0.0
# 1.1 -> 1.1.0
# 1.2.0 -> 1.2.0
# 1.2.4.3 -> 1.2.4.3
function normalize_version() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "${1}.0.0"
    elif [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "${1}.0"
    else
        echo "$1"
    fi
}


function determine_versions() {
    if [ ! -r $release_file ]; then
        OLD_VERSION="1.0.0"
    elif grep -q run_list $release_file; then
        mv $release_file /etc/altai-install-info.json
        OLD_VERSION="1.0.0"
    else
        OLD_VERSION="$(normalize_version $(< $release_file))"
    fi
    NEW_VERSION=$(normalize_version $(rpm -q --queryformat '%{VERSION}\n' altai-installer))
    determine_node_roles
}


function store_version() {
    echo "$1" > $release_file
}


function check_update_script() {
    local script="$updates_dir/update-${1}.sh"
    if [ ! -x "$script" ]; then
        echo "File $script not found or is not executable."
        echo "Possibly corrupted installer."
        exit 1
    fi
}


function build_version_list() {
    UPDATE_PLAN=""
    OLD_VERSION_FOUND=n
    NEW_VERSION_FOUND=n
    check_update_script "$OLD_VERSION"
    while read version release_url; do
        if [ "$version" == "$OLD_VERSION" ]; then
            OLD_VERSION_FOUND=y
        elif [ "$OLD_VERSION_FOUND" == y ]; then
            UPDATE_PLAN="$UPDATE_PLAN
$version $release_url"
            check_update_script "$version"
            if [ "$version" == "$NEW_VERSION" ]; then
                NEW_VERSION_FOUND=y
                break
            fi
        fi
    done < $updates_dir/versions

    if [ "$OLD_VERSION_FOUND" == n ]; then
        echo "Cannot update from $OLD_VERSION to $NEW_VERSION."
        echo "$OLD_VERSION is not a parent version for $NEW_VERSION."
        echo "Please look for another version of Altai."
        exit 1
    fi
    if [ "$NEW_VERSION_FOUND" == n ]; then
        echo "$NEW_VERSION is not found in version list."
        echo "Possibly corrupted installer."
        exit 1
    fi
    echo "Altai will be updated from $OLD_VERSION to $NEW_VERSION."
    echo "Node role(s): $NODE_ROLES"
}


function incremental_update() {
    rpm --erase --nodeps altai-release || true
    "$updates_dir/update-${OLD_VERSION}.sh" stop_services
    local version=''
    for i in $UPDATE_PLAN; do
        if [ -z "$version" ]; then
            version="$i"
            continue
        fi
        local release_url=$i
        echo "Updating to $version"
        rpm -Uvh "$release_url"
        yum clean all
        "$updates_dir/update-${version}.sh" update
        store_version $version
        version=''
    done
    "$updates_dir/update-${NEW_VERSION}.sh" start_services
}


determine_versions

if [ "$NEW_VERSION" != "$OLD_VERSION" ]; then
    tools/validate-conf
    build_version_list
    incremental_update
    echo "Altai is updated"
else
    echo "Altai has been already updated"
fi
