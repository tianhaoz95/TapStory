#!/bin/bash
# Generates the placeholder narration audio for the bundled sample content
# using macOS's built-in `say` text-to-speech, so the app has real (if
# synthetic) audio to demo out of the box. Replace these .m4a files with
# real recorded narration/music before shipping to actual families --
# these exist purely so the app isn't silent on first run.
set -euo pipefail

cd "$(dirname "$0")/.."

VOICE="Samantha"
OUT_DIR="App/MagicBox/Resources/BundledContent/Audio"
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

echo "== Story: The Magic Monkey =="
say_line "story_magic_monkey_p1" "Once upon a time, there was a magic monkey named Momo, who lived high up in a tall, tall tree."
say_line "story_magic_monkey_p2" "One sunny morning, Momo found a sparkly golden banana. Ooooh! Magic!"
say_line "story_magic_monkey_p3" "Momo took one little bite, and whoosh! Momo could fly all around the jungle!"
say_line "story_magic_monkey_p4" "Momo flew home and shared the magic banana with all of Momo's friends. The end! Tap me again to hear it once more."

echo "== Story: Sleepy Bear's Bedtime =="
say_line "story_sleepy_bear_p1" "Little Bear was very sleepy after a big day of playing in the forest."
say_line "story_sleepy_bear_p2" "Little Bear snuggled into a cozy cave, pulled up a soft blanket of leaves, and yawned a big, big yawn."
say_line "story_sleepy_bear_p3" "Little Bear closed both eyes and drifted off to sleep, dreaming sweet dreams until morning. Goodnight, Little Bear."

echo "== Story: Curious Fox and the Rainbow =="
say_line "story_curious_fox_p1" "Curious Fox loved exploring, and one rainy day, Fox spotted something amazing in the sky."
say_line "story_curious_fox_p2" "It was a big, beautiful rainbow, stretching all the way across the meadow! Fox ran closer to see."
say_line "story_curious_fox_p3" "Fox never did find the end of the rainbow, but Fox had the best, most colorful day ever. Tap me again for another adventure!"

echo "== Vocabulary cards =="
say_line "letter_a_word" "A! A is for Apple."
say_line "letter_b_word" "B! B is for Ball."
say_line "letter_c_word" "C! C is for Cat."
say_line "letter_m_word" "M! M is for Monkey."
say_line "letter_s_word" "S! S is for Sun."

echo "== Music placeholder =="
say_line "lullaby_01" "Hmmmm, hmm, hmm. Time to close your eyes and rest, little one. Hmmmm, hmm, hmm."

echo "Done. Generated files are in $OUT_DIR"
