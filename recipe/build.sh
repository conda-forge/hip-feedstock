#!/bin/bash

set -xeuo pipefail

export ROCM_LIBPATCH_VERSION=${PKG_VERSION//\./0}
export HIP_CLANG_PATH=${PREFIX}/bin

# CMAKE_DISABLE_FIND_PACKAGE_Git: the build directory sits inside the feedstock
# git checkout, so without this the CLR/hipcc CMake code picks up the feedstock's
# commit hash and bakes it into the library and package version strings.
# HIPCC_BACKWARD_COMPATIBILITY: the legacy hip/bin directory of symlinks is not
# shipped.
pushd hipcc/amd/hipcc
mkdir build
cd build
cmake ${CMAKE_ARGS} \
  -DCMAKE_REQUIRE_FIND_PACKAGE_ROCM=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_Git=ON \
  -DHIPCC_BACKWARD_COMPATIBILITY=OFF \
  ..
make VERBOSE=1 -j${CPU_COUNT}
make install
popd

pushd clr
mkdir build
cd build

export CXXFLAGS="$CXXFLAGS -I$SRC_DIR/clr/opencl/khronos/headers/opencl2.2 -I$SRC_DIR/clr/opencl/khronos/headers/opencl2.2/CL"

install $SRC_DIR/clr/rocclr/platform/prof_protocol.h $PREFIX/include

cmake -LAH \
  ${CMAKE_ARGS} \
  -DCLR_BUILD_HIP=ON \
  -DCLR_BUILD_OCL=ON \
  -DHIPCC_BIN_DIR=$PREFIX/bin \
  -DHIP_COMMON_DIR=$SRC_DIR/hip \
  -DPython_EXECUTABLE=$BUILD_PREFIX/bin/python \
  -DPython3_EXECUTABLE=$BUILD_PREFIX/bin/python \
  -DROCM_PATH=$PREFIX \
  -DAMD_OPENCL_INCLUDE_DIR=$SRC_DIR/clr/opencl/amdocl/ \
  -DHIP_ENABLE_ROCPROFILER_REGISTER=OFF \
  -DHIP_CLANG_PATH=$PREFIX/bin \
  -DCMAKE_DISABLE_FIND_PACKAGE_Git=ON \
  ..

make VERBOSE=1 -j${CPU_COUNT}
make install

# Note: CLR does not build the Khronos ICD loader (BUILD_ICD is OFF), the
# libOpenCL.so in the prefix belongs to the ocl-icd host package.
# bin/hipvars.pm is a leftover of the Perl hipcc; hipcc and hipconfig are
# compiled binaries now and nothing reads it.
# CLR also installs its vendored Khronos headers into include/CL, on top of
# the ones from opencl-headers in the host environment. None of them are
# packaged here, so remove every header CLR installs rather than leave its
# copies behind.
# The roc-obj-*.bat files are Windows helpers that CLR installs on Linux too.
FILES_TO_REMOVE="
    bin/hipvars.pm
    lib/libcltrace.so
    bin/roc-obj-extract.bat
    bin/roc-obj-ls.bat
    include/CL/cl.h
    include/CL/cl.hpp
    include/CL/cl2.hpp
    include/CL/cl_dx9_media_sharing_intel.h
    include/CL/cl_egl.h
    include/CL/cl_ext.h
    include/CL/cl_ext_intel.h
    include/CL/cl_gl.h
    include/CL/cl_gl_ext.h
    include/CL/cl_icd.h
    include/CL/cl_platform.h
    include/CL/cl_va_api_media_sharing_intel.h
    include/CL/cl_version.h
    include/CL/opencl.h
    include/prof_protocol.h
    share/doc/opencl-asan/LICENSE.md
    share/doc/hip-asan/LICENSE.md
    bin/clinfo"

DIRS_TO_REMOVE="
    share/doc/opencl-asan
    share/doc/hip-asan"

# Strict on purpose: a missing file or a non-empty directory means upstream
# renamed or added something and this list needs updating.
for FILE in $FILES_TO_REMOVE
do
  rm "$PREFIX/$FILE"
done

for DIR in $DIRS_TO_REMOVE
do
  rmdir "$PREFIX/$DIR"
done

popd

# conda-build does not rewrite Perl shebangs, so point these scripts at the
# perl of the environment instead of /usr/bin/perl.
for SCRIPT in roc-obj-ls roc-obj-extract
do
  sed -i '1s|^#!/usr/bin/perl$|#!/usr/bin/env perl|' "$PREFIX/bin/$SCRIPT"
  head -n 1 "$PREFIX/bin/$SCRIPT" | grep -qxF '#!/usr/bin/env perl'
done

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/activate/hip_${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/hip_${CHANGE}.sh"
    cp "${RECIPE_DIR}/activate/hip-rocm-clang_${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/hip-rocm-clang_${CHANGE}.sh"
done

# register the opencl implementation
mkdir -p $PREFIX/etc/OpenCL/vendors
echo "$PREFIX/lib/libamdocl64.so" >> $PREFIX/etc/OpenCL/vendors/amdocl64.icd
