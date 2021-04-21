#!/bin/bash

function do_build_and_test() {
    ./build.sh  "$url" "$app" "$testdriver" "$1"
    cp -r thirdparty/sandbox sandbox_$1
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

do_build_and_test blas_small
do_build_and_test spmv_small
do_build_and_test solve_basic_small

