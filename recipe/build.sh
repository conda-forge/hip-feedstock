#!/bin/bash

set -xeuo pipefail

pushd hipcc
mkdir build
cd build
cmake ${CMAKE_ARGS} ..
make VERBOSE=1 -j${CPU_COUNT}
make install
popd

pushd clr
mkdir build
cd build

export CXXFLAGS="$CXXFLAGS -I$SRC_DIR/clr/opencl/khronos/headers/opencl2.2/"

install $SRC_DIR/clr/rocclr/platform/prof_protocol.h $PREFIX/include

cmake -LAH \
  ${CMAKE_ARGS} \
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

FILES_TO_REMOVE="
    lib/libOpenCL.so.1.2
    lib/libcltrace.so
    include/CL/cl.hpp
    include/CL/cl2.hpp
    include/prof_protocol.h
    share/doc/opencl/LICENSE.txt
    share/doc/opencl-asan/LICENSE.txt
    bin/clinfo"

DIRS_TO_REMOVE="
    include/CL
    share/doc/opencl
    share/doc/opencl-asan"

for FILE in $FILES_TO_REMOVE
do
  rm "$PREFIX/$FILE"
done

for DIR in $DIRS_TO_REMOVE
do 
  rmdir "$PREFIX/$DIR"
done

popd

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/activate/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done
