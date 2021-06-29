function dnb_XAMG() {
    local pkg="XAMG"
    local buildconf="generic"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_gitclone_recursive "$pkg" "https://$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN@gitlab.com/krasnopolsky_msu/XAMG.git" "$V" "$m"
    if this_mode_is_set "b" "$m"; then
        [ -e ../env.sh -a ! -e env.sh ] && ln -s ../env.sh env.sh 
        cd "$pkg"-"$V".src
        local old_install_dir=$INSTALL_DIR
        cd ThirdParty
        INSTALL_DIR=$PWD
        ./dnb.sh
        rm argsparser.bin
        ln -s ../../argsparser.bin argsparser.bin
        INSTALL_DIR="$old_install_dir"
        cd $INSTALL_DIR
    fi
    local COMMANDS="cd examples/test"
    for i in 1 2 4 8; do
        local PARAMS="BUILD=Release CONFIG=${buildconf} XAMG_USER_FLAGS=\"-DXAMG_NV=${i}\""
        b_make "$pkg" "$V" "$COMMANDS" "$PARAMS clean" "$m"
        b_make "$pkg" "$V" "$COMMANDS" "$PARAMS" "$m"
        mv "$pkg"-"$V".src/examples/test/xamg_test "$pkg"-"$V".src/examples/test/xamg_test_nv${i}
    done
    for i in 1 2 4 8; do
        local PARAMS="BUILD=Debug CONFIG=${buildconf} XAMG_USER_FLAGS=\"-DXAMG_NV=${i}\" WITH_SEPARATE_OBJECTS=TRUE"
        b_make "$pkg" "$V" "$COMMANDS" "$PARAMS clean" "$m"
        b_make "$pkg" "$V" "$COMMANDS" "$PARAMS" "$m"
        mv "$pkg"-"$V".src/examples/test/xamg_test "$pkg"-"$V".src/examples/test/xamg_test_debug_nv${i}
    done
    local FILES="examples/test/xamg_test_nv* examples/test/xamg_test_debug_nv* libxamgsep.so ThirdParty/hypre.bin/lib/*.so ThirdParty/scotch.bin/lib/*.so ThirdParty/argsparser.bin/*.so ThirdParty/yaml-cpp.bin/lib/*.so.*"
    i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    if this_mode_is_set "i" "$m"; then
        [ -e xamg.bin ] || ln -s XAMG.bin xamg.bin
    fi
}


TESTSUITE_MODULE=${TESTSUITE_MODULE:-functest}
TESTSUITE_PROJECT=${TESTSUITE_PROJECT:-xamg}
TESTSUITE_BUILD_CONF=${TESTSUITE_BUILD_CONF:-generic}
TESTSUITE_PACKAGES="XAMG"
TESTSUITE_BRANCH=${TESTSUITE_BRANCH:-master}
TESTSUITE_VERSIONS="XAMG:HEAD^$TESTSUITE_BRANCH"
TESTSUITE_SCRIPT=${TESTSUITE_SCRIPT:-functional}

[ -z "$DNB_GITLAB_USERNAME" ] && fatal "DNB_GITLAB_USERNAME must be set (credentials to access gitlab.com/krasnopolsky_msu)" || true
[ -z "$DNB_GITLAB_ACCESS_TOKEN" ] && fatal "DNB_GITLAB_ACCESS_TOKEN must be set (credentials to access gitlab.com/krasnopolsky_msu)" || true

