# Speech-to-Text (Whisper CPP)

Voice recording → transcription → typed at cursor, using [whisper.cpp](https://github.com/ggerganov/whisper.cpp).

## How It Works

Press the hotkey to start recording. Press it again to stop — Whisper transcribes the audio and types the result at the cursor. The result is also copied to clipboard.

## Scripts

| Script | Language | Hotkey |
|---|---|---|
| `~/bin/stt.sh` | English | Super+Alt+R |
| `~/bin/stt-sr.sh` | Serbian | Super+Alt+T |

## Models

| Script | Model | Notes |
|---|---|---|
| `stt.sh` | `ggml-medium.en.bin` | English-only, GPU-accelerated (~685ms) |
| `stt-sr.sh` | `ggml-large-v3-sr-q5_0.bin` | Serbian fine-tuned, GPU-accelerated (~1.1s) |

### Downloading Models

```bash
cd ~/whisper.cpp

# English
bash models/download-ggml-model.sh medium.en

# Serbian — fine-tuned large-v3 (Sagicc/Whisper.cpp on HuggingFace, 1.08 GB)
wget -O models/ggml-large-v3-sr-q5_0.bin \
  "https://huggingface.co/Sagicc/Whisper.cpp/resolve/main/ggml-large-v3-sr-q5_0.bin"
```

### Serbian model notes

The Serbian model (`Sagicc/whisper-large-v3-sr-q5_0`) is a community fine-tune of `whisper-large-v3` trained on Common Voice 13, Google FLEURS, and custom Serbian audio (5.56% WER). It outputs Cyrillic by default — `stt-sr.sh` pipes the result through a deterministic Cyrillic→Latin transliteration so the typed output is always latinica.

## GPU Acceleration (CUDA)

Both scripts benefit from GPU acceleration. whisper.cpp must be built with CUDA support:

```bash
cd ~/whisper.cpp
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -j$(nproc)
```

Requires `nvidia-cuda-toolkit` (`sudo apt install nvidia-cuda-toolkit`). The build auto-detects the GPU architecture — no manual flags needed. Tested with RTX 3060 Ti + CUDA 12.4.

**Speedup:** encode drops from ~12s (CPU) to ~180ms (GPU) for the Serbian large-v3 model.

## Hotkey Setup (GNOME)

Hotkeys are configured via `gsettings` (or Settings → Keyboard → Custom Shortcuts):

```bash
# Register both shortcuts
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', \
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"

# English — Super+Alt+R
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Speech to Text'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command '/home/parpil/bin/stt.sh'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super><Alt>r'

# Serbian — Super+Alt+T
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Speech to Text (Serbian)'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command '/home/parpil/bin/stt-sr.sh'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super><Alt>t'
```

## Dependencies

```bash
sudo apt install arecord xclip xdotool libnotify-bin
```
