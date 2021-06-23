#!/bin/bash

set -eu

BSCRIPTSDIR=./dbscripts

source $BSCRIPTSDIR/base.inc
source $BSCRIPTSDIR/funcs.inc
source $BSCRIPTSDIR/compchk.inc
source $BSCRIPTSDIR/envchk.inc
source $BSCRIPTSDIR/db.inc
source $BSCRIPTSDIR/apps.inc
source _local/massivetests_dnb.inc
source _local/conf.inc

[ -f ../env.sh ] && source ../env.sh || fatal "No ../env.sh file!"

[ -z "$TESTSUITE_MODULE" ] && fatal "TESTSUITE_MODULE must be defined."
[ -z "$TESTSUITE_PROJECT" ] && fatal "TESTSUITE_PROJECT must be defined."
[ -z "$TESTSUITE_PACKAGES" ] && fatal "TESTSUITE_PACKAGES must be defined."
[ -z "$TESTSUITE_VERSIONS" ] && fatal "TESTSUITE_VERSIONS must be defined."
[ -z "$TESTSUITE_SCRIPT" ] && fatal "TESTSUITE_SCRIPT must be defined."


function dnb_sandbox() {
    echo ">> Making sandbox:"
    mkdir -p sandbox
    [ -e sandbox/psubmit.bin ] || ln -s ../psubmit.bin sandbox/
    cp -va argsparser.bin/*.so sandbox/
    cp -va massivetests.bin/* sandbox/
	cp -va ${TESTSUITE_PROJECT}.bin/* sandbox/
    cp -va ../${TESTSUITE_PROJECT}.conf/* sandbox/
    cp -va daemonize.bin/sbin/daemonize sandbox/psubmit.bin
    cd sandbox
    local nps=$(ls -1 psubmit_*.opt.TEMPLATE 2> /dev/null | wc -l)
    if [ "$nps" != "0" ]; then
        for i in psubmit_*.opt.TEMPLATE; do
            local sfx=$(echo $i | sed 's/psubmit_//;s/.opt.TEMPLATE//')
            template_to_psubmitopts . "$sfx"
        done
    fi
    nps=$(ls -1 psubmit.opt.TEMPLATE 2> /dev/null | wc -l)
    if [ "$nps" != "0" ]; then
        template_to_psubmitopts . ""
    fi
    [ -e thirdparty ] || ln -s .. thirdparty
    [ -e env.sh ] || ln -s ../../env.sh env.sh
    cd ..
    echo ">> Sandbox ready"
    return 0
}

function dnb_daemonize() {
    local pkg="daemonize"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_github "bmc" "daemonize" "release-" "$V" "$m"
	bi_autoconf_make "$pkg" "$V" "" "" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    return 0    
}

PACKAGES="yaml-cpp argsparser massivetests psubmit daemonize $TESTSUITE_PACKAGES"
VERSIONS="yaml-cpp:0.6.3 argsparser:HEAD massivetests:HEAD^teststub_adding psubmit:HEAD daemonize:1.7.8 $TESTSUITE_VERSIONS"
TARGET_DIRS="sandbox"

started=$(date "+%s")
echo "Download and build started at timestamp: $started."
environment_check_main || fatal "Environment is not supported, exiting"
cd "$INSTALL_DIR"
dubi_main "$*"
finished=$(date "+%s")
echo "----------"
echo "Full operation time: $(expr $finished - $started) seconds."

