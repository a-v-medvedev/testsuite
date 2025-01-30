#!/bin/bash

set -eu

DNB_DBSCRIPTSDIR=./dbscripts
DNB_YAML_CONFIG="dnb.yaml"

source $DNB_DBSCRIPTSDIR/includes.inc

[ -z "$TESTSUITE_PROJECT" ] && fatal "TESTSUITE_PROJECT must be defined."

export TESTSUITE_SCRIPT=functional

[ -e _local/testapp_build.inc ] && source _local/testapp_build.inc

function dnb_massivetests() {
    generic_prolog "massivetests" $* || return 0
    du_github "a-v-medvedev" "v"
    if any_mode_is_set "bi" "$m"; then
        [ -f "$DNB_INSTALL_DIR/yaml-cpp.bin/include/yaml-cpp/yaml.h" ] || fatal "$pkg: installed yaml-cpp is required to build"
        [ -f "$DNB_INSTALL_DIR/argsparser.bin/argsparser.h" ] || fatal "$pkg: installed argsparser is required to build"
    fi
    local COMMANDS=""
    local PARAMS="THIRDPARTY=.."
    PARAMS="$PARAMS MODULE=functest"
    set +u
    local cxxdef=""
    [ -z "$MASSIVETESTS_CXX" ] || cxxdef="CXX=$MASSIVETESTS_CXX"
    set -u
    PARAMS="$PARAMS $cxxdef"
    b_make "$COMMANDS" "$PARAMS clean"
    b_make "$COMMANDS" "$PARAMS"
    local FILES="massivetest scripts/massive_tests.inc"
    if [ "$TESTSUITE_SCRIPT" == "functional" ]; then
        local C="scripts/functional"
        FILES="$FILES $C/clean.sh $C/extract.sh $C/functional_massive_tests.sh $C/make_table.sh $C/script-postproc.sh"
    else
        fatal "building massivetests: unsupported value of TESTSUITE_SCRIPT: $TESTSUITE_SCRIPT"
    fi
    this_mode_is_set "i" && i_direct_copy "$FILES"
    generic_epilog
}

function dnb_daemonize() {
    generic_prolog "daemonize" $* || return 0
    du_github "bmc" "release-"
    bi_autoconf_make "" "" 
    generic_epilog
    return 0    
}

function dnb_sandbox() {
    echo ">> Making sandbox:"
    mkdir -p sandbox
    [ -e sandbox/psubmit.bin ] || ln -s ../psubmit.bin sandbox/
    cp -va massivetests.bin/* sandbox/
	cp -va ${TESTSUITE_PROJECT}.bin/* sandbox/
    cp -v ../${TESTSUITE_PROJECT}.conf/* sandbox/
    rm -f sandbox/psubmit.bin/daemonize
    cp -va daemonize.bin/sbin/daemonize sandbox/psubmit.bin
    cp -va daemonize.bin/sbin/daemonize sandbox/
    cd sandbox
    [ -e thirdparty ] || ln -s .. thirdparty
    cd ..
    echo ">> Sandbox ready"
    return 0
}

source "$DNB_DBSCRIPTSDIR/yaml-config.inc"


