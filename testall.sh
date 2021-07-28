#!/bin/bash

source thirdparty/dbscripts/base.inc

RESULT=""

function report() {
    RESULT="$1"
    return 1
}

function get_timestamp() {
    secs=$(date +%s)
    day=$(date "+%Y.%m.%d" --date="@$secs")
    rest=$(expr "$secs" % 86400)
    code=$(awk -v N=$rest 'END { x1=(N/25/25/25); x2=(N/25/25)%25; x3=(N/25)%25; x4=N%25; printf "%c%c%c%c\n", 65+x1, 65+x2, 65+x3, 65+x4 }' < /dev/null)
    echo $day.$code
}

function do_build_and_test() {
    local suite="$1"
    echo RUN: ./build.sh  "$TESTSUITE_CONF_URL" "$TESTSUITE_PROJECT" "$TESTSUITE_MODULE" "$suite"
    echo ">> ..."
    local t1=$(date +%s)
    ./build.sh  "$TESTSUITE_CONF_URL" "$TESTSUITE_PROJECT" "$TESTSUITE_MODULE" "$suite" > build_$suite.log 2>&1 || report "build_failed" || return 1
    local t2=$(date +%s)
    echo ">> done in $(expr $t2 - $t1) sec."
    if [ -z "$TESTSUITE_DONT_ALWAYS_REBUILD" ]; then
        rm -rf sandbox_$suite
        cp -r thirdparty/sandbox sandbox_$suite
    else
        if [ -e sandbox_$suite ]; then
            cp -ru thirdparty/sandbox/* sandbox_$suite/
        else
            cp -r thirdparty/sandbox sandbox_$suite
        fi
    fi
    cd sandbox_$suite
    [ -f revision ] && echo "REVISION: $(cat revision)"
    rm env.sh
    ln -s ../env.sh .
    rm psubmit.bin
    ln -s ../thirdparty/psubmit.bin .
    export LD_LIBRARY_PATH=lib:$LD_LIBRARY_PATH
    echo RUN: ./functional_massive_tests.sh in sandbox_$suite directory
    echo ">> ..."
    local t3=$(date +%s)
    ./functional_massive_tests.sh > test_routine_$suite.log 2>&1 || report "test_routine_failed" || return 1
    local t4=$(date +%s)
    cd ..
    echo ">> done in $(expr $t4 - $t3) sec."
    report "$(expr $t2 - $t1) sec / $(expr $t4 - $t3) sec" || return 0
}

echo "APPLICATION: $TESTSUITE_PROJECT"
echo "BRANCH: $TESTSUITE_BRANCH"
echo "BUILD_CONF: $TESTSUITE_BUILD_CONF"
echo "TESTDRIVER: $TESTSUITE_MODULE"
echo "SCRIPT: $TESTSUITE_SCRIPT"
echo "CONF_URL: $TESTSUITE_CONF_URL"
echo "STARTED_AT: $(date)"

timestamp=$(get_timestamp)

echo "TIMESTAMP: $timestamp"

for suite in ${TESTSUITE_SUITES}; do
    echo "SUITE_START: $suite"
    do_build_and_test $suite
    if [ "$?" == 1 ]; then
        case $RESULT in
            build_failed) 
                mv build_$suite.log log_$suite.log
                echo "build" > timing_$suite.log
                ;;
            test_routine_failed) 
                mv test_routine_$suite.log log_$suite.log
                echo "test_routine" > timing_$suite.log
                ;;
            *) fatal "Unknown state after 'do_build_and_test $suite' execution."
        esac
        echo "STATUS: ${suite}: failure on stage: $(cat timing_$suite.log)"
        cat log_$suite.log
        SUMMARY=summary_${suite}_$(cat timing_$suite.log)_failure_${timestamp}.tar.gz
        tar czf "$SUMMARY" log_$suite.log
        mkdir -p sandbox_${suite}
    else
        echo "$RESULT" > timing_$suite.log
        echo "STATUS: ${suite}: actions complete."
    fi
    echo "SUITE_END: $suite"
done

echo "ENDED_AT: $(date)"

if [ $(ls -1d sandbox_* 2>/dev/null | wc -l) != "0" ]; then 
    for i in sandbox_*; do
        suite=$(echo $i | sed 's/sandbox_//')
        nfailed=X
        [ -f $i/summary/references.txt ] && nfailed=$(wc -l < $i/summary/references.txt)
        echo
        echo "----------------------------------------"
        if grep -q ' sec' timing_$suite.log; then
            echo "--- ${suite}: $(cat $i/summary/stats.txt)"
            echo "--- ${suite}: recorded $nfailed failure references"
            echo "--- ${suite}: processing time: $(cat timing_$suite.log)"
            echo "----------------------------------------"
            for j in $i/summary/table.*; do
                echo "----------------------------------------"
                echo "--> " $(basename $j)
                echo "----------------------------------------"
                cat $j
                echo "----------------------------------------"
            done
            SUMMARY=summary_${suite}_${nfailed}F_${timestamp}.tar.gz
            tar czf "$SUMMARY" $i/summary/*
        else
            echo "--- ${suite}: failure on stage: $(cat timing_$suite.log)"
        fi
    done
fi

