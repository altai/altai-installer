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
    echo "Usage:   $0  [master|compute]"
    echo "      master  - install controlling node"
    echo "      compute - install compute node"
    exit 1
}

if [ $1 = '--accept-eula' ]; then 
    shift
else 
    cat ./EULA.txt
    read -p "If you agree with the terms, please click y to proceed, otherwise click n to terminate the installation process: " -r -n 1
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    echo
fi
  
if [[ $# -ne 1 || ("$1" != 'master' && "$1" != 'compute') ]]
then
    usage
fi

# set Permissive mode if SELinux is enabled
if selinuxenabled; then
    setenforce 0
fi

# install packages
receipt="${1}-node.json"
altailog="/var/log/altai-install.log"
touch "$altailog"
chmod 600 "$altailog"
./_install.sh "$DIR" "$1" "$receipt" "$altailog" 2>&1 | tee -a "$altailog"

# disable SELinux
if selinuxenabled; then
    sed --follow-symlinks -i 's/SELINUX=.*$/SELINUX=disabled/' /etc/sysconfig/selinux
    echo -e "\033[47m\033[1;31m**************************************************\033[0m"
    echo -e "\033[47m\033[1;31m*\033[0m \033[40m\033[1;31m                                               \033[47m\033[1;31m*\033[0m"
    echo -e "\033[47m\033[1;31m*\033[0m \033[40m\033[1;31m>> \033[5mYou had SELinux enabled on your host!  \033[25m <<  \033[47m\033[1;31m*\033[0m"
    echo -e "\033[47m\033[1;31m*\033[0m \033[40m\033[1;31mAltai cannot work if SELinux is enabled.       \033[47m\033[1;31m*\033[0m"
    echo -e "\033[47m\033[1;31m*\033[0m \033[40m\033[1;31m                                               \033[47m\033[1;31m*\033[0m"
    echo -e "\033[47m\033[1;31m*\033[0m \033[40m\033[1;31mSELinux is now switched to Permissive mode     \033[47m\033[1;31m*\033[0m"
    echo -e "\033[47m\033[1;31m*\033[0m \033[40m\033[1;31mand disabled in /etc/sysconfig/selinux!        \033[47m\033[1;31m*\033[0m"
    echo -e "\033[47m\033[1;31m*\033[0m \033[40m\033[1;31m                                               \033[47m\033[1;31m*\033[0m"
    echo -e "\033[47m\033[1;31m**************************************************\033[0m"
fi

# save version and release
altai_release_file=/etc/altai-release
rpm -q --queryformat '%{VERSION}\n' altai-release > $altai_release_file

exit ${PIPESTATUS[0]} 
