set -E

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
altai_installer_dir=/opt/altai
tools_dir=$altai_installer_dir/tools
updates_dir=$altai_installer_dir/updates

function determine_versions() {
    if [ ! -r $release_file ]; then
        OLD_VERSION="1.0.0"
    else
        OLD_VERSION="$(normalize_version $(< $release_file))"
    fi

    NEW_VERSION=$(normalize_version $(rpm -q --queryformat '%{VERSION}\n' altai-installer))
}

function store_version() {
    echo "$NEW_VERSION" > $release_file
}

function check_updatable() {
    if [ "$OLD_VERSION_FOUND" == n ]; then
        echo "Cannot update from $OLD_VERSION to $NEW_VERSION."
        echo "$OLD_VERSION is not a parent version for $NEW_VERSION."
        echo "Please look for another version of Altai."
        exit 1
    fi
}

function build_version_list() {
    UPDATE_PLAN=""
    OLD_VERSION_FOUND=n
    while read version release_url; do
        if [ "$version" == "$OLD_VERSION" ]; then
            OLD_VERSION_FOUND=y
        elif [ "$OLD_VERSION_FOUND" == y ]; then
            UPDATE_PLAN="$UPDATE_PLAN
$version $release_url"
            if [ "$version" == "$NEW_VERSION" ]; then
                break
            fi
        fi
    done < $updates_dir/versions
}

function incremental_update() {
    set --  $UPDATE_PLAN
    rpm --erase --nodeps altai-release || true
    while [ -n "$1" ]; do
        local version=$1
        local release_url=$2
        local script="$updates_dir/update-${version}.sh"
        if [ -x "$script" ]; then
            echo "Updating to $version"
            rpm -Uvh "$release_url"
            yum clean all
            "$script"
        fi
        shift 2
    done
}

function has_role() {
    [[ "$NODE_ROLES" =~ .*${1}.* ]]
}

function determine_node_roles() {
    NODE_ROLES="$($tools_dir/node-roles)"
}

function aggregate_variables() {
    local VARIABLES="
        SERVICES_START
        SERVICES_STOP
        PACKAGES_INSTALL
        PACKAGES_ERASE
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
        local uniq_var=$(echo "${!var}" | sed 's/ /\n/' | sort -u)
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

# 1. Stop required services
# 2. Erase required packages
# 3. Run preinstall
# 4. Install required packages
# 5. Run postinstall
# 6. Start required services and add them to autostart
function standard_update() {
    determine_node_roles
    aggregate_variables

    if [ -n "$SERVICES_STOP" ]; then
        echo "Stopping services:" $SERVICES_STOP
        for srv in $SERVICES_STOP; do
            service $srv stop
        done
    fi

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

    if [ -n "$PACKAGES_INSTALL" ]; then
        echo "Installing/updating packages:" $PACKAGES_INSTALL
        yum install -y $PACKAGES_INSTALL
    fi

    run_if_exists postin_common
    if has_role master; then
        run_if_exists postin_master
    fi
    if has_role compute; then
        run_if_exists postin_compute
    fi

    if [ -n "$SERVICES_START" ]; then
        echo "Starting services:" $SERVICES_START
        for srv in $SERVICES_START; do
            service $srv start
            chkconfig --add $srv
        done
    fi
}
