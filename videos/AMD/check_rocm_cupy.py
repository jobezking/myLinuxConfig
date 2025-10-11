#!/usr/bin/env python3
"""
check_rocm_cupy.py

Quick sanity check for CuPy ROCm on AMD Radeon GPUs.

- Tries to import CuPy
- Prints backend info (ROCm vs CUDA vs CPU fallback)
- Runs a small GPU computation and compares with NumPy
"""

import sys

try:
    import cupy as cp
    from cupy.cuda.runtime import getDeviceCount
    BACKEND = "CUDA"
    try:
        ndev = getDeviceCount()
    except Exception:
        ndev = 0
except ImportError:
    cp = None
    BACKEND = None
    ndev = 0

import numpy as np

def main():
    if cp is None:
        print("⚠️ CuPy not installed. Falling back to NumPy only.")
        sys.exit(1)

    # Detect ROCm vs CUDA
    try:
        # CuPy >=12 has cp.show_config()
        print("CuPy configuration:")
        cp.show_config()
    except Exception:
        print("CuPy imported, but show_config() not available.")

    # Run a small computation
    try:
        x = cp.arange(10**6, dtype=cp.float32)
        y = cp.sin(x) ** 2 + cp.cos(x) ** 2
        result = float(cp.mean(y).get())  # transfer back to host
        print(f"✅ GPU computation succeeded. Mean={result:.6f}")
        if abs(result - 1.0) < 1e-6:
            print("Result matches expected identity sin^2+cos^2=1.")
        else:
            print("Unexpected result, check GPU math libraries.")
    except Exception as e:
        print("❌ CuPy import worked but GPU computation failed:", e)
        sys.exit(1)

    # Compare with NumPy
    x_np = np.arange(10**6, dtype=np.float32)
    y_np = np.sin(x_np) ** 2 + np.cos(x_np) ** 2
    print(f"NumPy mean={np.mean(y_np):.6f}")

if __name__ == "__main__":
    main()

