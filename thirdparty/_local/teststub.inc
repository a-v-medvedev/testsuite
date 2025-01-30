
function dnb_teststub() {
    local pkg="teststub"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_github "a-v-medvedev" "teststub" "v" "$V" "$m"
    local COMMANDS=""
    local PARAMS="THIRDPARTY=../../thirdparty"
    b_make "$pkg" "$V" "$COMMANDS" "clean" "$m"
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS" "$m"
    local FILES="teststub"
    this_mode_is_set "i" "$m" && i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    if this_mode_is_set "i" "$m"; then
        cd "$pkg".bin
        cat > psubmit.opt.TEMPLATE << 'EOM'
QUEUE=__QUEUE__
QUEUE_SUFFIX=__QUEUE_SUFFIX__
NODETYPE=__NODETYPE__
TIME_LIMIT=3
TARGET_BIN=./teststub
INIT_COMMANDS=__INIT_COMMANDS__
INJOB_INIT_COMMANDS='__INJOB_INIT_COMMANDS__'
MPIEXEC=__MPI_SCRIPT__
BATCH=__BATCH_SCRIPT__
EOM
        template_to_psubmitopts . ""
        cd "$INSTALL_DIR"
    fi
    return 0
}

TESTSUITE_PROJECT=teststub
#TESTSUITE_BUILD_CONF=
TESTSUITE_PACKAGES="teststub"
TESTSUITE_VERSIONS="teststub:HEAD"
TESTSUITE_SCRIPT="functional"
