#!/bin/bash

function env_init_global {
    echo "=== Specific Environment settings for 'mars' host ==="
    script=$(mktemp .XXXXXX.sh)
cat > $script << 'EOM'

export MAKE_PARALLEL_LEVEL=4

export PSUBMIT_OPTS_NNODES=1
export PSUBMIT_OPTS_PPN=4
export PSUBMIT_OPTS_NGPUS=1
export PSUBMIT_OPTS_QUEUE_NAME=test
export PSUBMIT_OPTS_QUEUE_SUFFIX=
export PSUBMIT_OPTS_NODETYPE=
export PSUBMIT_OPTS_INIT_COMMANDS=
export PSUBMIT_OPTS_MPI_SCRIPT=generic
export PSUBMIT_OPTS_BATCH_SCRIPT=direct

export PSUBMIT_OPTS_CPER10USEC=33

export TESTSUITE_MODULE=functest
export TESTSUITE_PROJECT=xamg
export TESTSUITE_CONF=xamg_mars

export DNB_NOCUDA=1
export DNB_NOCCOMP=1


EOM
    . $script
    cat $script
    rm $script
    echo "============================================================"
}


function env_init {
    local name="$1"
    case "$name" in
    scotch)
        # put here any specific env. setting before scotch build
    ;;
    yaml-cpp)
        # put here any specific env. setting before yaml-cpp build
    ;;
    silo)
        # put here any specific env. setting before silo build
    ;;
    CGNS)
        # put here any specific env. setting before CGNS build
	;;
    qubiq-lib)
        # put here any specific env. setting before qubiq-lib build
    ;;
    qubiq-solver)
        # put here any specific env. setting before qubiq-solver build
    ;;
    esac
    return 0
}

