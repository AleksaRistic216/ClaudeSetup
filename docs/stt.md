# Speech-to-Text (Whisper CPP)

Voice recording → transcription → typed at cursor, using [whisper.cpp](https://github.com/ggerganov/whisper.cpp).

## How It Works

Press the hotkey to start recording. Press it again to stop — Whisper transcribes the audio and types the result at the cursor. The result is also copied to clipboard.

## Models

| Language | Model | Notes |
|---|---|---|
| English | `ggml-medium.en.bin` | English-only, ~685ms on GPU |
| Serbian | `ggml-large-v3-sr-q5_0.bin` | Fine-tuned on Serbian data, ~1.1s on GPU |

### Serbian model notes

`Sagicc/whisper-large-v3-sr-q5_0` is a community fine-tune of `whisper-large-v3` trained on Common Voice 13, Google FLEURS, and custom Serbian audio (5.56% WER). It outputs Cyrillic by default — the STT script pipes the result through a deterministic Cyrillic→Latin transliteration so the typed output is always latinica.

---

## Linux setup

### Scripts and hotkeys

| Script | Language | Hotkey |
|---|---|---|
| `~/bin/stt.sh` | English | Super+Alt+R |
| `~/bin/stt-sr.sh` | Serbian | Super+Alt+T |

### Downloading models

```bash
cd ~/whisper.cpp

# English
bash models/download-ggml-model.sh medium.en

# Serbian — fine-tuned large-v3 (Sagicc/Whisper.cpp on HuggingFace, 1.08 GB)
wget -O models/ggml-large-v3-sr-q5_0.bin \
  "https://huggingface.co/Sagicc/Whisper.cpp/resolve/main/ggml-large-v3-sr-q5_0.bin"
```

### Build with GPU (CUDA)

```bash
cd ~/whisper.cpp
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -j$(nproc)
```

Requires `nvidia-cuda-toolkit` (`sudo apt install nvidia-cuda-toolkit`). The build auto-detects GPU architecture. Tested with RTX 3060 Ti + CUDA 12.4.

**Speedup:** encode drops from ~12s (CPU) to ~180ms (GPU) for the Serbian large-v3 model.

### Hotkey setup (GNOME)

```bash
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

### Dependencies

```bash
sudo apt install arecord xclip xdotool libnotify-bin
```

---

## Windows setup

See [voice-input.md](voice-input.md) for the full walkthrough (ffmpeg, AutoHotkey, mic detection, known gotchas). This section covers what's different for the updated models and Serbian support.

### Build whisper.cpp

```powershell
git clone https://github.com/ggml-org/whisper.cpp ~/source/whisper.cpp
cd ~/source/whisper.cpp
cmake -B build -G "Visual Studio 17 2022" -DGGML_CUDA=ON
cmake --build build --config Release
```

`-DGGML_CUDA=ON` requires the [CUDA Toolkit](https://developer.nvidia.com/cuda-downloads) installed separately on Windows (not available via winget — use the NVIDIA installer). Without it, omit the flag and it falls back to CPU.

### Downloading models

Run in PowerShell from `~/source/whisper.cpp`:

```powershell
# English
bash models/download-ggml-model.sh medium.en

# Serbian — fine-tuned large-v3 (1.08 GB)
Invoke-WebRequest -Uri "https://huggingface.co/Sagicc/Whisper.cpp/resolve/main/ggml-large-v3-sr-q5_0.bin" `
  -OutFile "models\ggml-large-v3-sr-q5_0.bin"
```

### English hotkey (Ctrl+Alt+R)

The existing `~/.claude/whisper-hotkey.ahk` handles English. Update the `ModelPath` variable in the script to point to `ggml-medium.en.bin` instead of `base.en`:

```ahk
ModelPath := A_MyDocuments "\..\source\whisper.cpp\models\ggml-medium.en.bin"
```

Whisper flags to use: `-l en --best-of 5 --beam-size 5 --suppress-nst -nt`

### Serbian hotkey (Ctrl+Alt+T) — TODO

A second AHK script (`whisper-hotkey-sr.ahk`) is needed for Serbian. It should follow the same structure as `whisper-hotkey.ahk` with these differences:

- **Model:** `ggml-large-v3-sr-q5_0.bin`
- **Whisper flags:** `-l sr --best-of 5 --beam-size 5 --suppress-nst -nt`
- **Transliteration:** after whisper-cli finishes, pipe the output through Python to convert Cyrillic→Latin before typing:

```powershell
# transliteration one-liner (same mapping as Linux version)
python -c "
import sys
t = open('C:\\Temp\\whisper.txt').read().strip()
for c,l in [('Љ','Lj'),('љ','lj'),('Њ','Nj'),('њ','nj'),('Џ','Dž'),('џ','dž'),('А','A'),('а','a'),('Б','B'),('б','b'),('В','V'),('в','v'),('Г','G'),('г','g'),('Д','D'),('д','d'),('Ђ','Đ'),('ђ','đ'),('Е','E'),('е','e'),('Ж','Ž'),('ж','ž'),('З','Z'),('з','z'),('И','I'),('и','i'),('Ј','J'),('ј','j'),('К','K'),('к','k'),('Л','L'),('л','l'),('М','M'),('м','m'),('Н','N'),('н','n'),('О','O'),('о','o'),('П','P'),('п','p'),('Р','R'),('р','r'),('С','S'),('с','s'),('Т','T'),('т','t'),('Ћ','Ć'),('ћ','ć'),('У','U'),('у','u'),('Ф','F'),('ф','f'),('Х','H'),('х','h'),('Ц','C'),('ц','c'),('Ч','Č'),('ч','č'),('Ш','Š'),('ш','š')]:
    t = t.replace(c,l)
print(t,end='')
" > C:\Temp\whisper-sr-latin.txt
```

- **Hotkey:** bind to `Ctrl+Alt+T` (avoid `Win+Alt+T` — same Xbox Game Bar conflict as `Win+Alt+R`)
