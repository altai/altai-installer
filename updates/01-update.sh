#!/bin/bash

function is_master() {
    rpm -q python-focus &>/dev/null
}

if is_master; then
    service odb stop
    service focus stop
    yum erase -y odb
    yum install -y python-focus
    service focus start
    chkconfig --add focus
fi
