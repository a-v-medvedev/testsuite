#!/bin/bash

function usage() {
    echo "Usage: $(basename $0) [-f|-i] <url> <app> [<testmodule>] [<suite_name>]"
    echo "           url        -- a git repository URL suitable for git clone, with some"
    echo "                         credentials if required. This git repository must"
    echo "                         contain config directory with the appropriate files."
    echo "           app        -- the target application name to choose actual test configs."
    echo "           testmodule -- (default: 'functest') name of massivetests module to build and use."
    echo "           suite_name     -- (default: 'basic') the suite name to run tests for."
    echo 
    fatal "command line parsing results in no further action."
}

function check_prereq_exists() {
    pkg="$1"
    if [ -e thirdparty/${pkg}.bin -a -e thirdparty/${pkg}.src ]; then 
        return 0; 
    else
        return 1;
    fi
}

set -ue

source thirdparty/dbscripts/base.inc
source thirdparty/dbscripts/funcs.inc
source thirdparty/dbscripts/db.inc

set +u
url="$1"
app="$2"
testmodule="$3"
suite_name="$4"
[ -z "$testmodule" ] && testmodule="functest" 
[ -z "$suite_name" ] && suite_name="basic" 
dont_always_rebuild="$TESTSUITE_DONT_ALWAYS_REBUILD"
set -u

[ -z "$url" -o -z "$app" -o -z "$testmodule" -o -z "$suite_name" ] && usage

hwconf=${USER}-$(hostname)
basedir="confs-HEAD.src"

echo "Using configuration: $hwconf"
#if [ ! -e "$basedir" ]; then
#    du_gitclone_recursive "confs" "$url" "HEAD" "du"
#fi

appdir="$basedir/$app/$testmodule"
hwdir="$basedir/$app/$testmodule/$hwconf"
[ ! -d "$hwdir" ] && fatal "can't find configuration: $hwconf in config directory. Tried to access directory: $hwdir."

#[ -f "$hwdir"/env.sh ] && cp "$hwdir"/env.sh . || fatal "no env.sh file in $hwdir."
suite_dir="$hwdir/$suite_name"
[ ! -d "$suite_dir" ] && fatal "can't find suite_name: $suite_name in config directory. Tried to access directory: $suite_dir."
[ -e "$app.conf" ] && rm "$app.conf"
ln -s "$suite_dir" "$app.conf"

#[ -e thirdparty/_local/conf.inc -o -L thirdparty/_local/conf.inc ] && rm -f thirdparty/_local/conf.inc
#if [ -e thirdparty/_local/$app.inc ]; then
#    ln -s $app.inc thirdparty/_local/conf.inc
#else
#    [ -e "$appdir/build.inc" ] || fatal "can't find build script for application: $app. Tried to access file: $appdir/build.inc."
#    ln -s $PWD/$appdir/build.inc thirdparty/_local/conf.inc
#fi

export TESTSUITE_SUITE_NAME="$suite_name"


if [ -z "$dont_always_rebuild" ]; then
    TESTSUITE_PACKAGES_EXPR=$(grep 'TESTSUITE_PACKAGES=' thirdparty/_local/conf.inc)
    PREREQUISITES=""
    ALL_PREREQ=$(check_prereq_exists "argsparser" && check_prereq_exists "daemonize" && check_prereq_exists "psubmit" && check_prereq_exists "yaml-cpp" && check_prereq_exists "massivetests" && echo OK || true)
    if [ -z "$TESTSUITE_PACKAGES_EXPR" -o "$ALL_PREREQ" != "OK" ]; then
        rm -rf thirdparty/*-*.src thirdparty/*.bin thirdparty/sandbox
        cd thirdparty
        ./dnb.sh
        cd ..
    else
        eval $TESTSUITE_PACKAGES_EXPR
        for pkg in $TESTSUITE_PACKAGES; do
            rm -rf thirdparty/${pkg}-*.src
        done
        rm -rf thirdparty/sandbox
        cd thirdparty
        for pkg in $TESTSUITE_PACKAGES; do
            ./dnb.sh ${pkg}:dub
        done
        ./dnb.sh :i
        cd ..
    fi
else
    s=$(ls -1d thirdparty/*-*.src 2>/dev/null | wc -l)
    if [ "$s" == "0" ]; then dnbmode=""; else dnbmode=":bi"; fi
    cd thirdparty
    ./is_rebuild_required.sh && ./dnb.sh "$dnbmode" || ./dnb.sh massivetests:i
    cd ..
fi
