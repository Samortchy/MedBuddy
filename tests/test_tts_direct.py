# Direct TTS test — bypasses FastAPI entirely.
# Run: python tests/test_tts_direct.py
import io
from pathlib import Path

WEIGHTS = r"D:\epoch_1\epoch_1\model.safetensors"
OUTPUT  = r"D:\epoch_1\test_output.wav"

print("Step 1: loading base Chatterbox Multilingual model from HuggingFace...")
from chatterbox.mtl_tts import ChatterboxMultilingualTTS
m = ChatterboxMultilingualTTS.from_pretrained(device="cpu")
print(f"  Base model loaded. Sample rate = {m.sr} Hz")

print(f"\nStep 2: overlaying fine-tuned weights from {WEIGHTS} ...")
from safetensors.torch import load_file
state = load_file(WEIGHTS, device="cpu")
print(f"  Checkpoint has {len(state)} parameter tensors")
print(f"  First 3 keys: {list(state.keys())[:3]}")

missing, unexpected = m.t3.load_state_dict(state, strict=False)
m.t3.eval()
print(f"  missing={len(missing)}  unexpected={len(unexpected)}")
if missing:
    print(f"  Missing (first 3): {missing[:3]}")
if unexpected:
    print(f"  Unexpected (first 3): {unexpected[:3]}")

print("\nStep 3: generating Arabic speech...")
import torchaudio
wav = m.generate("مرحبا، كيف حالك اليوم؟", language_id="ar")
buf = io.BytesIO()
torchaudio.save(buf, wav, m.sr, format="wav")
wav_bytes = buf.getvalue()
print(f"  Generated {len(wav_bytes):,} bytes of WAV audio")

Path(OUTPUT).write_bytes(wav_bytes)
print(f"\nSaved to: {OUTPUT}")
print("Open it and listen — does it sound right?")
