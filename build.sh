#!/bin/bash

function usage() {
    echo "Usage: $(basename $0) [-f|-i] <app> [<suite_name>] [<testmodule>]"
    echo "           app        -- the target application name to choose actual test configs."
    echo "           testmodule -- (default: 'functest') name of massivetests module to build and use."
    echo "           suite_name     -- (default: 'basic') the suite name to run tests for."
    echo 
    fatal "command line parsing results in no further action."
}

function check_prereq_exists() {
    pkg="$1"
    if [ -e ${pkg}.bin -a -e ${pkg}.src ]; then 
        return 0; 
    else
        return 1;
    fi
}

set -ue

source thirdparty/dbscripts/base.inc
source thirdparty/dbscripts/funcs.inc
source thirdparty/dbscripts/db.inc

##############
#set -x

set +u
app="$1"
suite_name="$2"
testmodule="$3"
[ -z "$suite_name" ] && suite_name="basic" 
[ -z "$testmodule" ] && testmodule="functest" 
set -u

[ -z "$app" -o -z "$testmodule" -o -z "$suite_name" ] && usage

export TESTSUITE_MODULE=$testmodule; 
export TESTSUITE_PROJECT=$app;
export TESTSUITE_SUITE_NAME="$suite_name"

hwconf=${USER}-$(hostname)
set +u
[ -z "$TESTSUITE_HWCONF" ] || hwconf="$TESTSUITE_HWCONF"
set -u
basedir="confs-*.src"
if [ $(ls -1d $basedir 2>/dev/null | wc -l) != "1" ]; then
    fatal "Can't find the configuration directory to use; tried to find: $basedir." 
else
    basedir=$(echo $basedir)
fi

echo "Locating test configs in: $basedir/$app/$testmodule"
echo "Using configuration: $hwconf"

appdir="$basedir/$app/$testmodule"
hwdir="$basedir/$app/$testmodule/$hwconf"
[ ! -d "$hwdir" ] && fatal "can't find configuration: $hwconf in config directory. Tried to access directory: $hwdir."

suite_dir="$hwdir/$suite_name"
[ ! -d "$suite_dir" ] && fatal "can't find suite_name: $suite_name in config directory. Tried to access directory: $suite_dir."

ls -l "$app.conf" || true
[ -e "$app.conf" ] && rm -f "$app.conf"
ln -s "$suite_dir" "$app.conf" || true


cd thirdparty
prereqs_are_built=$(check_prereq_exists "argsparser" && check_prereq_exists "daemonize" && check_prereq_exists "psubmit" && check_prereq_exists "yaml-cpp" && check_prereq_exists "massivetests" && echo OK || true)
pkgs=$(cat _local/testapp_conf.yaml | awk '/^packages:/ {on=1} on && /^[^p].*:/ {on=0} on {if ($3!="") print $3}' | tr '\n' ' ')
for i in $pkgs; do
    [ -d $i.dwn ] || continue
    [ -L $i.src ] || ./dnb.sh $i:u
    [ -L $i.src ] || fatal "uppack stage for package $i: can't locate $pkg.src"
    #ls -ld $i.src
    #ls -l $i.src/
    [ -f $i.src/dnb-$hwconf.yaml ] && { echo "Machine file found: $i.src/dnb-$hwconf.yaml"; cp $i.src/dnb-$hwconf.yaml _local/machine.yaml; }
done
if [ "$prereqs_are_built" != "OK" ]; then
    ./dnb.sh
else
    for pkg in $pkgs; do
        rm -rf ${pkg}-*.src
    done
    rm -rf sandbox
    for pkg in $pkgs; do
        ./dnb.sh ${pkg}:ub
    done
    ./dnb.sh :i
fi
cd ..

echo "Build is done."
