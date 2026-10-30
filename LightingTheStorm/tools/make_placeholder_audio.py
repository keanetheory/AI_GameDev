"""make_placeholder_audio.py - synthesises the Gate 1 placeholder sounds (backlog T14) into Assets/Audio/placeholder/.

Everything is generated here from noise and sine partials with numpy, so there is no third-party audio and no licence to
track: the output is released as CC0 by the project. Loops are built in the frequency domain with whole-cycle modulation, so they
repeat exactly. Run:  python tools/make_placeholder_audio.py   (re-run to regenerate; the seed is fixed).
"""
import wave
from pathlib import Path

import numpy as np

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "Assets" / "Audio" / "placeholder"
rng = np.random.default_rng(20261029)


def shaped_noise(seconds, lo, hi, tilt=0.0, seed_shift=0):
    """Periodic band-limited noise: random-phase spectrum between lo and hi Hz with a 1/f**tilt slope."""
    n = int(SR * seconds)
    freqs = np.fft.rfftfreq(n, 1.0 / SR)
    rise = np.clip((freqs - lo * 0.7) / (lo * 0.6 + 1.0), 0.0, 1.0)
    fall = np.clip((hi * 1.3 - freqs) / (hi * 0.6 + 1.0), 0.0, 1.0)
    amp = rise * fall / np.maximum(freqs, 1.0) ** tilt
    amp[0] = 0.0
    phase = np.exp(2j * np.pi * rng.random(len(freqs)))
    x = np.fft.irfft(amp * phase, n)
    return x / (np.max(np.abs(x)) + 1e-9)


def lfo(seconds, cycles, depth, phase=0.0):
    t = np.arange(int(SR * seconds)) / (SR * seconds)
    return 1.0 - depth + depth * 0.5 * (1.0 + np.sin(2 * np.pi * cycles * t + phase))


def norm(x, peak=0.8):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def save(name, x):
    OUT.mkdir(parents=True, exist_ok=True)
    pcm = np.clip(x, -1.0, 1.0)
    data = (pcm * 32767).astype("<i2")
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wrote", name, "%.1f s" % (len(x) / SR), "%d KB" % (len(data) * 2 // 1024))


def wind():
    secs = 12.0
    body = shaped_noise(secs, 120, 900, tilt=0.8)
    hiss = shaped_noise(secs, 900, 4000, tilt=1.2) * 0.25
    gust = lfo(secs, 3, 0.55, 0.3) * lfo(secs, 7, 0.25, 1.1) * lfo(secs, 1, 0.3, 2.0)
    t = np.arange(int(SR * secs)) / SR
    whistle = np.sin(2 * np.pi * (520 + 40 * np.sin(2 * np.pi * 2 * t / secs * 1.0)) * t) * 0.04 * lfo(secs, 5, 0.9, 0.7)
    return norm((body + hiss) * gust + whistle, 0.7)


def rain():
    secs = 8.0
    hiss = shaped_noise(secs, 1800, 9000, tilt=0.1)
    n = len(hiss)
    drops = np.zeros(n)
    idx = rng.integers(0, n - 200, size=int(secs * 220))
    for i in idx:
        k = rng.integers(20, 90)
        drops[i:i + k] += (rng.random() * 0.8) * np.exp(-np.arange(k) / (k / 4.0)) * np.sign(rng.standard_normal(k))
    patter = shaped_noise(secs, 300, 1500, tilt=0.5) * 0.15
    return norm(hiss * 0.5 + drops * 0.5 + patter, 0.6)


def machinery():
    secs = 8.0
    t = np.arange(int(SR * secs)) / SR
    rumble = shaped_noise(secs, 25, 140, tilt=0.3) * 0.9
    hum = sum(np.sin(2 * np.pi * f * t) * a for f, a in ((50, 0.5), (100, 0.35), (150, 0.2), (250, 0.08)))
    whine = np.sin(2 * np.pi * 437.5 * t + 2 * np.sin(2 * np.pi * 0.5 * t)) * 0.07 * lfo(secs, 2, 0.4)
    steam = shaped_noise(secs, 2500, 7000, tilt=0.2) * 0.12 * lfo(secs, 8, 0.6)
    thump = np.zeros_like(t)
    for k in range(int(secs * 2)):           # the boiler's slow beat, twice a second
        s = int(k * SR / 2)
        L = int(SR * 0.25)
        thump[s:s + L] += np.sin(2 * np.pi * 55 * np.arange(L) / SR) * np.exp(-np.arange(L) / (SR * 0.07)) * 0.5
    return norm(rumble + hum + whine + steam + thump, 0.7)


