#!/bin/bash -e

local_path=$(dirname $0)
nova_get_flag="$(readlink -f "$local_path/../../tools/nova-get-flag")"
update_libvirt_xml="$local_path/update-libvirt-xml"

log () { 
    printf "%s\t***\t%s\n" "$(date +[%FT%T%:z])" "$1" 
}


log "Downgrading QEMU packages"
yum shell -y --disablerepo='*' --enablerepo='base,updates,altai-*' \
    "$local_path/qemu-downgrade.yum-shell"


# after changing qemu binary, libvirtd should re-read its capabilities:
service libvirtd restart

instances_path="$("$nova_get_flag" nova.compute.manager instances_path)"

log "Updating instances configuration"
for instnace_dir in "$instances_path"/instance-*; do
    "$update_libvirt_xml" "$instnace_dir/libvirt.xml" || true
    EDITOR="$update_libvirt_xml" virsh edit "$(basename $instnace_dir)"
done

