#!/bin/bash

[ -e testapp_defaults.inc ] && source testapp_defaults.inc

source thirdparty/dbscripts/base.inc
source thirdparty/dbscripts/funcs.inc

RESULT=""

function getnumfiles() {
    ls -1d "$1" 2>/dev/null | wc -l
}


function getfirstlinelen() {
    head -n1 $1 | awk '{print length($0)}'
}

function getmaxlinelen() {
    awk 'BEGIN{LEN=0}{l=length($0); LEN=(LEN<l?l:LEN)} END{print LEN}' < $1
}

function printline() {
    local len=$1
    printf '%*s' "$len" | tr ' ' '-'
    echo
}

function report() {
    RESULT="$1"
    return 1
}

function do_build_and_test() {
    local suite="$1"

    echo RUN: ./build.sh "$TESTSUITE_PROJECT" "$suite" 
    echo ">> ..."
    local t1=$(date +%s)
    local avoid_psubmit_build=""
    is_set_to_true TESTSUITE_LOCAL_BUILD && avoid_psubmit_build="true"
    if [ -e application.conf/$suite/build-psubmit.opt -a -z "$avoid_psubmit_build" ]; then
	echo ">> note: using psubmit to build on a compute node"    
        psubmit.sh -n1 -o application.conf/$suite/build-psubmit.opt -a "$TESTSUITE_PROJECT $suite" > build_$suite.log 2>&1
        local true_log=$(grep '^Rank 0 output:' build_$suite.log | awk '{print $4}')
        [ -z "$true_log" ] || cat "$true_log" > build_$suite.log
        grep -q "Build is done." build_$suite.log || report "build_failed" || return 1
    else
       ./build.sh  "$TESTSUITE_PROJECT" "$suite" > build_$suite.log 2>&1 || report "build_failed" || return 1
    fi
    local t2=$(date +%s)
    echo ">> done in $(expr $t2 - $t1) sec."
    rm -rf sandbox_$suite
    cp -r thirdparty/sandbox sandbox_$suite

    #--- step into the specific sandbox
    cd sandbox_$suite
    [ -f revision ] && echo "REVISION: $(cat revision)"
    rm psubmit.bin
    ln -s ../thirdparty/psubmit.bin .
    rm thirdparty
    ln -s ../thirdparty .
    echo RUN: ./functional_massive_tests.sh in sandbox_$suite directory
    echo ">> ..."
    local t3=$(date +%s)
    local VBBSID=""
    if [ -e ../application.conf/$suite/vbbs-psubmit.opt -a -z "$MASSIVE_TESTS_OMIT_EXECUTION" ]; then
	[ -x "$(command -v vbbs 2>/dev/null)" ] || { echo "FATAL: can't find vbbs executable"; report "test_routine_failed" || { cd ..; return 1; }; }
	[ -x "$(command -v vbbs_sleep.sh 2>/dev/null)" ] || { echo "FATAL: can't find vbbs_sleep.sh executable"; report "test_routine_failed" || { cd ..; return 1; }; }
	vbbs init
        psubmit.sh -e vbbs_sleep.sh -o ../application.conf/$suite/vbbs-psubmit.opt > ../vbbs_$suite.log 2>&1 &
        while [ "$VBBSID" == 0 -o "$VBBSID" == "" ]; do
	    sleep 1	
            VBBSID=$(vbbs slurm_show_id | grep SLURM_JOBID: | awk '{print $2}')
        done
	echo ">> note: using vbbs, pre-allocated slurm job: $VBBSID"    
    fi
    ./functional_massive_tests.sh > ../test_routine_$suite.log 2>&1 || report "test_routine_failed" || { cd ..; return 1; }
    [ -z "$VBBSID" ] || { kill -s 2 %1; vbbs init; }
    local t4=$(date +%s)
    cd ..
    #--- step out of the specific sandbox

    echo ">> done in $(expr $t4 - $t3) sec."
    report "$(expr $t2 - $t1) sec / $(expr $t4 - $t3) sec"  
    return 0
}

if [ ! -v TESTSUITE_CONF_URL ]; then
    if [ -e "${TESTSUITE_PROJECT}.conf" ]; then
        url=""
        cd "${TESTSUITE_PROJECT}.conf" && url=$(git remote -v | grep ' (fetch)' | awk '{print $2}') && cd ..
        [ -z "$url" ] || export TESTSUITE_CONF_URL="$url"
    fi
fi

export TESTSUITE_SUITES=${1:-${TESTSUITE_SUITES}}
_default=${TESTSUITE_BRANCH:-${TESTSUITE_DEFAULT_BRANCH}}
export TESTSUITE_BRANCH=${2:-${_default}}

echo "APPLICATION: $TESTSUITE_PROJECT"
echo "BRANCH: $TESTSUITE_BRANCH"
echo "BUILD_CONF: $TESTSUITE_BUILD_CONF"
echo "TESTDRIVER: functest"
echo "CONF_URL: $TESTSUITE_CONF_URL"
echo "STARTED_AT: $(date)"

timestamp="$TESTSUITE_TIMESTAMP"
[ -z "$timestamp" ] && timestamp=$(./get_timestamp.sh)
export TESTSUITE_TIMESTAMP="$timestamp"
echo "TIMESTAMP: $timestamp"
stop_operation=""

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
        if [ -v TESTSUITE_REQUIRED_SUITES ]; then
            for i in $TESTSUITE_REQUIRED_SUITES; do
                [ "$i" == "$suite" ] && stop_operation=1
            done 
        fi
    else
        echo "$RESULT" > timing_$suite.log
        echo "STATUS: ${suite}: actions complete."
    fi
    echo "SUITE_END: $suite"
    if [ ! -z "$stop_operation" ]; then
        echo ">> NOTE: we interrupt operation because this suite belongs to the list of required ones."
        break
    fi
done

echo "ENDED_AT: $(date)"

for suite in ${TESTSUITE_SUITES}; do
    i="sandbox_"$suite
    [ $(getnumfiles "$i") == "1" ] || continue
    nfailed=0
    [ -f $i/summary/references.txt ] && nfailed=$(wc -l < $i/summary/references.txt)
    echo
    printline 50
    if grep -q ' sec' timing_$suite.log; then
        echo "--- ${suite}: $(cat $i/summary/stats.txt)"
        [ "$nfailed" == 0 ] || echo "--- ${suite}: recorded $nfailed failure references"
        echo "--- ${suite}: processing time: $(cat timing_$suite.log)"
        printline 50
        for j in $i/summary/table.*; do
            LEN=$(getfirstlinelen $j)
            printline $LEN
            echo "--> " $(basename $j)
            printline $LEN
            cat $j
            printline $LEN
        done
        SUMMARY=summary_${suite}_${nfailed}F_${timestamp}.tar.gz
        tar czf "$SUMMARY" $i/summary/*
    else
        echo "--- ${suite}: failure on stage: $(cat timing_$suite.log)"
    fi
done

for suite in ${TESTSUITE_SUITES}; do
    i="sandbox_"$suite
    [ $(getnumfiles "$i") == "1" ] || continue
    if grep -q ' sec' timing_$suite.log; then
        [ -f $i/stats.txt ] && echo "Suite ${suite}:" $(cat $i/stats.txt)
    fi
done    


