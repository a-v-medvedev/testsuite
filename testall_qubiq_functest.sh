#!/bin/bash

source thirdparty/dbscripts/base.inc

default_url="https://github.com/a-v-medvedev/testsuite_confs.git"
default_branch="functest_connection"
default_conf="generic"

app="qubiq"
testdriver="functest"
url=${1:-${default_url}}

export TESTSUITE_MODULE="$testdriver"
export TESTSUITE_PROJECT="$app"
export TESTSUITE_SCRIPT="functional"
export TESTSUITE_BRANCH=${2:-${default_branch}}
export TESTSUITE_CONF_URL=${3:-${default_conf}}
export TESTSUITE_SUITES="basic"

source ./testall.sh
