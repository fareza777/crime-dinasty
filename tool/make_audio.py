#!/usr/bin/env python3
"""Generate CC0-style original neo-noir loops and SFX (no third-party samples)."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

import numpy as np

OUT = Path("/workspace/assets/sfx")
MUSIC = Path("/workspace/assets/music")
SR = 22050


def save_wav(path: Path, samples: np.ndarray, sr: int = SR) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    print(path, path.stat().st_size)


def env(n: int, attack: float, release: float) -> np.ndarray:
    a = min(n // 3, int(SR * attack))
    r = min(n // 3, int(SR * release))
    e = np.ones(n, dtype=np.float32)
    if a > 0:
        e[:a] = np.linspace(0, 1, a)
    if r > 0:
        e[-r:] = np.linspace(1, 0, r)
    return e


def tone(freq: float, dur: float, vol: float = 0.2, kind: str = "sine") -> np.ndarray:
    n = int(SR * dur)
    t = np.arange(n) / SR
    if kind == "tri":
        s = 2 * np.abs(2 * ((t * freq) % 1) - 1) - 1
    elif kind == "sq":
        s = np.sign(np.sin(2 * math.pi * freq * t))
    else:
        s = np.sin(2 * math.pi * freq * t)
    return (s * vol * env(n, 0.01, min(0.12, dur * 0.4))).astype(np.float32)


def noise(dur: float, vol: float = 0.08) -> np.ndarray:
    n = int(SR * dur)
    rng = np.random.default_rng(7)
    x = rng.normal(0, 1, n).astype(np.float32)
    # simple lowpass
    for _ in range(3):
        x = np.convolve(x, np.ones(24) / 24, mode="same")
    return x * vol * env(n, 0.02, 0.08)


def ambient_loop() -> np.ndarray:
    dur = 18.0
    n = int(SR * dur)
    t = np.arange(n) / SR
    rng = np.random.default_rng(1998)
    rain = rng.normal(0, 1, n).astype(np.float32)
    rain = np.convolve(rain, np.ones(18) / 18, mode="same") * 0.045
    # slow drones in A minor
    drones = (
        0.07 * np.sin(2 * math.pi * 55 * t)
        + 0.05 * np.sin(2 * math.pi * 82.4 * t + 0.3)
        + 0.035 * np.sin(2 * math.pi * 110 * t + 1.1)
        + 0.02 * np.sin(2 * math.pi * 164.8 * t + 0.6)
    )
    # sparse "piano" hits
    hits = np.zeros(n, dtype=np.float32)
    notes = [220, 261.6, 293.7, 329.6, 196, 246.9]
    for i, f in enumerate(notes):
        start = int((1.8 + i * 2.6) * SR)
        frag = tone(f, 1.4, 0.045, "tri")
        end = min(n, start + len(frag))
        hits[start:end] += frag[: end - start]
    # fade edges for seamless-ish loop
    fade = int(SR * 0.8)
    drones[:fade] *= np.linspace(0.4, 1, fade)
    drones[-fade:] *= np.linspace(1, 0.4, fade)
    rain[:fade] *= np.linspace(0.5, 1, fade)
    rain[-fade:] *= np.linspace(1, 0.5, fade)
    out = rain + drones + hits
    return (out / (np.max(np.abs(out)) + 1e-6) * 0.55).astype(np.float32)


def main() -> None:
    save_wav(MUSIC / "ambience.wav", ambient_loop())
    save_wav(OUT / "heat.wav", tone(185, 0.28, 0.22) + tone(196, 0.28, 0.16) + noise(0.28, 0.04))
    m1 = tone(880, 0.08, 0.2, "tri")
    m2 = tone(1174, 0.1, 0.16, "tri")
    money = np.zeros(len(m1) + int(0.06 * SR) + len(m2), dtype=np.float32)
    money[: len(m1)] += m1
    money[int(0.06 * SR) : int(0.06 * SR) + len(m2)] += m2
    save_wav(OUT / "money.wav", money)
    c1 = tone(392, 0.09, 0.18)
    c2 = tone(523, 0.12, 0.16)
    conf = np.zeros(len(c1) + int(0.05 * SR) + len(c2), dtype=np.float32)
    conf[: len(c1)] += c1
    conf[int(0.05 * SR) : int(0.05 * SR) + len(c2)] += c2
    save_wav(OUT / "confirm.wav", conf)
    print("audio written")


if __name__ == "__main__":
    main()
