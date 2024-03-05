#!/bin/bash

function get_timestamp() {
    secs=$(date +%s)
    day=$(date "+%Y.%m.%d" --date="@$secs")
    rest=$(expr "$secs" % 86400)
    code=$(awk -v N=$rest 'END { x1=(N/25/25/25); x2=(N/25/25)%25; x3=(N/25)%25; x4=N%25; printf "%c%c%c%c\n", 65+x1, 65+x2, 65+x3, 65+x4 }' < /dev/null)
    echo $day.$code
}

echo "$(get_timestamp)"
