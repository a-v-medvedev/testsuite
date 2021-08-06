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
if [ ! -e "$basedir" ]; then
    du_gitclone_recursive "confs" "$url" "HEAD" "du"
fi

hwdir=$basedir/$app/$testmodule/$hwconf

[ ! -d "$hwdir" ] && fatal "can't find configuration: $hwconf in config directory. Tried to access directory: $hwdir."

[ -f "$hwdir"/env.sh ] && cp "$hwdir"/env.sh . || fatal "no env.sh file in $hwdir."
dir="$hwdir/$suite_name"

[ ! -d "$dir" ] && fatal "can't find suite_name: $suite_name in config directory. Tried to access directory: $dir."
[ -e "$app.conf" ] && rm "$app.conf"

ln -s "$dir" "$app.conf"

[ -r thirdparty/_local/conf.inc ] && rm -f thirdparty/_local/conf.inc

ln -s $app.inc thirdparty/_local/conf.inc

export TESTSUITE_SUITE_NAME="$suite_name"

s=$(ls -1d thirdparty/*-*.src 2>/dev/null | wc -l)

if [ -z "$dont_always_rebuild" ]; then

if [ "$s" != "0" ]; then
    rm -rf thirdparty/*-*.src thirdparty/sandbox
fi
cd thirdparty
./dnb.sh
cd ..

else

if [ "$s" == "0" ]; then dnbmode=""; else dnbmode=":bi"; fi
cd thirdparty
./is_rebuild_required.sh && ./dnb.sh "$dnbmode" || ./dnb.sh massivetests:i
cd ..

fi
