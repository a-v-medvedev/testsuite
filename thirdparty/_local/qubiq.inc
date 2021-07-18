function dnb_qubiq-solver-tests() {
    local pkg="qubiq-solver-tests"
    local buildconf="generic"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_gitclone_recursive "$pkg" "https://$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN@gitlab.com/qubiq/qubiq-solver-tests.git" "$V" "$m"

    #####
    if this_mode_is_set "d" "$m"; then
        local revision=$(git ls-remote --heads https://$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN@gitlab.com/qubiq/qubiq-solver | grep "$TESTSUITE_BRANCH" | awk '{print $1}')
        [ -e "$pkg".dwn ] && echo $revision > "$pkg".dwn/revision
        [ -e "$pkg-$V".src ] && echo $revision > "$pkg-$V".src/revision
    fi
    #####

    
    if this_mode_is_set "b" "$m"; then
        local OLD_INSTALL_DIR="$PWD"
        cd "$pkg-$V".src
        [ -e ../../env.sh -a ! -e env.sh ] && ln -s ../../env.sh env.sh
        export INSTALL_DIR="$PWD"
        export PACKAGE_VERSIONS="qubiq-solver:HEAD^$TESTSUITE_BRANCH"
        export CXXFLAGS="-DWITH_AUTOTEST"
        export DNB_SUPERIOR=".."
        ./dnb.sh ":$m"
        cd ..
        export INSTALL_DIR=$OLD_INSTALL_DIR
    fi

    local FILES="sandbox/psubmit.opt sandbox/qubiq-solver sandbox/run sandbox/yaml sandbox/lib"
    i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    if this_mode_is_set "i" "$m"; then
        [ -e qubiq.bin ] || ln -s "$pkg".bin qubiq.bin
        [ -e "$pkg".dwn/revision ] && cp "$pkg".dwn/revision qubiq.bin/revision
        [ -e "$pkg-$V".src/revision ] && cp "$pkg-$V".src/revision qubiq.bin/revision
        cat > "qubiq.bin/post-copy-chkpnt.sh" <<'EOM'
#!/bin/bash

wld="$1"
conf="$2"
wprt="$3"

from=out.$PSUBMIT_JOBID
to=chk.${wld}__${wprt}__${conf}__np${PSUBMIT_NP}

if [ -d ${from}/chk ]; then 
    [ -e "${to}" ] && rm -rf "${to}"
    cp -a ${from}/chk ${to}
fi
EOM

        cat > "qubiq.bin/pre-copy-chkpnt.sh" <<'EOM'
#!/bin/bash

wld="$1"
conf="$2"
wprt="$3"

to=out.${PSUBMIT_JOBID}
from=chk.${wld}__${wprt}__${conf}__np$PSUBMIT_NP

if [ -d ${from} ]; then 
    [ -e "${to}" ] && rm -rf "${to}"
    mkdir -p "${to}"
    cp -a ${from} ${to}/chk
fi
EOM
		chmod +x qubiq.bin/*.sh
    fi
}

TESTSUITE_MODULE=${TESTSUITE_MODULE:-functest}
TESTSUITE_PROJECT=${TESTSUITE_PROJECT:-qubiq}
TESTSUITE_BUILD_CONF=${TESTSUITE_BUILD_CONF:-generic}
TESTSUITE_PACKAGES="qubiq-solver-tests"
TESTSUITE_BRANCH=${TESTSUITE_BRANCH:-master}
TESTSUITE_VERSIONS="qubiq-solver-tests:HEAD^master"
TESTSUITE_SCRIPT=${TESTSUITE_SCRIPT:-functional}

[ -z "$DNB_GITLAB_USERNAME" ] && fatal "DNB_GITLAB_USERNAME must be set (credentials to access gitlab.com/qubiq)" || true
[ -z "$DNB_GITLAB_ACCESS_TOKEN" ] && fatal "DNB_GITLAB_ACCESS_TOKEN must be set (credentials to access gitlab.com/qubiq)" || true

