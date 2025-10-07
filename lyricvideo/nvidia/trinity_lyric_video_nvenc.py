#!/usr/bin/env python3
"""
trinity_lyric_video_nvidia2.py

Optimized 4K lyric-video generator tuned for NVIDIA GeForce RTX 4060 Mobile (8GB VRAM).

- Uses CuPy when available (falls back to NumPy)
- Optimized starfield scatter using a single-channel accumulation buffer
- Pillow >=10-safe text sizing via ImageDraw.textbbox
- Reads lyrics from a separate CSV file `lyrics.csv` (auto-creates a sample if missing)
- Always renders at 4K (3840x2160) as requested

Usage:
    python3.13 trinity_lyric_video_nvidia2.py --audio "TheTrinity.mp3" --output trinity_4k_nv.mp4

If `lyrics.csv` doesn't exist, the script will create `lyrics_sample.csv` and exit with instructions.

Requirements (suggested):
    moviepy==1.0.3  # if you want moviepy.editor import compatibility
    pillow>=9.0.0
    numpy
    cupy-cuda12x (optional for GPU acceleration)
    ffmpeg with nvenc support for h264_nvenc

"""

import argparse
import math
import subprocess
import sys
import os
import csv
from functools import partial

os.environ.setdefault("IMAGEIO_FFMPEG_EXE", "/usr/bin/ffmpeg")
# GPU support (CuPy) with graceful fallback to NumPy
GPU_ENABLED = False
try:
    import cupy as cp  # type: ignore
    from cupy import asnumpy as cp_asnumpy  # type: ignore
    GPU_ENABLED = True
    print("✅ CuPy detected. GPU acceleration for procedural rendering enabled.")
except Exception:
    import numpy as cp  # alias as cp so code can stay unified
    def cp_asnumpy(x):
        return x
    print("⚠️ CuPy not found. Falling back to NumPy (CPU rendering).")

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# moviepy 1.x import path
try:
    from moviepy.editor import AudioFileClip, VideoClip, ImageClip, CompositeVideoClip
except Exception:
    # try fallback for some environments
    from moviepy.video.io.AudioFileClip import AudioFileClip  # type: ignore
    from moviepy.video.VideoClip import VideoClip  # type: ignore
    from moviepy.video.io.ImageClip import ImageClip  # type: ignore
    from moviepy.video.compositing.CompositeVideoClip import CompositeVideoClip  # type: ignore

# --------------------------------
# Config (4K fixed)
# --------------------------------
W, H = 3840, 2160
FPS = 30

# Fonts (fall back to default if not available)
try:
    TITLE_FONT = ImageFont.truetype("DejaVuSans-Bold.ttf", 160)
    BODY_FONT = ImageFont.truetype("DejaVuSans.ttf", 120)
    GLOW_FONT = ImageFont.truetype("DejaVuSans-Bold.ttf", 140)
except Exception:
    TITLE_FONT = ImageFont.load_default()
    BODY_FONT = ImageFont.load_default()
    GLOW_FONT = ImageFont.load_default()

# --------------------------------
# Lyrics CSV handling
# CSV format: start_seconds,line,optional_highlight
# --------------------------------
LYRICS_CSV = "lyrics.csv"
SAMPLE_CSV = "lyrics_sample.csv"

def create_sample_csv(path=SAMPLE_CSV):
    sample = [
        (0.13, "Co-eternal, co-equal, sovereign one", ""),
        (0.16, "The Father is fundamentally the one entity", ""),
        (0.19, "Equipped to speak in history with no audible tongue", ""),
        (0.21, "And when He speaks, yo, it’s got to be done", ""),
        (0.23, "The obvious conclusion is there’s one ruler", "")
    ]
    with open(path, "w", newline='', encoding='utf-8') as fh:
        w = csv.writer(fh)
        w.writerow(["start", "text", "highlight"])  # header
        for r in sample:
            w.writerow([r[0], r[1], r[2]])

    print(f"Sample CSV written to '{path}'. Edit/rename it to '{LYRICS_CSV}' or create your own and re-run.")

