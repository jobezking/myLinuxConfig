#!/usr/bin/env python3.13
import sys
import subprocess
import os

def upscale_with_nvenc(input_file):
    base, ext = os.path.splitext(input_file)
    ext = ext.lower()

    if ext not in [".mp4", ".mkv"]:
        print(f"Unsupported file extension: {ext}. Use .mp4 or .mkv.")
        sys.exit(1)

    output_file = f"{base}_upscaled_4k60.mp4"

    # ffmpeg NVENC pipeline:
    # - hwaccel CUDA for decode (if supported)
    # - scale on GPU with scale_cuda
    # - encode with h264_nvenc
    cmd = [
        "ffmpeg",
        "-y",
        "-hwaccel", "cuda",
        "-hwaccel_output_format", "cuda",
        "-i", input_file,
        "-vf", "scale_cuda=w=3840:h=2160,fps=60",
        "-c:v", "h264_nvenc",
        "-preset", "p4",          # quality/speed balance (p1 slowest → p7 fastest)
        "-b:v", "10M",            # adjust as needed (e.g., 20M for higher quality)
        "-c:a", "copy",
        output_file
    ]

    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)
    print(f"Upscaled video saved as {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3.13 video_upscaler_nvenc.py <video_file(.mp4|.mkv)>")
        sys.exit(1)
    upscale_with_nvenc(sys.argv[1])
