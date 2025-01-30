# vim: set filetype=sh :

function dnb_massivetests() {
    local pkg="massivetests"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_github "a-v-medvedev" "massivetests" "v" "$V" "$m"
    if any_mode_is_set "bi" "$m"; then
        [ -f "$INSTALL_DIR/yaml-cpp.bin/include/yaml-cpp/yaml.h" ] || fatal "$pkg: installed yaml-cpp is required to build"
        [ -f "$INSTALL_DIR/argsparser.bin/argsparser.h" ] || fatal "$pkg: installed argsparser is required to build"
    fi
    local COMMANDS=""
    local PARAMS="THIRDPARTY=.."
    PARAMS="$PARAMS MODULE=functest"
    set +u    
    local cxxdef=""
    [ -z "$MASSIVETESTS_CXX" ] || cxxdef="CXX=$MASSIVETESTS_CXX"
    set -u
    PARAMS="$PARAMS $cxxdef"
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS clean" "$m"
    b_make "$pkg" "$V" "$COMMANDS" "$PARAMS" "$m"
    local FILES="massivetest scripts/massive_tests.inc"
    if [ "$TESTSUITE_SCRIPT" == "functional" ]; then
        local C="scripts/functional"
        FILES="$FILES $C/clean.sh $C/extract.sh $C/functional_massive_tests.sh $C/make_table.sh $C/script-postproc.sh"
    else
        fatal "building massivetests: unsupported value of TESTSUITE_SCRIPT: $TESTSUITE_SCRIPT"
    fi
    this_mode_is_set "i" "$m" && i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    return 0
}

