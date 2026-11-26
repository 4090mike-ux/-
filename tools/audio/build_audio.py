#!/usr/bin/env python3
"""버티컬 슬라이스 오디오(WP-22)를 코드로 렌더링한다: BGM 3곡 + 환경음 2개 + 효과음 28개.

  pip install numpy soundfile
  python tools/audio/build_audio.py          # game/audio/ 아래에 전부 다시 만든다 (결정적)

근거: docs/audio/audio_direction.md — 라장조, 3/4박, 72 BPM(한 마디 2.5초), 하늘 모티프「물결」(펠트 피아노),
별 모티프「해」(오르골), 둘 다 4마디째 V(A)에서 해결되지 않는다(음악의 R-NAME: 챕터 4 전에는 완전히 겹치지 않음).
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import soundfile as sf

sys.path.insert(0, str(Path(__file__).resolve().parent))
import synth as S  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
BGM_DIR = ROOT / "game/audio/bgm"
SFX_DIR = ROOT / "game/audio/sfx"

BEAT = 60.0 / 72.0
BAR = BEAT * 3
CHORDS = [  # I – vi – IV – V
    {"pad": ["D3", "F#3", "A3", "D4"], "bass": "D2", "tones": ["D4", "F#4", "A4"]},
    {"pad": ["B2", "D3", "F#3", "B3"], "bass": "B1", "tones": ["B3", "D4", "F#4"]},
    {"pad": ["G2", "B2", "D3", "G3"], "bass": "G1", "tones": ["G3", "B3", "D4"]},
    {"pad": ["A2", "C#3", "E3", "A3"], "bass": "A1", "tones": ["A3", "C#4", "E4"]},
]
# 하늘「물결」: (음, 박) — 긴·짧·보통, 4마디째 E4 길게(해결 안 됨)
HANEUL = [[("A4", 1.5), ("F#4", 0.5), ("G4", 1.0)], [("F#4", 1.5), ("D4", 0.5), ("E4", 1.0)],
          [("D4", 1.5), ("B3", 0.5), ("C#4", 1.0)], [("E4", 3.0)]]
# 별「해」: 5음계 상행, 4마디째 A5 열린 채로
BYEOL = [[("D5", 0.5), ("E5", 0.5), ("F#5", 1.0), ("A5", 1.0)], [("B5", 1.0), ("A5", 1.0), ("F#5", 1.0)],
         [("D6", 1.0), ("B5", 1.0), ("A5", 1.0)], [("A5", 3.0)]]


def write_ogg(path: Path, data: np.ndarray) -> None:
    """libsndfile 의 Vorbis 인코더는 큰 버퍼를 한 번에 받으면 Windows 에서 스택이 넘친다 → 조금씩 쓴다"""
    channels = 1 if data.ndim == 1 else data.shape[1]
    with sf.SoundFile(path, "w", S.SR, channels, format="OGG", subtype="VORBIS") as f:
        for i in range(0, data.shape[0], 4096):
            f.write(data[i:i + 4096])


def jitter() -> float:
    return float(S.RNG.uniform(-0.008, 0.008))


def lay_motif(track: np.ndarray, motif: list, start_bar: int, inst: str, vel: float = 0.8, octave_shift: int = 0,
              bars: range | None = None) -> None:
    fn = S.INSTRUMENTS[inst]
    for i, bar in enumerate(motif):
        if bars is not None and i not in bars:
            continue
        t = (start_bar + i) * BAR
        for note, beats in bar:
            n = note[:-1] + str(int(note[-1]) + octave_shift)
            S.place(track, fn(n, beats * BEAT * 0.95, vel * float(S.RNG.uniform(0.9, 1.05))), t + jitter())
            t += beats * BEAT


def lay_chords(track: np.ndarray, start_bar: int, count: int, pad_vel: float = 0.45, bass_vel: float = 0.4,
               arp: str | None = None, arp_vel: float = 0.35) -> None:
    for b in range(count):
        chord = CHORDS[(start_bar + b) % 4]
        t = (start_bar + b) * BAR
        S.place(track, S.pad(chord["pad"], BAR, pad_vel, attack=0.6), t)
        S.place(track, S.bass(chord["bass"], BAR * 0.9, bass_vel), t)
        if arp:
            fn = S.INSTRUMENTS[arp]
            steps = chord["tones"] + chord["tones"][1:2]
            for k, note in enumerate(steps[:3] if arp == "piano" else steps):
                dt = BEAT * (1.0 if arp == "piano" else 0.75)
                S.place(track, fn(note if arp == "piano" else note[:-1] + str(int(note[-1]) + 1), dt, arp_vel), t + k * dt + jitter())


def render_track(name: str, bars: int, compose) -> None:
    length = bars * BAR
    dry = np.zeros(int((length + 3.0) * S.SR), dtype=np.float32)
    compose(dry)
    stereo = S.stereo_mix(dry, wet_amount=0.32)
    looped = S.fold_tail(stereo, int(length * S.SR))
    out = S.normalize(looped, target_rms_db=-19.0, peak_db=-1.0)
    BGM_DIR.mkdir(parents=True, exist_ok=True)
    write_ogg(BGM_DIR / f"bgm_{name}.ogg", out)
    print(f"bgm_{name}.ogg  {length:.1f}s ({bars} bars)")


def compose_haneul(track: np.ndarray) -> None:
    lay_chords(track, 0, 4, pad_vel=0.38)                      # 인트로: 패드만
    S.place(track, S.felt_piano("D4", BAR, 0.5), 2 * BAR)
    lay_chords(track, 4, 4, pad_vel=0.32)
    lay_motif(track, HANEUL, 4, "piano")                        # 원형
    lay_chords(track, 8, 4, pad_vel=0.28, arp="piano", arp_vel=0.22)
    lay_motif(track, HANEUL, 8, "piano", 0.85)                  # 왼손 분산화음과 함께
    lay_chords(track, 12, 4, pad_vel=0.30)
    lay_motif(track, HANEUL, 12, "piano", 0.7, octave_shift=-1)  # 한 옥타브 아래, 더 그리운
    lay_chords(track, 16, 4, pad_vel=0.42)                      # 숨 쉬는 구간
    lay_motif(track, HANEUL, 16, "piano", 0.5, bars=range(0, 1))
    lay_chords(track, 20, 4, pad_vel=0.3, arp="piano", arp_vel=0.18)
    lay_motif(track, HANEUL, 20, "piano", 0.8)                  # 끝: 4마디째 E4 — 해결 없이 처음으로


def compose_byeol(track: np.ndarray) -> None:
    lay_chords(track, 0, 4, pad_vel=0.32, arp="box", arp_vel=0.18)
    lay_chords(track, 4, 4, pad_vel=0.28)
    lay_motif(track, BYEOL, 4, "box", 0.8)
    lay_chords(track, 8, 4, pad_vel=0.26, arp="box", arp_vel=0.16)
    lay_motif(track, BYEOL, 8, "box", 0.85)
    lay_motif(track, BYEOL, 8, "box", 0.25, octave_shift=-1, bars=range(0, 3))  # 메아리
    lay_chords(track, 12, 4, pad_vel=0.30)
    lay_motif(track, BYEOL, 12, "box", 0.7)
    lay_chords(track, 16, 4, pad_vel=0.36, arp="box", arp_vel=0.14)
    lay_chords(track, 20, 4, pad_vel=0.28)
    lay_motif(track, BYEOL, 20, "box", 0.8)


def compose_square(track: np.ndarray) -> None:
    lay_chords(track, 0, 4, pad_vel=0.34)
    lay_chords(track, 4, 4, pad_vel=0.28)
    lay_motif(track, HANEUL, 4, "piano", 0.8)                   # 하늘
    lay_chords(track, 8, 4, pad_vel=0.28)
    lay_motif(track, BYEOL, 8, "box", 0.75)                     # 별
    lay_chords(track, 12, 4, pad_vel=0.30, arp="piano", arp_vel=0.15)
    for i in range(2):                                          # 번갈아 한 마디씩
        lay_motif(track, [HANEUL[i]], 12 + i * 2, "piano", 0.75)
        lay_motif(track, [BYEOL[i]], 13 + i * 2, "box", 0.7)
    lay_chords(track, 16, 1, pad_vel=0.36)                      # ★ 1마디 겹침 (같은 말 동시에)
    lay_motif(track, [HANEUL[3]], 16, "piano", 0.75)
    lay_motif(track, [BYEOL[0]], 16, "box", 0.7)
    lay_chords(track, 17, 3, pad_vel=0.40)                      # 여운 — 해결하지 않는다
    lay_chords(track, 20, 4, pad_vel=0.28)
    lay_motif(track, HANEUL, 20, "piano", 0.55, bars=range(0, 2))
    lay_motif(track, BYEOL, 22, "box", 0.55, bars=range(0, 2))


def ambience() -> None:
    out_dir = SFX_DIR / "amb"
    out_dir.mkdir(parents=True, exist_ok=True)
    # 회색 마을 바람: 갈색 잡음 + 느린 세기 변화, 32초 루프(앞뒤 교차 페이드)
    n = int(34 * S.SR)
    noise = np.cumsum(S.RNG.normal(0, 1, n)).astype(np.float32)
    noise -= np.convolve(noise, np.ones(4410) / 4410, mode="same")
    wind = S.lowpass(noise * 0.02, 700.0)
    t = np.arange(n) / S.SR
    wind *= (0.6 + 0.4 * np.sin(2 * np.pi * t / 8.0) * np.sin(2 * np.pi * t / 13.0 + 1)).astype(np.float32)
    loop = int(32 * S.SR)
    fade = n - loop
    body = wind[:loop].copy()
    body[:fade] = body[:fade] * np.linspace(0, 1, fade) + wind[loop:] * np.linspace(1, 0, fade)
    stereo = np.stack([body, np.roll(body, 900)], axis=1)
    write_ogg(out_dir / "amb_wind.ogg", S.normalize(stereo, -28.0, -6.0))
    # 공명 패드(퍼즐): 라 음 드론 + 반짝임, 20초 루프
    dry = np.zeros(int(23 * S.SR), dtype=np.float32)
    for k in range(4):
        S.place(dry, S.pad(["D3", "A3", "D4", "F#4"], 5.5, 0.5, attack=2.0), k * 5.0)
    for k in range(10):
        S.place(dry, S.music_box(["A5", "D6", "F#6", "E6"][k % 4], 0.4, 0.12), 1.0 + k * 2.0 + float(S.RNG.uniform(0, 0.6)))
    stereo = S.fold_tail(S.stereo_mix(dry, 0.5), int(20 * S.SR))
    write_ogg(out_dir / "amb_resonance.ogg", S.normalize(stereo, -26.0, -6.0))
    print("amb_wind.ogg, amb_resonance.ogg")


# ---------------------------------------------------------------- 효과음

def noise_burst(dur: float, cutoff: float, decay: float) -> np.ndarray:
    t = np.arange(int(dur * S.SR)) / S.SR
    return (S.lowpass(S.RNG.normal(0, 1, t.size).astype(np.float32), cutoff) * np.exp(-decay * t)).astype(np.float32)


def sweep(f0: float, f1: float, dur: float, amp: float = 0.4) -> np.ndarray:
    t = np.arange(int(dur * S.SR)) / S.SR
    f = np.geomspace(f0, f1, t.size)
    phase = 2 * np.pi * np.cumsum(f) / S.SR
    return (np.sin(phase) * S.adsr(t.size, 0.02, 0.05, 0.8, dur * 0.5) * amp).astype(np.float32)


def seq(parts: list[tuple[float, np.ndarray]], total: float) -> np.ndarray:
    out = np.zeros(int(total * S.SR), dtype=np.float32)
    for at, snd in parts:
        S.place(out, snd, at)
    return out


def tick(f: float = 1200.0, dur: float = 0.04) -> np.ndarray:
    t = np.arange(int(dur * S.SR)) / S.SR
    return (np.sin(2 * np.pi * f * t) * np.exp(-t * 90)).astype(np.float32)


def with_reverb(x: np.ndarray, amount: float = 0.3) -> np.ndarray:
    wet = S.fft_convolve(x, S.reverb_ir(1.4, decay=4.0, seed=5))
    out = np.zeros(wet.size, dtype=np.float32)
    out[: x.size] += x
    return out + wet * amount


def sfx_list() -> dict[str, tuple[np.ndarray, float]]:
    box, piano = S.music_box, S.felt_piano
    return {
        "ui/sfx_ui_move": (tick(1500, 0.05), -6),
        "ui/sfx_ui_confirm": (seq([(0, box("A5", 0.1, 0.7)), (0.07, box("D6", 0.2, 0.7))], 0.9), -6),
        "ui/sfx_ui_cancel": (seq([(0, box("D6", 0.1, 0.5)), (0.07, box("A5", 0.2, 0.5))], 0.9), -6),
        "ui/sfx_ui_save": (with_reverb(seq([(0, box("D6", 0.1, 0.5)), (0.08, box("F#6", 0.1, 0.5)), (0.16, box("A6", 0.3, 0.5))], 1.2)), -6),
        "ui/sfx_ui_page": (noise_burst(0.14, 3000, 25), -6),
        "dlg/sfx_dlg_blip_haneul": (piano("A4", 0.03, 0.6)[: int(0.09 * S.SR)], -9),
        "dlg/sfx_dlg_blip_byeol": (box("D6", 0.03, 0.5)[: int(0.09 * S.SR)], -9),
        "dlg/sfx_dlg_sync": (with_reverb(seq([(0, piano("D4", 0.8, 0.6)), (0, piano("A4", 0.8, 0.5)), (0, box("D5", 0.8, 0.6)), (0.02, box("F#5", 0.8, 0.4))], 2.2), 0.4), -4),
        "step/sfx_step_wood": (seq([(0, S.bass("B1", 0.04, 0.9)[: int(0.12 * S.SR)]), (0, noise_burst(0.05, 1800, 60) * 0.5)], 0.15), -3),
        "step/sfx_step_wood_02": (seq([(0, S.bass("A1", 0.04, 0.9)[: int(0.12 * S.SR)]), (0, noise_burst(0.05, 1600, 60) * 0.5)], 0.15), -3),
        "step/sfx_step_stone": (seq([(0, noise_burst(0.06, 4200, 70)), (0, tick(900, 0.03) * 0.4)], 0.12), -3),
        "step/sfx_step_grass": (noise_burst(0.12, 1400, 30), -3),
        "step/sfx_step_door": (seq([(0, sweep(180, 260, 0.35, 0.3)), (0.33, S.bass("G1", 0.08, 1.0)[: int(0.25 * S.SR)])], 0.7), -3),
        "echo/sfx_echo_sense_start": (with_reverb(seq([(0, noise_burst(0.5, 900, 3) * 0.4), (0, sweep(300, 900, 0.5, 0.15))], 0.7)), -3),
        "echo/sfx_echo_sense_end": (seq([(0, sweep(800, 300, 0.4, 0.12))], 0.5), -6),
        "echo/sfx_echo_found_longing": (with_reverb(piano("A5", 0.6, 0.8), 0.5), -3),
        "echo/sfx_echo_found_warmth": (with_reverb(box("D6", 0.6, 0.8), 0.5), -3),
        "echo/sfx_echo_hidden_sparkle": (with_reverb(seq([(k * 0.06, box(n, 0.08, 0.35)) for k, n in enumerate(["A6", "D7", "A6", "F#7"])], 1.0)), -6),
        "pzl/sfx_pzl_open": (with_reverb(S.pad(["D4", "A4"], 0.5, 0.6, attack=0.25)), -6),
        "pzl/sfx_pzl_place_ok": (seq([(0, box("A5", 0.15, 0.7)), (0, piano("D5", 0.15, 0.4))], 0.9), -3),
        "pzl/sfx_pzl_place_no": (seq([(0, S.bass("D2", 0.08, 0.8)[: int(0.2 * S.SR)]), (0.05, tick(300, 0.06) * 0.5)], 0.3), -6),
        "pzl/sfx_pzl_hint": (with_reverb(seq([(0, box("F#6", 0.1, 0.4)), (0.15, box("A6", 0.2, 0.4))], 0.9)), -6),
        "pzl/sfx_pzl_solved": (with_reverb(seq([(0, piano("D4", 1.0, 0.6)), (0.06, box("F#5", 0.6, 0.6)), (0.12, box("A5", 0.6, 0.6)), (0.18, box("D6", 1.0, 0.7))], 2.6), 0.45), -3),
        "color/sfx_color_restore_longing": (with_reverb(seq([(k * 0.12, piano(n, 1.2, 0.5)) for k, n in enumerate(["D4", "F#4", "A4", "D5"])], 3.0), 0.5), -4),
        "color/sfx_color_restore_warmth": (with_reverb(seq([(k * 0.09, box(n, 0.8, 0.5)) for k, n in enumerate(["D6", "E6", "F#6", "A6", "B6"])], 3.0), 0.5), -4),
        "garden/sfx_garden_plant": (seq([(0, noise_burst(0.08, 600, 40)), (0.16, noise_burst(0.08, 600, 40))], 0.35), -4),
        "garden/sfx_garden_grow": (with_reverb(seq([(k * 0.1, box(n, 0.2, 0.45)) for k, n in enumerate(["D5", "F#5", "A5"])], 1.4)), -4),
        "sib/sfx_sib_tag_switch": (seq([(0, sweep(500, 1200, 0.18, 0.15)), (0.12, box("A5", 0.15, 0.5))], 0.8), -4),
    }


def render_sfx() -> None:
    for rel, (data, peak) in sfx_list().items():
        path = SFX_DIR / f"{rel}.wav"
        path.parent.mkdir(parents=True, exist_ok=True)
        sf.write(path, S.normalize_peak(data, peak), S.SR, subtype="PCM_16")
    print(f"sfx {len(sfx_list())}개")


def main() -> int:
    render_track("haneul", 24, compose_haneul)
    render_track("byeol", 24, compose_byeol)
    render_track("square", 24, compose_square)
    ambience()
    render_sfx()
    return 0


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
