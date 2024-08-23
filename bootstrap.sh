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

if [ "$CONF_URL" == "clean" ]; then
    rm -rf confs-*.src
    rm -rf thirdparty/*.dwn thirdparty/*.bin thirdparty/*.src thirdparty/*-* thirdparty/_local/conf.inc thirdparty/sandbox build-psubmit.opt env.sh
    exit 0
fi

basedir="confs-${confbranch}.src"

[ -d "$basedir" ] && fatal 'configuration tree is already cloned. Cannot bootstrap.'
check_if_exists thirdparty/*.dwn && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.dwn).'
check_if_exists thirdparty/*.bin && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.bin).'
check_if_exists thirdparty/*.src && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.src).'
check_if_exists thirdparty/*-* && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*-*).'
check_if_exists thirdparty/_local/conf.inc && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/_local/conf.inc).'
check_if_exists build-psubmit.opt && rm -f build-psubmit.opt
check_if_exists env.sh && rm -f env.sh

hwconf=${USER}-$(hostname)
[ -z "$TESTSUITE_HWCONF" ] || hwconf="$TESTSUITE_HWCONF"

echo "Using configuration: $hwconf"
echo "Doing git clone for a configuration repository:"
if [ ! -e "$basedir" ]; then
    pkg=confs; V="$confbranch"; m="du"; DNB_INSTALL_DIR=$PWD
    du_gitclone "$CONF_URL"
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

#[ -f "$hwdir"/env.sh ] && ln -s "$hwdir"/env.sh . || fatal "no env.sh file in $hwdir."
[ -f "$hwdir"/build-psubmit.opt ] && ln -s "$hwdir"/build-psubmit.opt .

[ -e thirdparty/_local/testapp_build.inc -o -L thirdparty/_local/testapp_build.inc ] && rm -f thirdparty/_local/testapp_build.inc
[ -e thirdparty/_local/testapp_conf.yaml -o -L thirdparty/_local/testapp_conf.yaml ] && rm -f thirdparty/_local/testapp_conf.yaml
[ -e "$appdir/testapp_conf.yaml" ] || fatal "can't find dnb yaml config file for application: $app. Tried to access file: $appdir/testapp_conf.yaml."
[ -e "$appdir/build.inc" ] || fatal "can't find build script for application: $app. Tried to access file: $appdir/build.inc."
ln -s ../../$appdir/build.inc thirdparty/_local/testapp_build.inc
ln -s ../../$appdir/testapp_conf.yaml thirdparty/_local/testapp_conf.yaml
echo "Build script to use: $appdir/build.inc + $appdir/testapp_conf.yaml"

echo "------"
echo "> Testsuite bootstrap finished, now use testall_*.sh scripts for test action."
echo "> NOTE: Directory $basedir/ is a working git clone of configuration repository."
echo "> Use it to save your work."

