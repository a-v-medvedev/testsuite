#!/bin/bash

[ -d sandbox ] || exit 0
s=$(ls -1d *-*.src 2>/dev/null | wc -l)
[ "$s" -gt "0" ] || exit 0
REFERENCE=$(find sandbox -type f -printf '%T@ %p\n' | sort -rn | head -n1 | awk '{print $2}')
F=$(for i in *-*.src; do find -L $i -newer $REFERENCE -type f 2>/dev/null; done | head -n1)
[ -z "$F" ] || exit 0 && exit 1
