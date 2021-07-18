#!/bin/bash

source thirdparty/dbscripts/base.inc

[ -z "$DNB_GITLAB_USERNAME" ] && echo "DNB_GITLAB_USERNAME environment variable must be defined" && exit 1
[ -z "$DNB_GITLAB_ACCESS_TOKEN" ] && echo "DNB_GITLAB_ACCESS_TOKEN environment variable must be defined" && exit 1

default_url="https://$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN@gitlab.com/qubiq/qubiq-testsuite-conf.git"
default_branch="master"
default_conf="generic"

app="qubiq"
testdriver="functest"
url=${1:-${default_url}}

export TESTSUITE_MODULE="$testdriver"
export TESTSUITE_PROJECT="$app"
export TESTSUITE_SCRIPT="functional"
export TESTSUITE_BRANCH=${2:-${default_branch}}
export TESTSUITE_CONF_URL=${1:-${default_url}}
export TESTSUITE_SUITES="basic"
export TESTSUITE_BUILD_CONF=${3:-${default_conf}}

source ./testall.sh
