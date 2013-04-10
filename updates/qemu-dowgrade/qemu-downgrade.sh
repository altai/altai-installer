#!/bin/bash -e

nova_get_flag="$(readlink -f "$(dirname $0)/../../tools/nova-get-flag")"
update_libvirt_xml="$(dirname $0)/update-libvirt-xml"

log () { 
    printf "%s\t***\t%s\n" "$(date +[%FT%T%:z])" "$1" 
}


# 1. Packages manipulation
log("Downgrading QEMU packages")
yum shell -y --disablerepo='*' --enablerepo='base,updates,altai-*' \
    "$LOCAL_PATH/downgrade-qemu.yum-shell" 


local instances_path="$("$nova_get_flag" nova.compute.manager instances_path)"

log("Updating instances configuration")
for instnace_dir in "$instances_path"/instance-*; do
    "$update_libvirt_xml" "$instnace_dir/libvirt.xml" || true
    EDITOR="$update_libvirt_xml" virsh edit "$(dirname $instnace_dir)"
done

