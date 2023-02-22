#!/bin/bash

function check_if_exists() {
	N=$(ls -1 $1 2>/dev/null | wc -l)
	[ "$N" != 0 ]
}

source thirdparty/dbscripts/base.inc
source thirdparty/dbscripts/funcs.inc
source thirdparty/dbscripts/db.inc

CONF_URL="$1"
app="$2"
testmodule="$3"
confbranch=${4:-HEAD}

basedir="confs-${confbranch}.src"

[ -d "$basedir" ] && fatal 'configuration tree is already cloned. Cannot bootstrap.'
check_if_exists thirdparty/*.dwn && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.dwn).'
check_if_exists thirdparty/*.bin && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.bin).'
check_if_exists thirdparty/*.src && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.src).'
check_if_exists thirdparty/*-* && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*-*).'
check_if_exists thirdparty/_local/conf.inc && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/_local/conf.inc).'

hwconf=${USER}-$(hostname)

echo "Using configuration: $hwconf"
echo "Doing git clone for a configuration repository:"
if [ ! -e "$basedir" ]; then
    du_gitclone_recursive "confs" "$CONF_URL" "$confbranch" "du"
fi
echo "Cloning finished."

appdir="$basedir/$app/$testmodule"
hwdir="$basedir/$app/$testmodule/$hwconf"
[ ! -d "$hwdir" ] && fatal "can't find configuration: $hwconf in config directory. Tried to access directory: $hwdir."

if check_if_exists "$appdir/testall_*.sh"; then
    for i in $appdir/testall_*.sh; do
        lnk=$(basename "$i")
        rm -f "$lnk"
        ln -s "$i" "$lnk"
        echo "Made symlink: $lnk (to: $i)"
    done
fi

if check_if_exists "$hwdir/testall_*.sh"; then
    for i in $appdir/testall_*.sh; do
        lnk=$(basename "$i")
        [ -e "$lnk" -o -L "$lnk" ] && echo "NOTE: symlink $lnk will be overwritten."
        rm -f "$lnk"
        ln -s "$i" "$lnk"
        echo "Made symlink: $lnk (to: $i)"
    done
fi

[ -f "$hwdir"/env.sh ] && ln -s "$hwdir"/env.sh . || fatal "no env.sh file in $hwdir."
suite_dir="$hwdir/$suite_name"

[ -e thirdparty/_local/conf.inc -o -L thirdparty/_local/conf.inc ] && rm -f thirdparty/_local/conf.inc
if [ -e thirdparty/_local/$app.inc ]; then
    ln -s $app.inc thirdparty/_local/conf.inc
    echo "Build script to use: thirdparty/_local/$app.inc"
else
    [ -e "$appdir/build.inc" ] || fatal "can't find build script for application: $app. Tried to access file: $appdir/build.inc."
    ln -s ../../$appdir/build.inc thirdparty/_local/conf.inc
    echo "Build script to use: $appdir/build.inc"
fi

echo "------"
echo "> Testsuite bootstrap finished, now use testall_*.sh scripts for test action."
echo "> NOTE: Directory $basedir/ is a working git clone of configuration repository."
echo "> Use it to save your work."

