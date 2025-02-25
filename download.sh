#!/bin/bash

[ -e application.conf/env.inc ] && source application.conf/env.inc

cd thirdparty
DNB_OMIT_CHECKS=TRUE ./dnb.sh :d

