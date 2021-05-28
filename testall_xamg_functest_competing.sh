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
    ./functional_massive_tests.sh
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
export TESTSUITE_SCRIPT="functional"
export TESTSUITE_BRANCH=${2:${default_branch}}
export TESTSUITE_CONF=${3:${default_conf}}

echo "============"
echo STARTED AT: $(date)
echo "============"

for suite in blas_small spmv_small solve_basic_small; do
#for suite in spmv_small; do
    do_build_and_test $suite
done

echo "============"
echo ENDED AT: $(date)
echo "============"
timestamp=$(date +%s)
for i in sandbox_*; do
    suite=$(echo $i | sed 's/sandbox_//')
    nfailed=$(wc -l < $i/summary/references.txt)
    echo "----------------------------------------"
    echo "--- ${suite}: $nfailed failure references"
    echo "----------------------------------------"
    for j in $i/summary/table.*; do
        echo "----------------------------------------"
        echo "--> " $(basename $j)
        echo "----------------------------------------"
        cat $j
        echo "----------------------------------------"
    done
    tar czf summary_${suite}_${nfailed}F_${timestamp}.tar.gz $i/summary/*
done
