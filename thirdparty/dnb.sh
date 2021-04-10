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
    cp -va massivetests.bin/* sandbox/
	cp -va ${TESTSUITE_PROJECT}.bin/* sandbox/
    cp -va ../${TESTSUITE_PROJECT}.conf/* sandbox/
    cd sandbox
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


PACKAGES="yaml-cpp argsparser massivetests psubmit $TESTSUITE_PACKAGES"
VERSIONS="yaml-cpp:0.6.3 argsparser:HEAD massivetests:HEAD^teststub_adding psubmit:HEAD $TESTSUITE_VERSIONS"
TARGET_DIRS="sandbox"

started=$(date "+%s")
echo "Download and build started at timestamp: $started."
environment_check_main || fatal "Environment is not supported, exiting"
cd "$INSTALL_DIR"
dubi_main "$*"
finished=$(date "+%s")
echo "----------"
echo "Full operation time: $(expr $finished - $started) seconds."

