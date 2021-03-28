#!/bin/bash

set -eu

BSCRIPTSDIR=./dbscripts

source $BSCRIPTSDIR/base.inc
source $BSCRIPTSDIR/funcs.inc
source $BSCRIPTSDIR/compchk.inc
source $BSCRIPTSDIR/envchk.inc
source $BSCRIPTSDIR/db.inc
source $BSCRIPTSDIR/apps.inc

[ -f ../env.sh ] && source ../env.sh || fatal "No ../env.sh file!"

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
    PARAMS="$PARAMS MODULE=$TESTSUITE_MODULE"
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS clean" "$m"
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS" "$m"
    local FILES="massivetest scripts/competing/clean.sh scripts/competing/compare.sh scripts/competing/competing_massive_tests.sh scripts/competing/make_table.sh scripts/massive_tests.inc scripts/competing/script-postproc.sh confs/${TESTSUITE_CONF}/modeset.inc confs/${TESTSUITE_CONF}/params.inc"
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
        template_to_psubmitopts .
        cd "$INSTALL_DIR"
    fi
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
        cp "$INSTALL_DIR"/argsparser.bin/*.so "$INSTALL_DIR"/yaml-cpp.bin/lib/*.so lib/
        #cp "$INSTALL_DIR"/argsparser.bin/*.a "$INSTALL_DIR"/yaml-cpp.bin/lib/*.a lib/
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
        [ -e "imb_async.bin" ] || ln -s "$pkg".bin imb_async.bin
fi

}


function dnb_XAMG() {
    local pkg="XAMG"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    if any_mode_is_set "du" "$m"; then
        [ -e "$pkg"-"$V".src ] && rm -rf "$pkg"-"$V".src
        mkdir -p "$pkg"-"$V".src
        cd "$pkg"-"$V".src
		local branch="$V"
		local XVER=$(get_field "${V}" "1" "^")
        if [ "${XVER}" == "HEAD" ]; then
            local branch=master
            [ $(get_nfields "$V" "^") == "2" ] && branch=$(get_field "${VER}" "2" "^")
        fi
        git clone --depth 1 --single-branch --branch "$branch" --recursive https://gitlab.com/xamg/xamg.git .
        cd ..
    fi
	if this_mode_is_set "b" "$m"; then
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
    local PARAMS="BUILD=Release CONFIG=generic"
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS clean" "$m"
    cd $INSTALL_DIR
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS" "$m"
    local FILES="examples/test/xamg_test ThirdParty/hypre.bin/lib/*.so ThirdParty/scotch.bin/lib/*.so ThirdParty/argsparser.bin/*.so ThirdParty/yaml-cpp.bin/lib/*.so.*"
    i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    if this_mode_is_set "i" "$m"; then
        [ -e xamg.bin ] || ln -s XAMG.bin xamg.bin
    fi
}


function dnb_sandbox() {
    echo ">> Making sandbox:"
    mkdir -p sandbox
    [ -e sandbox/psubmit.bin ] || ln -s ../psubmit.bin sandbox/
    cp -va massivetests.bin/* sandbox/
	cp -va ${TESTSUITE_PROJECT}.bin/* sandbox/
    cp -va ../${TESTSUITE_PROJECT}.conf/* sandbox/
    cd sandbox
    for i in always never rand1 rand2 rand5 rand10 rand50 rand90 rand95 rand99; do 
        [ -e psubmit_${i}.opt ] || ln -s psubmit.opt psubmit_${i}.opt
    done
    for i in psubmit_*.opt.TEMPLATE; do
        local sfx=$(echo $i | sed 's/psubmit_//;s/.opt.TEMPLATE//')
        template_to_psubmitopts . "$sfx"
    done
    [ -e thirdparty ] || ln -s .. thirdparty
    [ -e env.sh ] || ln -s ../../env.sh env.sh
    cd ..
    echo ">> Sandbox ready"
    return 0
}


PACKAGES="yaml-cpp argsparser massivetests psubmit teststub mpi-benchmarks XAMG"
VERSIONS="yaml-cpp:0.6.3 argsparser:HEAD massivetests:HEAD^teststub_adding psubmit:HEAD teststub:HEAD mpi-benchmarks:HEAD XAMG:HEAD"
TARGET_DIRS=""

started=$(date "+%s")
echo "Download and build started at timestamp: $started."
environment_check_main || fatal "Environment is not supported, exiting"
[ -z "$TESTSUITE_MODULE" ] && fatal "TESTSUITE_MODULE must be defined."
[ -z "$TESTSUITE_PROJECT" ] && fatal "TESTSUITE_PROJECT must be defined."
[ -z "$TESTSUITE_CONF" ] && fatal "TESTSUITE_CONF must be defined."
cd "$INSTALL_DIR"
dubi_main "$*"
finished=$(date "+%s")
echo "----------"
echo "Full operation time: $(expr $finished - $started) seconds."

