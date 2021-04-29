#!/bin/bash

function do_build_and_test() {
    ./build.sh  "$url" "$app" "$testdriver" "$1"
    if [ -e sandbox_$1 ]; then
        cp -ru thirdparty/sandbox/* sandbox_$1/
    else
        cp -r thirdparty/sandbox sandbox_$1
    fi
    cd sandbox_$1
    rm env.sh
    ln -s ../env.sh .
    rm psubmit.bin
    ln -s ../thirdparty/psubmit.bin .
    ./competing_massive_tests.sh
    cd ..
}


default_url="https://github.com/a-v-medvedev/testsuite_confs.git"
default_branch="master"
default_conf="generic"

app="xamg"
testdriver="functest"
url=${1:-${default_url}}

export TESTSUITE_MODULE="$testdriver"
export TESTSUITE_PROJECT="$app"
export TESTSUITE_SCRIPT="competing"
export TESTSUITE_BRANCH=${2:${default_branch}}
export TESTSUITE_CONF=${3:${default_conf}}

echo "============"
echo STARTED AT: $(date)
echo "============"
do_build_and_test blas_small
do_build_and_test spmv_small
do_build_and_test solve_basic_small
echo "============"
echo ENDED AT: $(date)
echo "============"

for i in sandbox_*; do
    for j in $i/table.*; do
        echo "--------------------------------"
        echo "--> " $j
        echo "--------------------------------"
        cat $j
        echo "--------------------------------"
    done
done