def engine():
    secs = 4.0
    t = np.arange(int(SR * secs)) / SR
    out = np.zeros_like(t)
    for k in range(int(secs * 4)):           # a steam launch chugging four times a second
        s = int(k * SR / 4)
        L = int(SR * 0.2)
        env = np.exp(-np.arange(L) / (SR * 0.045))
        out[s:s + L] += (np.sin(2 * np.pi * 70 * np.arange(L) / SR) * 0.8 + shaped_noise(0.2, 200, 1400)[:L] * 0.5) * env * (1.0 if k % 2 == 0 else 0.7)
    hiss = shaped_noise(secs, 2000, 6000) * 0.07
    return norm(out + hiss, 0.7)


def bell():
    secs = 5.0
    t = np.arange(int(SR * secs)) / SR
    base = 420.0
    parts = ((0.5, 0.45, 2.6), (1.0, 1.0, 2.0), (1.19, 0.6, 1.7), (1.5, 0.5, 1.5), (2.0, 0.55, 1.2), (2.54, 0.3, 1.0), (3.0, 0.22, 0.8), (4.1, 0.14, 0.6))
    x = sum(a * np.sin(2 * np.pi * base * r * t + r) * np.exp(-t * d) for r, a, d in parts)
    x += 0.03 * np.sin(2 * np.pi * (base * 1.01) * t) * np.exp(-t * 2.0)       # a little beating
    x *= np.minimum(t / 0.004, 1.0)
    return norm(x, 0.8)


def foghorn():
    secs = 4.5
    t = np.arange(int(SR * secs)) / SR
    env = np.clip(t / 0.5, 0, 1) * np.clip((secs - 0.3 - t) / 1.4, 0, 1)
    x = np.zeros_like(t)
    for f0, amp in ((98.0, 1.0), (103.0, 0.7)):             # two slightly detuned voices
        for h in range(1, 13):
            x += amp * np.sin(2 * np.pi * f0 * h * t + h) * (1.0 / h ** 1.1)
    x *= env * (1.0 + 0.04 * np.sin(2 * np.pi * 7 * t))
    x += shaped_noise(secs, 80, 400) * 0.05 * env
    return norm(x, 0.85)


def impact():
    secs = 6.0
    t = np.arange(int(SR * secs)) / SR
    crack = shaped_noise(secs, 200, 6000) * np.exp(-t * 7.0) * np.minimum(t / 0.003, 1.0)
    thump = np.sin(2 * np.pi * 42 * t * (1.0 + 0.5 * np.exp(-t * 3))) * np.exp(-t * 1.6) * 1.2
    groan_f = 130 - 60 * np.clip(t / 4.0, 0, 1)             # steel complaining, falling
    phase = 2 * np.pi * np.cumsum(groan_f) / SR
    groan = (np.sin(phase) + 0.5 * np.sin(2 * phase + 1) + 0.3 * np.sin(3 * phase)) * np.clip((t - 0.15) / 0.5, 0, 1) * np.exp(-(t - 0.15) * 0.55) * 0.5
    groan *= 1.0 + 0.3 * np.sin(2 * np.pi * 11 * t)
    rubble = shaped_noise(secs, 100, 2500, tilt=0.4) * np.exp(-t * 0.9) * np.clip((t - 0.1) / 0.3, 0, 1) * 0.35
    return norm(crack * 1.2 + thump + groan + rubble, 0.9)


def knock():
    secs = 1.6
    t = np.arange(int(SR * secs)) / SR
    x = np.zeros_like(t)
    for start in (0.05, 0.42, 0.78):          # three knuckle raps on a heavy wooden door
        s0 = int(start * SR)
        L = int(0.32 * SR)
        k = np.arange(L) / SR
        thud = np.sin(2 * np.pi * (150 - 40 * k * 3) * k) * np.exp(-k * 18.0) * 1.0
        body = shaped_noise(0.32, 200, 1800, tilt=0.4)[:L] * np.exp(-k * 30.0) * 0.5
        tap = shaped_noise(0.32, 1500, 5000)[:L] * np.exp(-k * 90.0) * 0.25
        x[s0:s0 + L] += (thud + body + tap) * np.minimum(k / 0.002, 1.0)
    return norm(x, 0.9)


if __name__ == "__main__":
    for name, fn in (("wind_loop.wav", wind), ("rain_loop.wav", rain), ("machinery_loop.wav", machinery), ("engine_loop.wav", engine),
                     ("bell.wav", bell), ("foghorn.wav", foghorn), ("ship_impact.wav", impact), ("knock.wav", knock)):
        save(name, fn())
