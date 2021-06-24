function dnb_qubiq-solver-tests() {
    local pkg="qubiq-solver-tests"
    local buildconf="generic"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_gitclone_recursive "$pkg" "https://$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN@gitlab.com/qubiq/qubiq-solver-tests.git" "$V" "$m"
    if this_mode_is_set "b" "$m"; then
        local OLD_INSTALL_DIR="$PWD"
        cd "$pkg-$V".src
        [ -e ../../env.sh -a ! -e env.sh ] && ln -s ../../env.sh env.sh
        export INSTALL_DIR="$PWD"
        export PACKAGE_VERSIONS="qubiq-solver:HEAD^$TESTSUITE_BRANCH"
        export DNB_SUPERIOR=".."
        ./dnb.sh
        cd ..
        export INSTALL_DIR=$OLD_INSTALL_DIR
    fi
    local FILES="sandbox/psubmit.opt sandbox/qubiq-solver sandbox/run sandbox/yaml sandbox/lib"
    i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    if this_mode_is_set "i" "$m"; then
        [ -e qubiq.bin ] || ln -s "$pkg".bin qubiq.bin
    fi
}


TESTSUITE_MODULE=${TESTSUITE_MODULE:-functest}
TESTSUITE_PROJECT=${TESTSUITE_PROJECT:-qubiq}
TESTSUITE_CONF=${TESTSUITE_CONF:-generic}
TESTSUITE_PACKAGES="qubiq-solver-tests"
TESTSUITE_BRANCH=${TESTSUITE_BRANCH:-master}
TESTSUITE_VERSIONS="qubiq-solver-tests:HEAD^master"
TESTSUITE_SCRIPT=${TESTSUITE_SCRIPT:-functional}

[ -z "$DNB_GITLAB_USERNAME" ] && fatal "DNB_GITLAB_USERNAME must be set (credentials to access gitlab.com/qubiq)" || true
[ -z "$DNB_GITLAB_ACCESS_TOKEN" ] && fatal "DNB_GITLAB_ACCESS_TOKEN must be set (credentials to access gitlab.com/qubiq)" || true

