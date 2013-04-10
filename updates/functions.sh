set -e

release_file=/etc/altai-release
altai_installer_dir=/opt/altai
tools_dir=$altai_installer_dir/tools
updates_dir=$altai_installer_dir/updates


function has_role() {
    [[ "$NODE_ROLES" =~ .*${1}.* ]]
}


function determine_node_roles() {
    NODE_ROLES="$($tools_dir/node-roles)"
}


function aggregate_variables() {
    local VARIABLES="
        SERVICES
        PACKAGES_INSTALL
        PACKAGES_ERASE
        PACKAGES_EXCLUDE
    "
    for var in $VARIABLES; do
        eval "$var=''"
        local role_var
        if has_role master; then
            role_var="${var}_MASTER"
            eval "$var='${!var} ${!role_var}'"
        fi
        if has_role compute; then
            role_var="${var}_COMPUTE"
            eval "$var='${!var} ${!role_var}'"
        fi
        local uniq_var=$(echo ${!var} | sed 's/ /\n/g' | sort -u)
        eval "$var='$uniq_var'"
    done
}


function run_if_exists() {
    local name="$1"
    if [ "$(type -t $name)" == "function" ]; then
        echo "Executing $name"
        "$name"
    fi
}


function do_stop_services() {
    if [ -n "$SERVICES" ]; then
        echo "Stopping services:" $SERVICES
        for srv in $SERVICES; do
            # Don't be afraid of non-LFS compliant scripts
            service $srv stop || true
        done
    fi
}


function do_start_services() {
    if [ -n "$SERVICES" ]; then
        echo "Starting services:" $SERVICES
        for srv in $SERVICES; do
            service $srv start
            chkconfig --add $srv
        done
    fi
}


# 1. Erase required packages
# 2. Run preinstall
# 3. Install required packages
# 4. Run postinstall
function do_update() {
    if [ -n "$PACKAGES_ERASE" ]; then
        echo "Erasing packages:" $PACKAGES_ERASE
        yum erase -y $PACKAGES_ERASE
    fi

    run_if_exists prein_common
    if has_role master; then
        run_if_exists prein_master
    fi
    if has_role compute; then
        run_if_exists prein_compute
    fi
    if [ -n "$PACKAGES_EXCLUDE" ]; then
        PACKAGES_EXCLUDE="--exclude=$(echo $PACKAGES_EXCLUDE | sed 's/ /,/g')"
    fi
    yum -y --disablerepo='*' --enablerepo='base,updates,altai-*' --skip-broken $PACKAGES_EXCLUDE upgrade
    if [ -n "$PACKAGES_INSTALL" ]; then
        echo "Installing packages:" $PACKAGES_INSTALL
        yum install -y $PACKAGES_INSTALL
    fi

    run_if_exists postin_common
    if has_role master; then
        run_if_exists postin_master
    fi
    if has_role compute; then
        run_if_exists postin_compute
    fi
}


function standard_update() {
    determine_node_roles
    aggregate_variables

    case "$1" in
        update|stop_services|start_services)
            do_$1
            ;;
        *)
            echo "usage: $0 update|stop_services|start_services"
            exit 1
            ;;
    esac
}
