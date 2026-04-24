#!/bin/bash
set -eu
ROOT="/Users/alexlamb/Desktop/AE_Exports/image_bank_live"
THUMBS="$ROOT/thumbs"
WEB="$ROOT/web"
MANIFEST="$ROOT/manifest.json"

MJ_DIR="/Users/alexlamb/Desktop/AE_Exports/Projects/Stan_Store_Courses/midjourney_curated"
CROW_DIR="/Users/alexlamb/Desktop/AE_Exports/Projects/CultOfSocial/meta_reels/generated"
REMI_DIR="/Users/alexlamb/Desktop/AE_Exports/Projects/Baddie.exe/video"
ALTAI_DIR1="/Users/alexlamb/Desktop/AE_Exports/Projects/LoopWorker/gumroad_products/tier3_v2/proofs_locked_3brands/altai_wool"
ALTAI_DIR2="/Users/alexlamb/Desktop/AE_Exports/Projects/LoopWorker/gumroad_products/2 - Brand Worlds/altai_wool/Content"
ACES_DIR1="/Users/alexlamb/Desktop/AE_Exports/Projects/LoopWorker/gumroad_products/output/agency_course_images"

mkdir -p "$THUMBS" "$WEB"

gather() {
  local source="$1"; shift
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    if [ "$source" = "remi" ]; then
      find "$dir" -type d \( -name "images" -o -name "starting_images" -o -name "intro_images" \) -print0 2>/dev/null | while IFS= read -r -d '' d; do
        find "$d" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null
      done
    elif [ "$source" = "crow" ]; then
      find "$dir" -type d -name "crow_*" -print0 2>/dev/null | while IFS= read -r -d '' d; do
        find "$d" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null
      done
    else
      find "$dir" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null
    fi
  done
}

LIST="$ROOT/_list.tsv"
> "$LIST"
gather mj "$MJ_DIR" | awk -v s=mj 'BEGIN{FS=OFS="\t"}{print s, $0}' >> "$LIST"
gather crow "$CROW_DIR" | awk -v s=crow 'BEGIN{FS=OFS="\t"}{print s, $0}' >> "$LIST"
gather remi "$REMI_DIR" | awk -v s=remi 'BEGIN{FS=OFS="\t"}{print s, $0}' >> "$LIST"
gather altai "$ALTAI_DIR1" "$ALTAI_DIR2" | awk -v s=altai 'BEGIN{FS=OFS="\t"}{print s, $0}' >> "$LIST"
# ACES: only files matching aces/tennis in agency images
find "$ACES_DIR1" -maxdepth 1 -type f \( -iname "*aces*" -o -iname "*tennis*" \) \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | awk -v s=aces 'BEGIN{FS=OFS="\t"}{print s, $0}' >> "$LIST"

echo "Found: $(wc -l < "$LIST") images"

i=0
> "$MANIFEST.tmp"
echo "[" > "$MANIFEST.tmp"
FIRST=1
while IFS=$'\t' read -r source src; do
  i=$((i+1))
  base=$(basename "$src")
  ext="${base##*.}"
  id="${source}_$(printf '%04d' $i)"
  thumb="$THUMBS/${id}.jpg"
  web_img="$WEB/${id}.jpg"
  if [ ! -f "$thumb" ]; then
    sips -s format jpeg -s formatOptions 70 -Z 400 "$src" --out "$thumb" >/dev/null 2>&1 || continue
  fi
  if [ ! -f "$web_img" ]; then
    sips -s format jpeg -s formatOptions 82 -Z 1400 "$src" --out "$web_img" >/dev/null 2>&1 || continue
  fi
  esc_src=$(printf '%s' "$src" | sed 's/\\/\\\\/g; s/"/\\"/g')
  esc_base=$(printf '%s' "$base" | sed 's/\\/\\\\/g; s/"/\\"/g')
  if [ $FIRST -eq 1 ]; then FIRST=0; else echo "," >> "$MANIFEST.tmp"; fi
  printf '{"id":"%s","source":"%s","thumb":"thumbs/%s.jpg","web":"web/%s.jpg","name":"%s"}' "$id" "$source" "$id" "$id" "$esc_base" >> "$MANIFEST.tmp"
  if [ $((i % 50)) -eq 0 ]; then echo "  ...$i processed"; fi
done < "$LIST"
echo "]" >> "$MANIFEST.tmp"
mv "$MANIFEST.tmp" "$MANIFEST"
echo "Done: $i entries in manifest"
