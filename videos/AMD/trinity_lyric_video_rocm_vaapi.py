#!/usr/bin/env python3
"""
trinity_lyric_video_rocm_vaapi.py

4K lyric-video generator tuned for AMD Radeon 680M (ROCm compute + VAAPI encoding).

- Uses CuPy ROCm when available (falls back to NumPy)
- Prints a startup sanity check of CuPy/ROCm GPU availability
- Optimized starfield scatter using a single-channel accumulation buffer
- Pillow >=10-safe text sizing
- Reads lyrics from `lyrics.csv` (auto-creates a sample if missing)
- Always renders at 4K (3840x2160)

Usage:
    python trinity_lyric_video_rocm_vaapi.py --audio "song.mp3" --output out_4k_vaapi.mp4
"""

import argparse, math, subprocess, sys, os, csv
from functools import partial

os.environ.setdefault("IMAGEIO_FFMPEG_EXE", "/usr/bin/ffmpeg")

# ---------------- GPU compute backend ----------------
GPU_ENABLED = False
try:
    import cupy as cp
    from cupy import asnumpy as cp_asnumpy
    GPU_ENABLED = True
except Exception:
    import numpy as cp
    def cp_asnumpy(x): return