def load_lyrics(path=LYRICS_CSV):
    if not os.path.exists(path):
        create_sample_csv()
        sys.exit(0)

    rows = []
    with open(path, encoding='utf-8') as fh:
        r = csv.DictReader(fh)
        for row in r:
            try:
                st = float(row.get('start') or row.get('time') or row.get('timestamp'))
            except Exception:
                continue
            text = row.get('text') or row.get('line') or ''
            highlight = row.get('highlight') or None
            rows.append((st, text, highlight))
    rows.sort(key=lambda x: x[0])
    return rows

LYRICS = load_lyrics()

# --------------------------------
# Utility: check ffmpeg nvenc support
# --------------------------------

def nvenc_available():
    try:
        out = subprocess.run(["ffmpeg", "-hide_banner", "-encoders"], capture_output=True, text=True, check=True)
        return ("h264_nvenc" in out.stdout) or ("hevc_nvenc" in out.stdout)
    except Exception:
        return False

NVENC = nvenc_available()
if NVENC:
    print("✅ FFmpeg NVENC support detected. Will use h264_nvenc when rendering.")
else:
    print("⚠️ NVENC not detected. Will use libx264 (CPU) for encoding.")

# --------------------------------
# Precompute star positions (GPU-friendly arrays)
# --------------------------------

def generate_starfield_positions(n_stars=1400, seed=2025):
    # use cp random; if cp is numpy this still works
    try:
        rng = cp.random.RandomState(seed) if hasattr(cp.random, "RandomState") else cp.random
    except Exception:
        rng = cp.random
    xs = rng.rand(n_stars).astype(cp.float32) * W
    ys = rng.rand(n_stars).astype(cp.float32) * H
    sizes = (0.6 + rng.rand(n_stars).astype(cp.float32) * 3.0)
    brightness = (0.6 + rng.rand(n_stars).astype(cp.float32) * 0.4)
    return cp.stack((xs, ys, sizes, brightness), axis=1)  # shape (n,4)

STAR_POS = generate_starfield_positions(1400, seed=2025)

# --------------------------------
# Procedural GPU (or CPU) background generation - HYBRID (cosmic + geometric)
# Uses 'cp' (CuPy if available, otherwise NumPy)
# --------------------------------

