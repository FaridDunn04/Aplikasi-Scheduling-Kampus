import wave
import math
import struct
import os

os.makedirs('assets/sounds', exist_ok=True)

def generate_tone(filename, notes, duration_per_note=0.25, sample_rate=44100):
    wav_file = wave.open(filename, 'w')
    wav_file.setnchannels(1)  # Mono
    wav_file.setsampwidth(2)  # 16-bit
    wav_file.setframerate(sample_rate)
    
    total_samples = []
    for freq in notes:
        n_samples = int(sample_rate * duration_per_note)
        for i in range(n_samples):
            # Apply smooth attack and decay envelope
            t = i / sample_rate
            env = 1.0
            if i < sample_rate * 0.05:
                env = i / (sample_rate * 0.05)
            elif i > n_samples - (sample_rate * 0.1):
                env = (n_samples - i) / (sample_rate * 0.1)
                
            sample = int(32767 * 0.6 * env * math.sin(2 * math.pi * freq * t))
            total_samples.append(sample)
            
    packed = struct.pack(f'<{len(total_samples)}h', *total_samples)
    wav_file.writeframes(packed)
    wav_file.close()
    print(f"Created: {filename}")

# 1. Chime: C5 (523Hz), E5 (659Hz), G5 (784Hz), C6 (1046Hz)
generate_tone('assets/sounds/chime.wav', [523.25, 659.25, 783.99, 1046.50], duration_per_note=0.35)

# 2. Beep: 880Hz, 880Hz, 880Hz
generate_tone('assets/sounds/beep.wav', [880.0, 0, 880.0, 0, 880.0], duration_per_note=0.18)

# 3. Energetic: Quick upbeat arpeggio
generate_tone('assets/sounds/energetic.wav', [440, 554.37, 659.25, 880, 1108.73], duration_per_note=0.18)
