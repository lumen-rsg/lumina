#!/usr/bin/python3
"""Probe EGL initialization on a DRM node without a running compositor."""

import ctypes
import os
import sys


EGL_PLATFORM_GBM_KHR = 0x31D7
EGL_EXTENSIONS = 0x3055
EGL_VENDOR = 0x3053
EGL_VERSION = 0x3054


def main() -> int:
    node = sys.argv[1] if len(sys.argv) > 1 else "/dev/dri/card2"
    gbm = ctypes.CDLL("libgbm.so.1")
    egl = ctypes.CDLL("libEGL.so.1")

    gbm.gbm_create_device.argtypes = [ctypes.c_int]
    gbm.gbm_create_device.restype = ctypes.c_void_p
    gbm.gbm_device_get_backend_name.argtypes = [ctypes.c_void_p]
    gbm.gbm_device_get_backend_name.restype = ctypes.c_char_p
    gbm.gbm_device_destroy.argtypes = [ctypes.c_void_p]

    egl.eglGetPlatformDisplay.argtypes = [
        ctypes.c_uint,
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_int),
    ]
    egl.eglGetPlatformDisplay.restype = ctypes.c_void_p
    egl.eglInitialize.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_int),
        ctypes.POINTER(ctypes.c_int),
    ]
    egl.eglInitialize.restype = ctypes.c_uint
    egl.eglGetError.restype = ctypes.c_uint
    egl.eglQueryString.argtypes = [ctypes.c_void_p, ctypes.c_int]
    egl.eglQueryString.restype = ctypes.c_char_p
    egl.eglTerminate.argtypes = [ctypes.c_void_p]

    open_flags = os.O_RDWR | os.O_CLOEXEC
    if os.environ.get("PROBE_NONBLOCK") == "1":
        open_flags |= os.O_NONBLOCK
    fd = os.open(node, open_flags)
    device = gbm.gbm_create_device(fd)
    if not device:
        print(f"gbm_create_device({node}) failed", file=sys.stderr)
        os.close(fd)
        return 1
    backend = gbm.gbm_device_get_backend_name(device)
    print(f"GBM backend: {backend.decode() if backend else '(unknown)'}")

    display = egl.eglGetPlatformDisplay(EGL_PLATFORM_GBM_KHR, device, None)
    if not display:
        print(f"eglGetPlatformDisplay failed: 0x{egl.eglGetError():04x}")
        gbm.gbm_device_destroy(device)
        os.close(fd)
        return 1

    major = ctypes.c_int()
    minor = ctypes.c_int()
    if not egl.eglInitialize(display, ctypes.byref(major), ctypes.byref(minor)):
        print(f"eglInitialize failed: 0x{egl.eglGetError():04x}")
        gbm.gbm_device_destroy(device)
        os.close(fd)
        return 1

    print(f"EGL initialized: {major.value}.{minor.value}")
    for name, query in (
        ("vendor", EGL_VENDOR),
        ("version", EGL_VERSION),
        ("extensions", EGL_EXTENSIONS),
    ):
        value = egl.eglQueryString(display, query)
        print(f"{name}: {value.decode() if value else '(none)'}")

    egl.eglTerminate(display)
    gbm.gbm_device_destroy(device)
    os.close(fd)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
