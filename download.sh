#!/bin/bash
[ -e testapp_defaults.inc ] && source testapp_defaults.inc
cd thirdparty
DNB_OMIT_CHECKS=TRUE ./dnb.sh :d

