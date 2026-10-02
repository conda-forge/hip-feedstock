export HIPCXX_CONDA_BACKUP=${HIPCXX:-}
export HIPCXX=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-clang

# Default ROCm GPU targets used by conda-forge packages.
# The list is given by the official architectures supported by ROCm 7.2.4, see:
# * https://rocm.docs.amd.com/projects/install-on-linux/en/docs-7.2.4/reference/system-requirements.html
# * https://rocm.docs.amd.com/projects/radeon-ryzen/en/docs-6.4.4/docs/compatibility/compatibilityryz/native_linux/native_linux_compatibility.html
# The ryzen link is the one for ROCm 6.4.4, but it is actually the one linked by ROCm 7.2.4 docs
export CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS_CONDA_BACKUP=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS:-}
export CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS="gfx908;gfx90a;gfx942;gfx950;gfx1030;gfx1100;gfx1101;gfx1150;gfx1151;gfx1200;gfx1201"
