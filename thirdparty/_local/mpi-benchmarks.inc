function dnb_mpi-benchmarks() {
    local pkg="mpi-benchmarks"
    environment_check_specific "$pkg" || fatal "$pkg: environment check failed"
    local m=$(get_field "$1" 2 "=")
    local V=$(get_field "$2" 2 "=")
    du_github "a-v-medvedev" "mpi-benchmarks" "v" "$V" "$m"
    if this_mode_is_set "b" "$m"; then
        [ -f "$INSTALL_DIR/yaml-cpp.bin/include/yaml-cpp/yaml.h" ] || fatal "$pkg: installed yaml-cpp is required to build"
        [ -f "$INSTALL_DIR/argsparser.bin/argsparser.h" ] || fatal "$pkg: installed argsparser is required to build"
        cd "$INSTALL_DIR"
        cd "$pkg"-"$V".src/src_cpp
        cd "ASYNC/thirdparty"
        rm -f argsparser.bin yaml-cpp.bin
        ln -s "$INSTALL_DIR"/argsparser.bin .
        ln -s "$INSTALL_DIR"/yaml-cpp.bin .
        mkdir -p lib
        cp "$INSTALL_DIR"/argsparser.bin/*.so "$INSTALL_DIR"/yaml-cpp.bin/lib/*.so lib/
        #cp "$INSTALL_DIR"/argsparser.bin/*.a "$INSTALL_DIR"/yaml-cpp.bin/lib/*.a lib/
        cd "$INSTALL_DIR"/"$pkg"-"$V".src/src_cpp
        export CXXFLAGS="-IASYNC/thirdparty/argsparser.bin -IASYNC/thirdparty/yaml-cpp.bin/include "
        make TARGET=ASYNC CXX=$MPICXX clean
        make TARGET=ASYNC CXX=$MPICXX
        cd "$INSTALL_DIR"
    fi
    FILES="src_cpp/IMB-ASYNC"
    i_direct_copy "$pkg" "$V" "$FILES" "$m"
    i_make_binary_symlink "$pkg" "${V}" "$m"
    if this_mode_is_set "i" "$m"; then
        cd "$pkg".bin
        cat > psubmit.opt.TEMPLATE << 'EOM'
QUEUE=__QUEUE__
QUEUE_SUFFIX=__QUEUE_SUFFIX__
NODETYPE=__NODETYPE__
TIME_LIMIT=3
TARGET_BIN=./IMB-ASYNC
INIT_COMMANDS=__INIT_COMMANDS__
INJOB_INIT_COMMANDS='__INJOB_INIT_COMMANDS__'
MPIEXEC=__MPI_SCRIPT__
BATCH=__BATCH_SCRIPT__
EOM
        template_to_psubmitopts . ""
        cd "$INSTALL_DIR"
        [ -e "imb_async.bin" ] || ln -s "$pkg".bin imb_async.bin
    fi

}

TESTSUITE_MODULE=imb_async
TESTSUITE_PROJECT=imb_async
#TESTSUITE_BUILD_CONF=
TESTSUITE_PACKAGES="mpi-benchmarks"
TESTSUITE_VERSIONS="mpi-benchmarks:HEAD"
TESTSUITE_SCRIPT=competing
