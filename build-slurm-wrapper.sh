#!/bin/bash

[ -z "$SLURM_JOBID" -o -z "$SLURM_NODEID" ] && { echo "FATAL: this wrapper $(basename $0) is designed to be run inside a compute node."; exit 1; }

if [ ! -z "$SLURM_NODEID" -a "$SLURM_LOCALID" == "0" ]; then
    ./build.sh $*
fi

