#!/usr/bin/env python3.13
import sys
import subprocess
import os

def upscale_with_vaapi(input_file):
    base, ext = os.path.splitext(input_file)
    ext = ext.lower()

    if ext not in [".mp4", ".mkv"]:
        print(f"Unsupported file extension: {ext}. Use .mp4 or .mkv.")
        sys.exit(1)

    output_file = f"{base}_upscaled_4k60.mp4"

    # ffmpeg VAAPI pipeline:
    # - select VAAPI device
    # - convert to NV12, upload to GPU, scale via scale_vaapi, set fps
    # - encode with h264_vaapi
    cmd = [
        "ffmpeg",
        "-y",
        "-hwaccel", "vaapi",
        "-vaapi_device", "/dev/dri/renderD128",
        "-i", input_file,
        "-vf", "format=nv12,hwupload,scale_vaapi=w=3840:h=2160,fps=60",
        "-c:v", "h264_vaapi",
        "-b:v", "10M",
        "-c:a", "copy",
        output_file
    ]

    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)
    print(f"Upscaled video saved as {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3.13 video_upscaler_vaapi.py <video_file(.mp4|.mkv)>")
        sys.exit(1)
    upscale_with_vaapi(sys.argv[1])
