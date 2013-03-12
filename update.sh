#!/bin/bash


# make version contain at least 3 components:
# 1 -> 1.0.0
# 1.1 -> 1.1.0
# 1.2.0 -> 1.2.0
# 1.2.4.3 -> 1.2.4.3
function normalize_version() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "${1}.0.0"
    elif [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "${1}.0"
    else
        echo "$1"
    fi
}


release_file=/etc/altai-release

if [ ! -r $release_file ]; then
    old_release="1.0.0"
else
    old_release="$(normalize_version $(< $release_file))"
fi

new_release=$(normalize_version $(rpm -q --queryformat '%{VERSION}\n' altai-release))

if [ "$new_release" != "$old_release" ]; then
    cd "$(dirname "$0")/updates"

    middle=""
    found=n
    while read version; do
        if [ "$version" == "v$old_release" ]; then
            found=y
        elif [ "$version" == "v$new_release" ]; then
            break
        elif [ "$found" == y ]; then
            middle="$middle$version, "
        fi
    done < versions

    if [ "$found" == n ]; then
        echo "Cannot update from v$old_release to v$new_release."
        echo "v$old_release is not a parent version for v$new_release."
        echo "Please look for another version of Altai."
        exit 1
    fi

    if [ -n "$middle" ]; then
        echo "Cannot update from v$old_release to v$new_release."
        echo "Please consequently update to ${middle}v$new_release."
        exit 1
    fi

    for script in update-v$new_release-*; do
        if [ -x $script ]; then
            echo "executing $script"
            ./$script
        fi
    done
    echo "$new_release" > $release_file
    echo "Altai is updated"
else
    echo "Altai has been already updated"
fi
