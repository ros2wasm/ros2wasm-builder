#! /bin/bash

DrawLogo()
{
    echo -e "\n\
╔═════════════════════╗ \n\
║   ╔╗ ╦  ╔═╗╔═╗╔╦╗   ║ \n\
║   ╠╩╗║  ╠═╣╚═╗║║║   ║ \n\
║   ╚═╝╩═╝╩ ╩╚═╝╩ ╩   ║ \n\
╚═════════════════════╝ \n"

}

#-------------------------------------------------------------------------------
# HELP
#-------------------------------------------------------------------------------
Help()
{
    DrawLogo
    echo -e "Options:"
    echo "-h     help"
    echo "-c     clean workspace"
    echo "-d     activate cmake debug mode"
    echo "-u     build up to package"
    echo "-s     build selected package"
    echo "-i     ignore \"listed packages\""
    echo "-p     install emscripten python"
    echo "-v     verbose"
    echo -e "\n"
}

#-------------------------------------------------------------------------------
# INSTALL PYTHON
#-------------------------------------------------------------------------------
InstallPython()
{
    # Install emscripten python
    CONDA_META_DIR="${PWD}/install/conda-meta"
    [[ -d "${CONDA_META_DIR}" ]] || mkdir -p "${CONDA_META_DIR}"
    micromamba install -p ./install python --platform=emscripten-32 \
        -c https://repo.mamba.pm/emscripten-forge -y
    mv ./install/bin/python3 ./install/bin/old_python3
}

#-------------------------------------------------------------------------------
# VARIABLES
#-------------------------------------------------------------------------------
VERBOSE=0
EMSDK_VERBOSE=0
RMW_IMPLEMENTATION="rmw_wasm_cpp"
verbose_args=""
package_args=""
package_ignore=""
debug_mode=OFF
build_type="Release"

#-------------------------------------------------------------------------------
# OPTIONS
#-------------------------------------------------------------------------------

while getopts "hcdvpu:s:i:" option; do
    case $option in
        h) # Display help
            Help
            exit;;

        c) # Clean workspace
            [[ -d "${PWD}/install" ]] && rm -rf "${PWD}/install"
            [[ -d "${PWD}/build" ]]   && rm -rf "${PWD}/build"
            [[ -d "${PWD}/log" ]]     && rm -rf "${PWD}/log"
            exit;;

        d) # Activate cmake debug
            debug_mode=ON
            build_type=Debug
            echo "[BLASM]: CMake debug mode activated.";;

        v) # Make verbose
            VERBOSE=1
            EMSDK_VERBOSE=1
            verbose_args="--event-handlers console_direct+"
            echo "[BLASM]: Verbose activated.";;

        p) # Install emscripten python
            echo "[BLASM]: Installing python."
            package_ignore=""
            InstallPython;;

        u) # Build up to package
            DrawLogo
            package_args="--packages-up-to ${OPTARG}"
            echo "[BLASM]: Build up to ${OPTARG}.";;

        s) # Build selected package
            DrawLogo
            [[ -d "${PWD}/build/${OPTARG}" ]] && rm -rf "${PWD}/build/${OPTARG}"
            package_args="--packages-select ${OPTARG}"
            echo "[BLASM]: Build only ${OPTARG}.";;

        i) # Ignore "given packages"
            package_ignore="--packages-ignore ${OPTARG}"
            echo "[BLASM]: Ignore packages ${OPTARG}.";;

        \?) # Invalid option
            echo "Error: Invalid option."
            Help
            exit;;
    esac
done

#-------------------------------------------------------------------------------
# MAIN
#-------------------------------------------------------------------------------
[[ -z "${package_args}" ]] && { echo "No args given."; exit 1; }
[[ -d "${PWD}/src" ]] || { echo "Not a workspace directory"; exit 1; }

echo "[BLASM]: Commencing build."

colcon build \
    ${package_args} ${package_ignore} ${verbose_args} \
    --packages-skip-build-finished \
    --merge-install \
    --cmake-args \
        -DCMAKE_TOOLCHAIN_FILE="${EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_VERBOSE_MAKEFILE=${debug_mode} \
        -DRMW_IMPLEMENTATION=${RMW_IMPLEMENTATION} \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
        -DCMAKE_CROSSCOMPILING=TRUE \
        -DCMAKE_FIND_DEBUG_MODE=${debug_mode} \
        -DFORCE_BUILD_VENDOR_PKG=ON \
        -DCMAKE_BUILD_TYPE=${build_type} \
        -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" \
        -DPython3_EXECUTABLE=${CONDA_PREFIX}/bin/python \
        -Wno-dev
