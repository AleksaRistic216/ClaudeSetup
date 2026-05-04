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
| `stt.sh` | `ggml-small.en.bin` | English-only, faster |
| `stt-sr.sh` | `ggml-large-v3.bin` | Best quality, multilingual |

### Downloading Models

```bash
cd ~/whisper.cpp

# English
bash models/download-ggml-model.sh small.en

# Serbian (large-v3 — best quality)
bash models/download-ggml-model.sh large-v3
```

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
