#!/bin/bash

set -eu

DNB_DBSCRIPTSDIR=./dbscripts
DNB_YAML_CONFIG="dnb.yaml"

source $DNB_DBSCRIPTSDIR/includes.inc

[ -z "$TESTSUITE_MODULE" ] && fatal "TESTSUITE_MODULE must be defined."
[ -z "$TESTSUITE_PROJECT" ] && fatal "TESTSUITE_PROJECT must be defined."
[ -z "$TESTSUITE_PACKAGES" ] && fatal "TESTSUITE_PACKAGES must be defined."
[ -z "$TESTSUITE_VERSIONS" ] && fatal "TESTSUITE_VERSIONS must be defined."
[ -z "$TESTSUITE_SCRIPT" ] && fatal "TESTSUITE_SCRIPT must be defined."

source _local/testapp_build.inc

function dnb_massivetests() {
    generic_prolog "massivetests" $* || return 0
    du_github "a-v-medvedev" "v"
    if any_mode_is_set "bi" "$m"; then
        [ -f "$INSTALL_DIR/yaml-cpp.bin/include/yaml-cpp/yaml.h" ] || fatal "$pkg: installed yaml-cpp is required to build"
        [ -f "$INSTALL_DIR/argsparser.bin/argsparser.h" ] || fatal "$pkg: installed argsparser is required to build"
    fi
    local COMMANDS=""
    local PARAMS="THIRDPARTY=.."
    PARAMS="$PARAMS MODULE=$TESTSUITE_MODULE"
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
    cd sandbox
    generate_psubmit_opt "."
    #local nps=$(ls -1 psubmit_*.opt.TEMPLATE 2> /dev/null | wc -l)
    #if [ "$nps" != "0" ]; then
    #    for i in psubmit_*.opt.TEMPLATE; do
    #        local sfx=$(echo $i | sed 's/psubmit_//;s/.opt.TEMPLATE//')
    #        template_to_psubmitopts . "$sfx"
    #    done
    #fi
    #nps=$(ls -1 psubmit.opt.TEMPLATE 2> /dev/null | wc -l)
    #if [ "$nps" != "0" ]; then
    #    template_to_psubmitopts . ""
    #fi
    [ -e thirdparty ] || ln -s .. thirdparty
    #[ -e env.sh ] || ln -s ../../env.sh env.sh
    cd ..
    echo ">> Sandbox ready"
    return 0
}

source "$DNB_DBSCRIPTSDIR/yaml-config.inc"

#export DNB_NOCUDA=TRUE
#
##PACKAGES="yaml-cpp argsparser massivetests psubmit daemonize $TESTSUITE_PACKAGES"
##VERSIONS="yaml-cpp:0.7.0 argsparser:0.1.2 massivetests:HEAD psubmit:HEAD daemonize:1.7.8 $TESTSUITE_VERSIONS"

