"""작은 오프라인 신시사이저: docs/audio/audio_direction.md 의 음색·모티프를 코드로 렌더링한다.

악기는 감정 색에 묶여 있다(§4): longing=펠트 피아노, warmth=오르골, dream=패드, courage=피치카토, healing=플루트.
모든 함수는 numpy 배열(모노, float32, 44.1kHz)을 돌려준다.
"""
from __future__ import annotations

import numpy as np

SR = 44100
RNG = np.random.default_rng(20261126)

NOTE_INDEX = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
              "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def freq(note: str) -> float:
    """'A4' → 440.0"""
    name, octave = note[:-1], int(note[-1])
    midi = 12 * (octave + 1) + NOTE_INDEX[name]
    return 440.0 * 2 ** ((midi - 69) / 12)


def _t(dur: float) -> np.ndarray:
    return np.arange(int(dur * SR)) / SR


def adsr(n: int, a: float, d: float, s: float, r: float) -> np.ndarray:
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    s_n = max(0, n - a_n - d_n - r_n)
    env = np.concatenate([
        np.linspace(0, 1, max(a_n, 1), endpoint=False),
        np.linspace(1, s, max(d_n, 1), endpoint=False),
        np.full(s_n, s),
        np.linspace(s, 0, max(r_n, 1)),
    ])
    return env[:n] if env.size >= n else np.pad(env, (0, n - env.size))


# ---------------------------------------------------------------- 악기

def felt_piano(note: str, dur: float, vel: float = 0.8) -> np.ndarray:
    """부드러운 펠트 피아노: 배음이 빨리 사라지는 감쇠음 + 약한 망치 소리"""
    f = freq(note)
    length = dur + 1.6
    t = _t(length)
    out = np.zeros_like(t)
    for k, amp in enumerate([1.0, 0.42, 0.18, 0.08, 0.04], start=1):
        decay = 1.6 + 1.4 * k
        detune = 1 + 0.0007 * k
        out += amp * np.sin(2 * np.pi * f * k * detune * t) * np.exp(-decay * t / (1 + 0.15 * (f / 440)))
    hammer = RNG.normal(0, 1, t.size) * np.exp(-t * 90) * 0.04
    out += hammer
    env = adsr(t.size, 0.006, 0.05, 0.85, 0.0)
    release = np.ones_like(t)
    rel_start = int(dur * SR)
    release[rel_start:] = np.exp(-np.arange(t.size - rel_start) / SR * 7)
    return (out * env * release * vel * 0.32).astype(np.float32)


def music_box(note: str, dur: float, vel: float = 0.8) -> np.ndarray:
    """오르골·글로켄: 비조화 배음의 종소리"""
    f = freq(note)
    length = max(dur, 0.2) + 1.8
    t = _t(length)
    partials = [(1.0, 1.0, 2.2), (2.0, 0.28, 4.0), (5.4, 0.12, 9.0), (8.9, 0.05, 14.0)]
    out = np.zeros_like(t)
    for ratio, amp, decay in partials:
        out += amp * np.sin(2 * np.pi * f * ratio * t) * np.exp(-decay * t)
    env = adsr(t.size, 0.002, 0.02, 1.0, 0.0)
    return (out * env * vel * 0.26).astype(np.float32)


def pad(notes: list[str], dur: float, vel: float = 0.5, attack: float = 0.9) -> np.ndarray:
    """꿈(보라) 패드: 살짝 어긋난 배음 합 + 느린 어택·릴리스"""
    length = dur + 1.2
    t = _t(length)
    out = np.zeros_like(t)
    for note in notes:
        f = freq(note)
        for det in (-0.004, 0.0, 0.0045):
            for k, amp in enumerate([1.0, 0.3, 0.12], start=1):
                out += amp * np.sin(2 * np.pi * f * k * (1 + det) * t + RNG.uniform(0, 6.28))
    out /= max(1, len(notes) * 3)
    env = adsr(t.size, attack, 0.3, 0.8, 1.2)
    trem = 1 + 0.05 * np.sin(2 * np.pi * 0.3 * t)
    return (out * env * trem * vel * 0.30).astype(np.float32)


def pluck(note: str, dur: float, vel: float = 0.7) -> np.ndarray:
    """용기(주황) 피치카토/나일론 기타: 간단한 카플러스-스트롱"""
    f = freq(note)
    n = int((dur + 0.8) * SR)
    period = max(2, int(SR / f))
    buf = RNG.uniform(-1, 1, period)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % period]
        buf[i % period] = 0.5 * (buf[i % period] + buf[(i + 1) % period]) * 0.996
    return (out * vel * 0.3).astype(np.float32)


