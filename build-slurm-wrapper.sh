#!/bin/bash

[ -z "$SLURM_JOBID" -o -z "$NODE_NODEID" ] && { ./build.sh $*; exit $?; }

if [ ! -z "$SLURM_NODEID" -a "$SLURM_LOCALID" == "0" ]; then
    ./build.sh $*
fi

