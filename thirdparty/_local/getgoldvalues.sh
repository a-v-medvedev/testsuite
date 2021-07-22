#!/bin/bash

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function print_norms() {
     for v in $VALS; do
        echo $v | grep -q norms_ || continue
        echo $v | awk -F= '{gsub("norms_", "norms/", $1); gsub("\"", "", $2); print "        " $1 ": " $2 }'
    done
}

function get_exec_arg() {
    local psubmit_out_file="$1"
    local key="$2"
    cat "$psubmit_out_file" | grep mpirun | awk -v "KEY=$key" '{ for (i=1;i<NF;i++) { if ($i==KEY) {++i; print $i; } } }'
}

N=$(ls -1 results.*/result*.yaml 2>/dev/null | wc -l)
[ "$N" == "0" ] && exit 0
for i in results.*/result*.yaml; do
    j=$(echo $i | sed 's!/result.!/psubmit_wrapper_output.!;s/\.yaml$//')
    WLD=$(get_exec_arg "$j" "-yaml" | sed 's!./input_!!;s/\.yaml$//')
    WPRT=$(get_exec_arg "$j" "-grid")
    VALS=$(parse_yaml "$i")
    if [ ! -z "$1" -a "$WLD" != "$1" ]; then continue; fi
    eval $VALS
    echo "# from: " $i
    echo "${WLD}/${WPRT}:"
    echo "    values:"
    echo "        scheme/time: " $scheme_time
    echo "        scheme/time_step: " $scheme_time_step
    echo "        scheme/tau: " $scheme_tau
    echo "        grid/nverts: " $grid_nverts
    echo "        grid/ncells: " $grid_ncells
    print_norms
    echo
done
