#!/bin/bash

set -xeuo pipefail

cd clr
mkdir -p build
cd build

export CXXFLAGS="$CXXFLAGS -I$SRC_DIR/clr/opencl/khronos/headers/opencl2.2/"

cmake ${CMAKE_ARGS} \
  -DCLR_BUILD_HIP=ON \
  -DCLR_BUILD_OCL=ON \
  -DHIPCC_BIN_DIR=$PREFIX/bin \
  -DHIP_COMMON_DIR=$SRC_DIR/hip \
  -DPython3_EXECUTABLE=$BUILD_PREFIX/bin/python \
  -DROCM_PATH=$PREFIX \
  -DAMD_OPENCL_INCLUDE_DIR=$SRC_DIR/clr/opencl/amdocl/ \
  ..

make VERBOSE=1 -j${CPU_COUNT}
make install

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/activate/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done