def flute(note: str, dur: float, vel: float = 0.6) -> np.ndarray:
    """치유(초록) 플루트: 사인 + 약한 3배음 + 숨소리 + 비브라토"""
    f = freq(note)
    t = _t(dur + 0.4)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t * 2, 0, 1)
    out = np.sin(2 * np.pi * f * vib * t) + 0.12 * np.sin(2 * np.pi * 3 * f * vib * t)
    breath = RNG.normal(0, 1, t.size) * 0.03
    env = adsr(t.size, 0.08, 0.1, 0.85, 0.35)
    return ((out + breath) * env * vel * 0.25).astype(np.float32)


def bass(note: str, dur: float, vel: float = 0.5) -> np.ndarray:
    f = freq(note)
    t = _t(dur + 0.6)
    out = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
    env = adsr(t.size, 0.02, 0.3, 0.7, 0.6)
    return (out * env * vel * 0.3).astype(np.float32)


INSTRUMENTS = {"piano": felt_piano, "box": music_box, "pluck": pluck, "flute": flute, "bass": bass}


# ---------------------------------------------------------------- 믹스 도구

def place(track: np.ndarray, sound: np.ndarray, at_sec: float, gain: float = 1.0) -> None:
    i = int(at_sec * SR)
    if i >= track.size:
        return
    end = min(track.size, i + sound.size)
    track[i:end] += sound[: end - i] * gain


def reverb_ir(seconds: float = 2.4, decay: float = 3.2, seed: int = 1) -> np.ndarray:
    rng = np.random.default_rng(seed)
    t = _t(seconds)
    ir = rng.normal(0, 1, t.size) * np.exp(-decay * t)
    # 고역을 조금 깎아 부드럽게
    ir = np.convolve(ir, np.ones(6) / 6, mode="same")
    ir[0] = 1.0
    return (ir / np.sqrt(np.sum(ir ** 2))).astype(np.float32)


def fft_convolve(x: np.ndarray, h: np.ndarray) -> np.ndarray:
    n = x.size + h.size - 1
    size = 1 << (n - 1).bit_length()
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(h, size), size)[:n]
    return y.astype(np.float32)


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    """1차 IIR 저역 통과 (환경음·회색 톤용)"""
    rc = 1.0 / (2 * np.pi * cutoff)
    alpha = (1 / SR) / (rc + 1 / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def stereo_mix(dry: np.ndarray, wet_amount: float = 0.28, width: float = 0.6, ir_seconds: float = 2.4) -> np.ndarray:
    """모노 드라이 → 스테레오(좌우 다른 리버브)"""
    left = fft_convolve(dry, reverb_ir(ir_seconds, seed=11))[: dry.size]
    right = fft_convolve(dry, reverb_ir(ir_seconds, seed=23))[: dry.size]
    out = np.stack([dry + wet_amount * (left * (1 + width) + right * (1 - width)) / 2,
                    dry + wet_amount * (right * (1 + width) + left * (1 - width)) / 2], axis=1)
    return out.astype(np.float32)


def fold_tail(stereo: np.ndarray, loop_len: int) -> np.ndarray:
    """루프 본체 뒤로 넘친 리버브 꼬리를 앞부분에 겹친다 (audio_direction.md §8-1)"""
    body = stereo[:loop_len].copy()
    tail = stereo[loop_len:]
    if tail.size:
        n = min(tail.shape[0], loop_len)
        body[:n] += tail[:n]
    return body


def normalize(x: np.ndarray, target_rms_db: float = -19.0, peak_db: float = -1.0) -> np.ndarray:
    """간이 라우드니스: RMS 를 맞춘 뒤 피크 제한 (LUFS 근사)"""
    rms = np.sqrt(np.mean(x.astype(np.float64) ** 2)) + 1e-9
    y = x * (10 ** (target_rms_db / 20) / rms)
    peak = np.max(np.abs(y)) + 1e-9
    limit = 10 ** (peak_db / 20)
    if peak > limit:
        y = np.tanh(y / limit * 0.9) * limit / np.tanh(0.9)
    return y.astype(np.float32)


def normalize_peak(x: np.ndarray, peak_db: float = -3.0) -> np.ndarray:
    peak = np.max(np.abs(x)) + 1e-9
    return (x * (10 ** (peak_db / 20) / peak)).astype(np.float32)
