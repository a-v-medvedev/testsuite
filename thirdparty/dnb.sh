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
    PARAMS="$PARAMS MODULE=imb_async"
    b_make "$pkg" "$V" "$COMMANDS" "clean" "$m"
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS" "$m"
    local FILES="massivetest scripts/competing/clean.sh scripts/competing/compare.sh scripts/competing/competing_massive_tests.sh scripts/competing/make_table.sh scripts/massive_tests.inc scripts/competing/script-postproc.sh confs/imb_async_mars/modeset.inc confs/imb_async_mars/params.inc"
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

function dnb_mpi-benchmarks() {
    local pkg="mpi-benchmarks"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_github "a-v-medvedev" "mpi-benchmarks" "v" "$V" "$m"
    if this_mode_is_set "b" "$m"; then
        [ -f "$INSTALL_DIR/yaml-cpp.bin/include/yaml-cpp/yaml.h" ] || fatal "$pkg: installed yaml-cpp is required to build"
        [ -f "$INSTALL_DIR/argsparser.bin/argsparser.h" ] || fatal "$pkg: installed argsparser is required to build"
        cd "$INSTALL_DIR"
        cd "$pkg"-"$V".src/src_cpp
        cd "ASYNC/thirdparty"
        rm -f argsparser.bin yaml-cpp.bin
        ln -s "$INSTALL_DIR"/argsparser.bin .
        ln -s "$INSTALL_DIR"/yaml-cpp.bin .
        mkdir -p lib
        #cp "$INSTALL_DIR"/argsparser.bin/*.so "$INSTALL_DIR"/yaml-cpp.bin/lib/*.so lib/
        cp "$INSTALL_DIR"/argsparser.bin/*.a "$INSTALL_DIR"/yaml-cpp.bin/lib/*.a lib/
        cd "$INSTALL_DIR"/"$pkg"-"$V".src/src_cpp
        export CXXFLAGS="-IASYNC/thirdparty/argsparser.bin -IASYNC/thirdparty/yaml-cpp.bin/include "
        make TARGET=ASYNC CXX=$MPICXX clean
        make TARGET=ASYNC CXX=$MPICXX
        cd "$INSTALL_DIR"
    fi
    FILES="src_cpp/IMB-ASYNC"
    i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    if this_mode_is_set "i" "$m"; then
        cd "$pkg".bin
        cat > psubmit.opt.TEMPLATE << 'EOM'
QUEUE=__QUEUE__
QUEUE_SUFFIX=__QUEUE_SUFFIX__
NODETYPE=__NODETYPE__
TIME_LIMIT=3
TARGET_BIN=./IMB-ASYNC
INIT_COMMANDS=__INIT_COMMANDS__
INJOB_INIT_COMMANDS='__INJOB_INIT_COMMANDS__'
MPIEXEC=__MPI_SCRIPT__
BATCH=__BATCH_SCRIPT__
EOM
        template_to_psubmitopts .
        cd "$INSTALL_DIR"
fi

}


function dnb_sandbox() {
    echo ">> Making sandbox:"
    mkdir -p sandbox
    [ -e sandbox/psubmit.bin ] || ln -s ../psubmit.bin sandbox/
    cp -vr massivetests.bin/* sandbox/
	cp -vr teststub.bin/* sandbox/
    cp -vr mpi-benchmarks.bin/* sandbox/
    cp -vr ../teststub.conf/* sandbox/
    cd sandbox
    #template_to_psubmitopts .
    for i in always never rand1 rand2 rand5 rand10 rand50 rand90 rand95 rand99; do 
        [ -e psubmit_${i}.opt ] || ln -s psubmit.opt psubmit_${i}.opt
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
VERSIONS="yaml-cpp:0.6.3 argsparser:HEAD massivetests:HEAD^teststub_adding psubmit:HEAD teststub:HEAD mpi-benchmarks:HEAD"
TARGET_DIRS=""

started=$(date "+%s")
echo "Download and build started at timestamp: $started."
environment_check_main || fatal "Environment is not supported, exiting"
cd "$INSTALL_DIR"
dubi_main "$*"
finished=$(date "+%s")
echo "----------"
echo "Full operation time: $(expr $finished - $started) seconds."

