#!/bin/bash
# Generates placeholder audio for bundled content that genuinely needs a
# pre-rendered file rather than on-device speech synthesis -- currently
# just the lullaby, since AVSpeechSynthesizer can speak words but can't
# sing or hum convincingly. Stories and vocab cards use MediaRef(source:
# .speech, ...) instead: their audio is synthesized live on-device from
# the text in their JSON, so there's nothing to (re)generate for them.
#
# Uses macOS's built-in `say` text-to-speech. Replace lullaby_01.m4a with
# real recorded/composed music before shipping to actual families -- this
# exists purely so the app isn't silent on first run.
set -euo pipefail

cd "$(dirname "$0")/.."

VOICE="Samantha"
OUT_DIR="App/TapStory/Resources/BundledContent/Audio"
WORK_DIR="Scripts/.audio_work"
mkdir -p "$OUT_DIR" "$WORK_DIR"

say_line() {
  local name="$1"
  local text="$2"
  local aiff="$WORK_DIR/$name.aiff"
  local m4a="$OUT_DIR/$name.m4a"
  say -v "$VOICE" -o "$aiff" "$text"
  afconvert -f m4af -d aac "$aiff" "$m4a"
  rm -f "$aiff"
  echo "Generated $m4a"
}

echo "== Music placeholder =="
say_line "lullaby_01" "Hmmmm, hmm, hmm. Time to close your eyes and rest, little one. Hmmmm, hmm, hmm."

echo "Done. Generated files are in $OUT_DIR"