def hybrid_frame_gpu(t):
    t = float(t)

    # 1) Cosmic base using sin/cos noise on grid
    nx, ny = 960, 540
    xs = cp.linspace(0.0, 6.0, nx, dtype=cp.float32)
    ys = cp.linspace(0.0, 6.0, ny, dtype=cp.float32)
    X, Y = cp.meshgrid(xs, ys)
    Z = (cp.sin(X * 1.2 + t * 0.35) * cp.cos(Y * 0.8 + t * 0.25)).astype(cp.float32)
    Z = (Z - Z.min()) / (Z.max() - Z.min() + 1e-9)

    # dynamic palette
    if 0.13 <= t < 1.29:
        base_color = cp.array([30, 60, 180], dtype=cp.float32)
        accent = cp.array([200, 160, 80], dtype=cp.float32)
    elif 1.29 <= t < 2.27:
        base_color = cp.array([120, 50, 40], dtype=cp.float32)
        accent = cp.array([200, 100, 60], dtype=cp.float32)
    elif 2.53 <= t:
        base_color = cp.array([220, 120, 40], dtype=cp.float32)
        accent = cp.array([40, 200, 200], dtype=cp.float32)
    else:
        base_color = cp.array([40, 60, 90], dtype=cp.float32)
        accent = cp.array([150, 150, 180], dtype=cp.float32)

    Z3 = Z[:, :, None] * (base_color[None, None, :] + accent[None, None, :] * (0.5 + 0.5 * cp.sin(t * 0.6)))
    Z3_up = cp.kron(Z3, cp.ones((H // ny, W // nx, 1), dtype=Z3.dtype))

    # 2) Geometric overlays
    xv = (cp.arange(W, dtype=cp.float32) - W/2) / (W/2)
    yv = (cp.arange(H, dtype=cp.float32) - H/2) / (H/2)
    XX, YY = cp.meshgrid(xv, yv)
    buff = Z3_up * 0.6

    for i in range(3):
        angle = t * (0.2 + 0.15 * i) + i * 1.5
        ca = math.cos(angle); sa = math.sin(angle)
        XR = ca * XX - sa * YY
        YR = sa * XX + ca * YY
        tri = cp.clip(1.0 - (cp.abs(XR) * 1.8 + 0.9 * cp.abs(YR)), 0.0, 1.0)
        col = base_color * (0.06 + 0.04 * (i+1)) + accent * (0.02 + 0.01 * i)
        buff = buff + tri[:, :, None] * col[None, None, :]

    # 3) Optimized Starfield (single-channel accumulation + tint)
    shift_x = (t * 18.0) % float(W)
    shift_y = (t * 9.0) % float(H)
    sp = STAR_POS
    xs = (sp[:, 0] + shift_x) % float(W)
    ys = (sp[:, 1] + shift_y) % float(H)
    bright = sp[:, 3].astype(cp.float32)

    ix = xs.astype(cp.int32)
    iy = ys.astype(cp.int32)

    # single-channel accumulation buffer (faster and less memory churn on GPU)
    star_buf = cp.zeros((H, W), dtype=cp.float32)

    # Vectorized scatter across small kernel - uses advanced indexing; faster than repeated channel ops
    # We precompute offsets and weights to distribute brightness to neighbors
    offsets = [(dx, dy, max(0.0, 3.0 - 0.7 * (abs(dx) + abs(dy)))) for dy in range(-2, 3) for dx in range(-2, 3)]
    for dx, dy, w in offsets:
        if w <= 0:
            continue
        xidx = cp.clip(ix + dx, 0, W - 1)
        yidx = cp.clip(iy + dy, 0, H - 1)
        # accumulate into single channel
        # Note: if indices repeat, CuPy advanced-index assignment will add the provided values to selected positions.
        star_buf[yidx, xidx] += bright * cp.float32(w)

    # expand to RGB with a subtle tint for variety and scale
    tint = cp.array([1.0, 1.05, 1.15], dtype=cp.float32)
    buff = buff + star_buf[:, :, None] * tint[None, None, :] * 110.0

    # 4) Tone mapping & clamp to uint8
    buff = cp.clip(buff, 0.0, 255.0)
    out_rgb = buff.astype(cp.uint8)
    return cp_asnumpy(out_rgb)

# wrapper for MoviePy
def frame_generator(t):
    arr = hybrid_frame_gpu(t)
    if arr.dtype != np.uint8:
        arr = arr.astype(np.uint8)
    return arr

# --------------------------------
# Text helpers (Pillow-safe across versions)
# --------------------------------

def create_text_image(text, w=W, h=H, fontsize=120, color=(255,255,255), glow=None):
    img = Image.new("RGBA", (w, h), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    font = BODY_FONT if fontsize < 160 else TITLE_FONT

    lines = text.split("\n")
    line_h = fontsize + 6
    y = int(h * 0.58 - (len(lines) * line_h) // 2)
    for line in lines:
        # Pillow >=10: textbbox; older versions: textsize
        if hasattr(draw, 'textbbox'):
            bbox = draw.textbbox((0, 0), line, font=font)
            w_text = bbox[2] - bbox[0]
        else:
            w_text, _ = draw.textsize(line, font=font)
        x = (w - w_text) // 2
        draw.text((x, y), line, font=font, fill=color)
        y += line_h

    if glow:
        blurred = img.filter(ImageFilter.GaussianBlur(radius=glow.get('radius', 10)))
        tint = Image.new('RGBA', img.size, glow.get('color', (255,200,80,140)))
        glow_img = Image.composite(tint, blurred, blurred)
        out = Image.alpha_composite(glow_img, img)
        return out
    return img


def make_text_clip(line, start, end, highlight=None):
    duration = max(0.2, end - start)
    glow = {'color': (255,220,120,160), 'radius': 10} if highlight else None
    img = create_text_image(line, fontsize=120, color=(255,255,255), glow=glow)
    clip = ImageClip(np.array(img)).set_start(start).set_duration(duration).set_position(("center", int(H*0.58)))
    clip = clip.crossfadein(0.05).crossfadeout(0.08)
    return clip


def create_title_clip(duration=12.0):
    img = create_text_image("The Trinity\n(Artist Name)", fontsize=160, color=(255,240,220))
    clip = ImageClip(np.array(img)).set_start(0.0).set_duration(duration).set_position(("center", int(H*0.45))).fadein(0.4).fadeout(0.6)
    return clip


def create_trinity_symbol_clip(duration, fps=FPS):
    img = Image.new("RGBA", (W, H), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    cx, cy = W//2, H//2
    base_r = int(W * 0.24)
    offsets = [(-base_r//2, 0), (base_r//2, 0), (0, -base_r//3)]
    for i, (ox, oy) in enumerate(offsets):
        bbox = (cx+ox-base_r, cy+oy-base_r, cx+ox+base_r, cy+oy+base_r)
        draw.ellipse(bbox, outline=(255,255,255,160), width=14)
    cross_r = int(base_r * 0.35)
    draw.rectangle((cx-cross_r, cy-24, cx+cross_r, cy+24), fill=(255,255,255,48))
    return ImageClip(np.array(img)).set_start(0).set_duration(duration).set_position(("center","center")).set_opacity(0.92)

# --------------------------------
# Assemble video
# --------------------------------

def build_video(audio_path, output_path):
    audio = AudioFileClip(audio_path)
    duration = audio.duration

    print("Building procedural base clip (GPU)" if GPU_ENABLED else "Building procedural base clip (CPU)")
    base_clip = VideoClip(frame_generator, ismask=False).set_duration(duration).set_fps(FPS)

    title_clip = create_title_clip(duration=12.0)
    trinity_symbol = create_trinity_symbol_clip(duration=duration)

    # Prepare lyric text clips
    sorted_lyrics = LYRICS
    starts = [s for s, *_ in sorted_lyrics]
    ends = []
    for i, s in enumerate(starts):
        if i < len(starts) - 1:
            ends.append(starts[i+1] - 0.02)
        else:
            ends.append(min(duration, s + 3.0))

    lyric_clips = []
    for idx, entry in enumerate(sorted_lyrics):
        st = starts[idx]
        end = ends[idx]
        highlight = entry[2] if len(entry) >= 3 else None
        lyric_clips.append(make_text_clip(entry[1], st, end, highlight=highlight))

    clips = [base_clip, title_clip, trinity_symbol] + lyric_clips
    comp = CompositeVideoClip(clips, size=(W, H)).set_duration(duration).set_audio(audio)

    if NVENC:
        codec = "h264_nvenc"
        preset = "p4"  # p1 = slowest (best), p7 = fastest
        ffmpeg_params = ["-preset", "p4", "-b:v", "20M", "-maxrate", "25M", "-bufsize", "40M", "-pix_fmt", "yuv420p"]
        threads = 2
    else:
        codec = "libx264"
        preset = "slow"
        ffmpeg_params = ["-crf", "18", "-pix_fmt", "yuv420p"]
        threads = 0

    print("Starting render to:", output_path)
    print(f"Using codec={codec}, preset={preset}, GPU frame generation={'yes' if GPU_ENABLED else 'no'}")

    comp.write_videofile(
        output_path,
        codec=codec,
        audio_codec="aac",
        fps=FPS,
        preset=preset,
        threads=threads,
        ffmpeg_params=ffmpeg_params,
    )

# --------------------------------
# CLI
# --------------------------------

def main():
    parser = argparse.ArgumentParser(description="Generate Trinity lyric video (4K, CUDA-accelerated if available).")
    parser.add_argument("--audio", required=True, help="Path to mp3 file (e.g., TheTrinity.mp3).")
    parser.add_argument("--output", default="trinity_4k_nv.mp4", help="Output MP4 filename.")
    args = parser.parse_args()

    if not os.path.exists(args.audio):
        print(f"Audio file not found: {args.audio}")
        sys.exit(1)

    build_video(args.audio, args.output)

if __name__ == "__main__":
    main()
