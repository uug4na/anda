#!/usr/bin/env python3
"""Compose looping placeholder music for each map with numpy: a bowed drone, plucked pentatonic
melody (Karplus-Strong) and a frame drum. Output: assets/audio/music/<name>.wav, 16-bit mono.
Replace any file with a real track of the same name and the game picks it up."""
import math
import wave
import numpy as np
from pathlib import Path

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "music"
OUT.mkdir(parents=True, exist_ok=True)

# D minor pentatonic over three octaves (D3 = 146.83 Hz)
SCALE = [146.83, 174.61, 196.0, 220.0, 261.63, 293.66, 349.23, 392.0, 440.0, 523.25, 587.33]


def pluck(freq, dur, decay=0.996, rng=None):
    n = int(SR / freq)
    buf = rng.uniform(-1, 1, n)
    out = np.zeros(int(dur * SR))
    for i in range(len(out)):
        j = i % n
        out[i] = buf[j]
        buf[j] = decay * 0.5 * (buf[j] + buf[(j + 1) % n])
    return out * np.exp(-np.linspace(0, 3.0, len(out)))


def drone(freq, seconds, vib=0.4, depth=0.004):
    t = np.arange(int(seconds * SR)) / SR
    f = freq * (1.0 + depth * np.sin(2 * np.pi * vib * t))
    phase = 2 * np.pi * np.cumsum(f) / SR
    saw = sum(np.sin(k * phase) / k for k in range(1, 7))
    kernel = np.ones(24) / 24.0
    low = np.convolve(saw, kernel, mode="same")
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * 0.08 * t)
    return low * swell * 0.25


def drum(dur=0.35, rng=None):
    t = np.arange(int(dur * SR)) / SR
    f = 55 + 60 * np.exp(-t * 18)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)
    click = rng.uniform(-1, 1, len(t)) * np.exp(-t * 90) * 0.4
    return (body + click) * 0.9


def wind(seconds, rng):
    noise = rng.uniform(-1, 1, int(seconds * SR))
    kernel = np.ones(40) / 40.0
    low = np.convolve(noise, kernel, mode="same")
    t = np.arange(len(low)) / SR
    return low * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t)) * 0.5


def add(mix, sound, start):
    s = int(start * SR)
    e = min(len(mix), s + len(sound))
    if e > s:
        mix[s:e] += sound[: e - s]


def compose(name, bpm, bars, seed, drone_notes, melody_density, drum_pattern, octave_shift, wind_level):
    rng = np.random.default_rng(seed)
    beat = 60.0 / bpm
    seconds = bars * 4 * beat
    mix = np.zeros(int(seconds * SR))
    for f in drone_notes:
        mix += drone(f, seconds, vib=0.3 + rng.uniform(0, 0.2))[: len(mix)]
    # melody: random walk on the scale, eighth notes with rests
    idx = 4 + octave_shift
    step = beat / 2
    n_steps = int(seconds / step)
    for i in range(n_steps):
        if rng.uniform() > melody_density:
            continue
        idx = int(np.clip(idx + rng.choice([-2, -1, -1, 0, 1, 1, 2]), 0, len(SCALE) - 1))
        if i % 8 == 0 and rng.uniform() < 0.5:
            idx = 4 + octave_shift  # come home to the root at bar starts sometimes
        dur = step * rng.choice([1, 1, 2, 3])
        add(mix, pluck(SCALE[idx], min(dur + 0.4, 2.0), rng=rng) * 0.45, i * step)
    for b in range(bars * 4):
        for sub, vel in drum_pattern:
            if (b % 4) in [p for p, _ in [(sub, vel)]]:
                add(mix, drum(rng=rng) * vel, b * beat)
    if wind_level > 0:
        mix += wind(seconds, rng)[: len(mix)] * wind_level
    # loop-friendly edges and normalise
    fade = int(0.03 * SR)
    mix[:fade] *= np.linspace(0, 1, fade)
    mix[-fade:] *= np.linspace(1, 0, fade)
    mix = mix / (np.max(np.abs(mix)) + 1e-6) * 0.6
    data = (mix * 32767).astype("<i2").tobytes()
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(f"{name}: {seconds:.1f}s at {bpm} bpm")


# (beat index within bar, velocity) pairs that get a drum hit
QUIET = []
WALK = [(0, 0.9), (2, 0.6)]
TENSE = [(0, 0.8), (3, 0.4)]
FIGHT = [(0, 1.0), (1, 0.5), (2, 0.9), (3, 0.5)]

compose("title", 60, 8, 1, [146.83, 220.0], 0.35, QUIET, 2, 0.35)
compose("camp", 76, 8, 2, [146.83], 0.55, QUIET, 1, 0.2)
compose("overworld", 96, 8, 3, [146.83, 220.0], 0.6, WALK, 1, 0.25)
compose("riverbank", 88, 8, 4, [196.0], 0.6, QUIET, 3, 0.3)
compose("burkhan", 70, 8, 5, [146.83, 155.56], 0.4, TENSE, 0, 0.3)
compose("boss", 124, 8, 6, [146.83, 220.0], 0.7, FIGHT, 1, 0.1)
