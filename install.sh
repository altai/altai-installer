#!/bin/bash
#    Altai Private Cloud 
#    Copyright (C) GridDynamics Openstack Core Team, GridDynamics
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation, either version 2.1 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

DIR=$(readlink -f $(dirname $0))


function usage() {
    echo "Usage:   $0  [--accept-eula] [-f|--force]  [master|compute]"
    echo "      master  - install controlling node (default)"
    echo "      compute - install compute node"
    exit 1
}


function die() {
    echo "$@" >&2
    exit 1
}


function error_start() {
    echo
    echo -e "\033[1;31m********************************************************************************"
}


function error_end() {
    echo -e "********************************************************************************\033[0m"
    echo
}


function check_ports() {
    NETSTAT=$(netstat -anp | awk '/^(tcp.*LISTEN|udp)/ { print $1 "\t" $4 "\t" $(NF) }')
    TCP_PLAN="80	nginx
3333	nova-objectstore
5000	keystone-all
6080	novnc
8080	focus
8773	nova-api
8774	nova-api
8775	nova-api
8776	nova-api
8787	nova-billing-heart
9191	glance-registry
9292	glance-api
15353	nova-dns
35357	keystone-all
6343	hsflow
16509	libvirtd"

    UDP_PLAN="53	dnsmasq
6343    hsflow
123	ntpd"

    TCP_MASK="$(echo "$TCP_PLAN" | awk 'BEGIN { ORS="|";} { print $1 }')"
    TCP_MASK="${TCP_MASK%|}"
    UDP_MASK="$(echo "$UDP_PLAN" | awk 'BEGIN { ORS="|";} { print $1 }')"
    UDP_MASK="${UDP_MASK%|}"
    ALTAI_BUSY_PORTS=$(echo "$NETSTAT" | grep -E "^(tcp.*:($TCP_MASK)|udp.*:($UDP_MASK))\b")

    if [ -n "$ALTAI_BUSY_PORTS" ]; then
        error_start
        echo "Some ports needed by Altai services are already in use:"
        echo "$ALTAI_BUSY_PORTS"
        error_end
        if [ $force_install == y ]; then
            return
        fi
        read -p "Please click y to proceed, otherwise click n to terminate the installation process: " -r -n 1
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}


function get_param() {
    receipt="$receipt" python -c 'import json; import os;
print json.load(open(os.environ["receipt"]))["'$1'"]' ||
        die "cannot read parameter $1"
}


function check_interface() {
    iface=$(get_param "projects-interface") || exit $?
    err=$(ifconfig $iface 2>&1 >/dev/null) || {
        error_start
        echo "$err"
        echo "Please check projects-interface parameter in $receipt"
        error_end
        if [ $force_install == n ]; then
            exit 1
        fi
    }
}


function check_ip_exists() {
    local ip_param=$(get_param "$1") || exit $?
    /sbin/ip addr show | grep -q "inet $ip_param\>" || {
        error_start
        echo "This IP does not exist in the system: $1 = $ip_param"
        error_end
        exit 1
    }
}


function check_ips() {
    set -E
    local run_list="$(get_param run_list)"
    if [[ "$run_list" =~ .*master-node.* ]]; then
        check_ip_exists "master-ip-private"
        check_ip_exists "master-ip-public"
    fi
    if [[ "$run_list" =~ .*compute-node.* ]]; then
        check_ip_exists "compute-ip-private"
    fi
    set +E
}

function check_receipt() {
    if [ ! -r "$receipt" ]; then
        die "$receipt is not found"
    fi
}

function check_management_network() {
    m_net=$(get_param "management-network") || {
        error_start
        echo "Please check and specify management-network parameter in $receipt"
        error_end
        if [ $force_install == n ]; then
            exit 1
        fi
    }

}

accept_eula=n
force_install=n
install_mode="master"

for arg in "$@"; do
    case "$arg" in
        --accept-eula)
            accept_eula=y
            ;;
        master|compute)
            install_mode="$arg"
            ;;
        -f|--force)
            force_install=y
            ;;
        *)
            usage
            ;;
    esac
done

if [ $accept_eula == n ]; then
    cat ./EULA.txt
    read -p "If you agree with the terms, please click y to proceed, otherwise click n to terminate the installation process: " -r -n 1
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# set Permissive mode if SELinux is enabled
if selinuxenabled; then
    setenforce 0
fi

# install packages
receipt="${install_mode}-node.json"
check_receipt
check_ports
check_interface
check_ips
check_management_network
altailog="/var/log/altai-install.log"
touch "$altailog"
chmod 600 "$altailog"
./_install.sh "$DIR" "$install_mode" "$receipt" "$altailog" 2>&1 | tee -a "$altailog"

# disable SELinux
if selinuxenabled; then
    sed --follow-symlinks -i 's/SELINUX=.*$/SELINUX=disabled/' /etc/sysconfig/selinux
    error_start
    echo "You had SELinux enabled on your host!"
    echo "Altai cannot work if SELinux is enabled. SELinux is now switched"
    echo "to Permissive mode and disabled in /etc/sysconfig/selinux!"
    error_end
fi

# save version and release
altai_release_file=/etc/altai-release
rpm -q --queryformat '%{VERSION}\n' altai-release > $altai_release_file

exit ${PIPESTATUS[0]} 
