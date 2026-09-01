# NVIDIA CUDA 13.2

Lumina splits NVIDIA's Jetson CUDA payload into two RPMs:

- `nvidia-cuda-runtime` contains the complete CUDA runtime library set;
- `nvidia-cuda-toolkit` contains nvcc, headers, development libraries, CUPTI,
  cuda-gdb, Compute Sanitizer, and command-line inspection tools.

The pinned source-package manifest is
`jetson/tools/cuda-13.2.packages`. Generate both deterministic source archives
with:

```bash
jetson/tools/grab_cuda_13_2.sh
```

The source archives retain NVIDIA's `/usr/local/cuda-13.2` layout. Lumina owns
the `/usr/local/cuda` and `/usr/local/cuda-13` symlinks instead of invoking
Debian's `update-alternatives`. Nsight GUI applications are excluded from the
base image because they add hundreds of megabytes and are not required to
compile, debug, profile through CUPTI, or execute CUDA programs.
