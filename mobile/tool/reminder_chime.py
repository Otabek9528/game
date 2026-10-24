"""The prayer reminders' sound: a short, soft three-note chime (G5, C6, E6).

    pip install numpy
    python3 tool/reminder_chime.py
    ffmpeg -i chime.wav -c:a libvorbis -q:a 5 android/app/src/main/res/raw/vegukin_chime.ogg
"""
import numpy as np, wave
sr = 44100
length = 1.7
t = np.arange(int(sr * length)) / sr
out = np.zeros_like(t)

def bell(freq, start, gain):
    x = t - start
    on = x >= 0
    x = np.where(on, x, 0)
    attack = np.clip(x / 0.006, 0, 1)
    # Fundamental rings longest; the bright partials fade fast, so it's soft.
    tone = (1.00 * np.exp(-x / 0.55) * np.sin(2 * np.pi * freq * x)
          + 0.32 * np.exp(-x / 0.22) * np.sin(2 * np.pi * freq * 2.0 * x + 0.3)
          + 0.12 * np.exp(-x / 0.09) * np.sin(2 * np.pi * freq * 2.76 * x + 0.7)
          + 0.05 * np.exp(-x / 0.05) * np.sin(2 * np.pi * freq * 5.4 * x))
    # A slow shimmer, like a struck glass.
    tone *= 1 + 0.06 * np.sin(2 * np.pi * 5.5 * x)
    return np.where(on, gain * attack * tone, 0)

out += bell(783.99, 0.00, 0.80)   # G5
out += bell(1046.50, 0.16, 0.70)  # C6
out += bell(1318.51, 0.32, 0.62)  # E6
fade = np.clip((length - t) / 0.25, 0, 1)
out *= fade
out /= np.max(np.abs(out))
out *= 10 ** (-5 / 20)  # peak -5 dBFS: gentle, never harsh
pcm = (out * 32767).astype(np.int16)
with wave.open('chime.wav', 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(pcm.tobytes())
print('ok', len(pcm) / sr, 's')
