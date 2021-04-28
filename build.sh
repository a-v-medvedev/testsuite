#!/bin/bash

function usage() {
    echo "Usage: $(basename $0) [-f|-i] <url> <app> [<testmodule>] [<subset>]"
    echo "           url        -- a git repository URL suitable for git clone, with some"
    echo "                         credentials if required. This git repository must"
    echo "                         contain config directory with the appropriate files."
    echo "           app        -- the target application name to choose actual test configs."
    echo "           testmodule -- (default: 'functest') name of massivetests module to build and use."
    echo "           subset     -- (default: 'basic') the config subset to run tests."
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
subset="$4"
[ -z "$testmodule" ] && testmodule="functest" 
[ -z "$subset" ] && subset="basic" 
set -u

[ -z "$url" -o -z "$app" -o -z "$testmodule" -o -z "$subset" ] && usage

hwconf=${USER}-$(hostname)
basedir="confs-HEAD.src"

echo "Using configuration: $hwconf"
if [ ! -e "$basedir" ]; then
    du_gitclone_recursive "confs" "$url" "HEAD" "du"
fi

hwdir=$basedir/$app/$testmodule/$hwconf

[ ! -d "$hwdir" ] && fatal "can't find configuration: $hwconf in config directory. Tried to access directory: $hwdir."

[ -f "$hwdir"/env.sh ] && cp "$hwdir"/env.sh . || fatal "no env.sh file in $hwdir."
dir="$hwdir/$subset"

[ ! -d "$dir" ] && fatal "can't find subset: $subset in config directory. Tried to access directory: $dir."
[ -e "$app.conf" ] && rm "$app.conf"

ln -s "$dir" "$app.conf"

[ -r thirdparty/_local/conf.inc ] && rm -f thirdparty/_local/conf.inc

ln -s $app.inc thirdparty/_local/conf.inc

s=$(ls -1d thirdparty/*-*.src | wc -l)
if [ "$s" == "0" ]; then dnbmode=""; else dnbmode=":bi"; fi
cd thirdparty
./is_rebuild_required.sh && ./dnb.sh "$dnbmode" || ./dnb.sh massivetests:i
cd ..
