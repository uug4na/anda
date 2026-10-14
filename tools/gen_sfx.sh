#!/bin/bash
# Builds the fight sounds from Kenney CC0 samples (run once, the results are committed): a blade slice mixed over a soft
# thud for sword hits, a heavier thud for bosses, a body drop for deaths, a boomy thud for the hero.
set -e
K=${KENNEY:-$HOME/Downloads/kenney}  # the unpacked Kenney packs: impact-sounds/Audio and rpg-audio/Audio
IMP=$K/impact-sounds/Audio
RPG=$K/rpg-audio/Audio
OUT="$(cd "$(dirname "$0")/.." && pwd)/assets/audio/sfx"
cd "$OUT"
rm -f hit_*.ogg hit_*.ogg.import hurt_*.ogg hurt_*.ogg.import swoosh_*.ogg swoosh_*.ogg.import enemy_die_*.ogg enemy_die_*.ogg.import hit_boss_* hurt_* hit_* enemy_die_*
FMT="aformat=sample_rates=44100:channel_layouts=mono"
ENC="-ar 22050 -ac 1 -c:a pcm_s16le"
# slice + soft thud: sword hit on a raider
n=1
for pair in "knifeSlice.ogg impactSoft_medium_000" "knifeSlice2.ogg impactSoft_medium_001" "knifeSlice.ogg impactSoft_medium_002" "knifeSlice2.ogg impactSoft_medium_000"; do
  set -- $pair
  ffmpeg -y -loglevel error -i "$RPG/$1" -i "$IMP/$2.ogg" -filter_complex \
    "[0:a]atrim=0:0.22,asetpts=PTS-STARTPTS,afade=t=out:st=0.08:d=0.14,volume=0.7,$FMT[a];[1:a]$FMT,volume=0.85[b];[a][b]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.9:level=0" \
    $ENC hit_$n.wav
  n=$((n+1))
done
# slice + heavy thud: hits on a boss
n=1
for pair in "knifeSlice.ogg impactSoft_heavy_000" "knifeSlice2.ogg impactSoft_heavy_001" "knifeSlice.ogg impactSoft_heavy_002"; do
  set -- $pair
  ffmpeg -y -loglevel error -i "$RPG/$1" -i "$IMP/$2.ogg" -filter_complex \
    "[0:a]atrim=0:0.22,asetpts=PTS-STARTPTS,afade=t=out:st=0.08:d=0.14,volume=0.7,$FMT[a];[1:a]atrim=0:0.4,afade=t=out:st=0.22:d=0.18,$FMT,volume=0.9[b];[a][b]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.9:level=0" \
    $ENC hit_boss_$n.wav
  n=$((n+1))
done
# heavy thud + a low thump: the hero takes a hit
n=1
for t in impactSoft_heavy_000 impactSoft_heavy_001 impactSoft_heavy_003; do
  ffmpeg -y -loglevel error -i "$IMP/$t.ogg" -f lavfi -i "aevalsrc=0.7*sin(2*PI*75*t)*exp(-t*16):d=0.35:s=44100" -filter_complex \
    "[0:a]$FMT,volume=1.0[a];[1:a]$FMT[b];[a][b]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.9:level=0" \
    $ENC hurt_$n.wav
  n=$((n+1))
done
# heavy thud, then a leather body drop a moment later: an enemy falls
n=1
for t in impactSoft_heavy_001 impactSoft_heavy_002 impactSoft_heavy_003; do
  ffmpeg -y -loglevel error -i "$IMP/$t.ogg" -i "$RPG/dropLeather.ogg" -filter_complex \
    "[0:a]$FMT,volume=0.9[a];[1:a]$FMT,adelay=90:all=1,volume=0.8[b];[a][b]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.9:level=0" \
    $ENC enemy_die_$n.wav
  n=$((n+1))
done
for f in hit_*.wav hit_boss_*.wav hurt_*.wav enemy_die_*.wav; do
  printf "%-16s " "$f"; ffmpeg -hide_banner -i "$f" -af volumedetect -f null - 2>&1 | grep -oE "max_volume: [-0-9.]+ dB|Duration: [0-9:.]+" | tr '\n' ' '; echo
done
