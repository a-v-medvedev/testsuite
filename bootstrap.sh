#!/bin/bash

function check_if_exists() {
    local mask=""
    local result=1
    for mask in $*; do
        local N=$(ls -1 $mask 2>/dev/null | wc -l)
	    [ "$N" != 0 ] && result=0
    done
    return $result
}

source thirdparty/dbscripts/base.inc
source thirdparty/dbscripts/funcs.inc
source thirdparty/dbscripts/db.inc

CONF_URL="$1"
app="$2"
confbranch=${3:-HEAD}

testmodule="functest"

if [ "$CONF_URL" == "clean" ]; then
    if check_if_exists confs-*.src; then
      N=$(ls -1 confs-*.src 2>/dev/null | wc -l)
      if [ "$N" == 1 ]; then
          cd confs-*.src
	  uncommitted_changes=$(git diff --quiet && git diff --cached --quiet && echo clean || echo dirty)
	  cd ..
	  [ "$uncommitted_changes" == "dirty" ] && fatal "the directory $(ls -1d confs-*.src) contains uncommitted changes, clean it manually."
      fi
    fi
    rm -rf confs-*.src
    rm -rf env.sh
    rm -rf thirdparty/*.dwn thirdparty/*.bin thirdparty/*.src thirdparty/*-* thirdparty/sandbox
    rm -rf thirdparty/_local/testapp_build.inc  thirdparty/_local/testapp_conf.yaml
    for i in application.conf confs.src testapp_defaults.inc suite.conf; do [ -L $i ] && rm $i; done
    exit 0
fi

basedir="confs-${confbranch}.src"

[ -d "$basedir" ] && fatal 'configuration tree is already cloned. Cannot bootstrap.'
check_if_exists thirdparty/*.dwn && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.dwn).'
check_if_exists thirdparty/*.bin && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.bin).'
check_if_exists thirdparty/*.src && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*.src).'
check_if_exists thirdparty/*-* && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/*-*).'
check_if_exists thirdparty/_local/testapp_build.inc && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/_local/testapp_build.inc).'
check_if_exists thirdparty/_local/testapp_conf.inc && fatal 'thirdparty is not clear, cannot bootstrap (thirdparty/_local/testapp_conf.inc).'
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

[ -e "application.conf" ] && rm -rf application.conf
ln -s $hwdir application.conf

if check_if_exists "application.conf/testall_*.sh" "application.conf/testapp_defaults.inc"; then
    for i in application.conf/testall_*.sh application.conf/testapp_defaults.inc; do
        [ -e "$i" ] || continue
        lnk=$(basename "$i")
        [ -e "$lnk" -o -L "$lnk" ] && echo "NOTE: symlink $lnk will be overwritten."
        rm -f "$lnk"
        ln -s "$i" "$lnk"
        echo "Made symlink: $lnk (to: $i)"
    done
fi

[ -e thirdparty/_local/testapp_build.inc -o -L thirdparty/_local/testapp_build.inc ] && rm -f thirdparty/_local/testapp_build.inc
[ -e thirdparty/_local/testapp_conf.yaml -o -L thirdparty/_local/testapp_conf.yaml ] && rm -f thirdparty/_local/testapp_conf.yaml
[ -e "$appdir/testapp_conf.yaml" ] || fatal "can't find dnb yaml config file for application: $app. Tried to access file: $appdir/testapp_conf.yaml."
[ -e "$appdir/build.inc" ] || fatal "can't find build script for application: $app. Tried to access file: $appdir/build.inc."
ln -s ../../$appdir/build.inc thirdparty/_local/testapp_build.inc
ln -s ../../$appdir/testapp_conf.yaml thirdparty/_local/testapp_conf.yaml
echo "Build script to use: $appdir/build.inc + $appdir/testapp_conf.yaml"

echo "------"
echo "> Testsuite bootstrap finished, now use testall.sh or testall_*.sh scripts for test action."
echo "> NOTE: Directory $basedir/ is a working git clone of configuration repository."
echo "> Use it to save your work."

