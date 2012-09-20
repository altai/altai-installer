#!/bin/bash

release_file=/etc/altai-release

if [ ! -r $release_file ]; then
    old_release="1.0.0"
else
    old_release="$(< $release_file)"
fi

new_release=$(rpm -q --queryformat '%{VERSION}\n' altai-release)

if [ "$new_release" != "$old_release" ]; then
    cd "$(dirname "$0")/updates"
    for script in *; do
        if [ -x $script ]; then
            echo "executing $script"
            ./$script
        fi
    done
    echo "$new_release" > $release_file
    echo "altai is updated"
else
    echo "altai has been already updated"
fi
