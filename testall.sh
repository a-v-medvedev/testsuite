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


url="https://github.com/a-v-medvedev/testsuite_confs.git"
app="xamg"
testdriver="functest"

export TESTSUITE_BRANCH=convergence_rework
export TESTSUITE_CONF=generic

do_build_and_test blas_small
do_build_and_test spmv_small
do_build_and_test solve_basic_small

