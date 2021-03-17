#!/bin/bash

set -eu

[ -f ../env.sh ] && source ../env.sh || echo "WARNING: no environment file ../env.sh!"

BSCRIPTSDIR=./dbscripts

source $BSCRIPTSDIR/base.inc
source $BSCRIPTSDIR/funcs.inc
source $BSCRIPTSDIR/compchk.inc
source $BSCRIPTSDIR/envchk.inc
source $BSCRIPTSDIR/db.inc
source $BSCRIPTSDIR/apps.inc

function dnb_massivetests() {
    local pkg="massivetests"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_github "a-v-medvedev" "massivetests" "v" "$V" "$m"
    if any_mode_is_set "bi" "$m"; then
        [ -f "$INSTALL_DIR/yaml-cpp.bin/include/yaml-cpp/yaml.h" ] || fatal "$pkg: installed yaml-cpp is required to build"
        [ -f "$INSTALL_DIR/argsparser.bin/argsparser.h" ] || fatal "$pkg: installed argsparser is required to build"
    fi
    local COMMANDS=""
    local PARAMS="THIRDPARTY=.."
    PARAMS="$PARAMS MODULE=teststub"
    b_make "$pkg" "$V" "$COMMANDS" "clean" "$m"
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS" "$m"
    local FILES="massivetest clean.sh compare.sh competing_massive_tests.sh make_table.sh massive_tests.inc script-postproc.sh modules/imb_async/modeset.inc modules/imb_async/params.inc"
    this_mode_is_set "i" "$m" && i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    return 0
}

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
	return 0
}

function dnb_sandbox() {
    echo ">> Making sandbox:"
    mkdir -p sandbox
    [ -e sandbox/psubmit.bin ] || ln -s ../psubmit.bin sandbox/
    cp -vr massivetests.bin/* sandbox/
    cp -vr teststub.bin/* sandbox/
    cp -vr ../teststub.conf/* sandbox/
    cd sandbox
    template_to_psubmitopts .
    for i in always never rand1 rand2 rand5 rand10 rand50 rand90 rand95 rand99; do 
        ln -s psubmit.opt psubmit_${i}.opt
    done
    cd ..
    echo ">> Sandbox ready"
    return 0
}

####
#DNB_NOCUDA=1
#DNB_NOCCOMP=1
#CXX=g++
#MPICXX=g++

PACKAGES="yaml-cpp argsparser massivetests psubmit teststub"
VERSIONS="yaml-cpp:0.6.3 argsparser:HEAD massivetests:HEAD^teststub_adding psubmit:HEAD teststub:HEAD"
TARGET_DIRS=""

started=$(date "+%s")
echo "Download and build started at timestamp: $started."
environment_check_main || fatal "Environment is not supported, exiting"
cd "$INSTALL_DIR"
dubi_main "$*"
finished=$(date "+%s")
echo "----------"
echo "Full operation time: $(expr $finished - $started) seconds."

