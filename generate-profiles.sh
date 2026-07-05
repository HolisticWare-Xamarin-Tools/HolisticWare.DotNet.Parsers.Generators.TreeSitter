#!/usr/bin/env bash
# generate-profiles.sh
# Generates profiles.md — a markdown document showing binary artifacts per profile, organized by platform.
#
# Usage: ./generate-profiles.sh [OUTPUT_DIR]
#   OUTPUT_DIR  = directory where profiles.md is written (default: current working directory)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve the externals/native directory
EXTERNALS_NATIVE="$SCRIPT_DIR/externals/native"
if [ ! -d "$EXTERNALS_NATIVE" ]; then
  echo "ERROR: externals/native not found at $EXTERNALS_NATIVE" >&2
  exit 1
fi

OUT_DIR="${1:-$SCRIPT_DIR}"
MD_FILE="$OUT_DIR/profiles.md"
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

PROFILES=("balanced" "debug" "size" "speed")
PLATFORMS=("android/arm64" "ios/arm64" "linux/arm64" "linux/x86_64" "macos/arm64" "macos/x86_64" "windows/x64")

# Collect all unique binary names per platform across ALL profiles
# Output: one file per platform containing sorted unique basenames
for plat in "${PLATFORMS[@]}"; do
  outfile="$TMPDIR_WORK/bins_${plat//\//_}.txt"
  : > "$outfile"
  for profile in "${PROFILES[@]}"; do
    plat_dir="$EXTERNALS_NATIVE/out-$profile/$plat"
    [ -d "$plat_dir" ] || continue
    find "$plat_dir" -type f \( -name "*.dylib" -o -name "*.so" -o -name "*.a" -o -name "*.dll" -o -name "*.lib" \) 2>/dev/null | xargs -I{} basename {} 2>/dev/null || true
  done | sort -u > "$outfile"
done

# Collect file sizes for balanced profile per platform
for plat in "${PLATFORMS[@]}"; do
  outfile="$TMPDIR_WORK/sizes_${plat//\//_}.txt"
  : > "$outfile"
  src_dir="$EXTERNALS_NATIVE/out-balanced/$plat"
  [ -d "$src_dir" ] || continue
  while IFS= read -r f; do
    bname=$(basename "$f")
    size=$(stat -f%z "$f" 2>/dev/null || echo "?")
    echo "$bname	$size"
  done < <(find "$src_dir" -type f \( -name "*.dylib" -o -name "*.so" -o -name "*.a" -o -name "*.dll" -o -name "*.lib" \) 2>/dev/null || true) | sort > "$outfile"
done

# Format size to human-readable
format_size() {
  local bytes="$1"
  if [ "$bytes" = "?" ] || [ -z "$bytes" ]; then
    echo "-"
    return
  fi
  if [ "$bytes" -ge 1048576 ] 2>/dev/null; then
    echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}")MB"
  elif [ "$bytes" -ge 1024 ] 2>/dev/null; then
    echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1024}")KB"
  else
    echo "${bytes}B"
  fi
}

# Check if binary exists in a given profile/platform
bin_exists() {
  local profile="$1" plat="$2" bname="$3"
  [ -f "$EXTERNALS_NATIVE/out-$profile/$plat/$bname" ] && echo "✓" || echo "–"
}

# ──────────── Generate Markdown ────────────

{
  echo "# Build Profiles — Binary Artifacts Report"
  echo ""
  echo "Auto-generated on $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo ""
  echo "## Overview"
  echo ""
  echo "| Profile | Description |"
  echo "|---------|-------------|"
  echo "| balanced | Balanced optimization (Release + LTO + strip) |"
  echo "| debug    | Debug build (no optimization, no LTO, no strip) |"
  echo "| size     | Size-optimized (Os + LTO + strip) |"
  echo "| speed    | Speed-optimized (O2 + LTO + strip) |"
  echo ""

  for plat in "${PLATFORMS[@]}"; do
    plat_display=$(echo "$plat" | sed 's/\// \//')

    # Get binary list for this platform
    bins_file="$TMPDIR_WORK/bins_${plat//\//_}.txt"
    [ -f "$bins_file" ] || continue
    [ -s "$bins_file" ] || continue

    echo "## Platform: $plat_display"
    echo ""

    # Build header row
    header="| Binary |"
    for profile in "${PROFILES[@]}"; do
      header+=" $profile |"
    done
    header+=" Size"
    echo "$header"

    separator="|--------|"
    for _ in "${PROFILES[@]}"; do
      separator+=" --------|"
    done
    separator+=" -------"
    echo "$separator"

    # Data rows — read from sorted binary list
    while IFS= read -r bname; do
      [ -z "$bname" ] && continue
      row="| \`$bname\` |"
      for profile in "${PROFILES[@]}"; do
        row+=" $(bin_exists "$profile" "$plat" "$bname") |"
      done

      # Look up size from sizes file
      size=$(grep "^${bname}	" "$TMPDIR_WORK/sizes_${plat//\//_}.txt" 2>/dev/null | cut -f2 || echo "?")
      row+=" $(format_size "${size:-?}")"
      echo "$row"
    done < "$bins_file"

    echo ""
  done

  # ──────────── Summary Table ────────────
  echo "## Summary"
  echo ""
  echo "| Platform | Balanced | Debug | Size | Speed | Total Unique Binaries |"
  echo "|----------|----------|-------|------|-------|----------------------|"

  for plat in "${PLATFORMS[@]}"; do
    bins_file="$TMPDIR_WORK/bins_${plat//\//_}.txt"
    [ -f "$bins_file" ] || continue
    [ -s "$bins_file" ] || continue

    balanced_count=0; debug_count=0; size_count=0; speed_count=0
    while IFS= read -r bname; do
      [ -z "$bname" ] && continue
      [ -f "$EXTERNALS_NATIVE/out-balanced/$plat/$bname" ] && balanced_count=$((balanced_count + 1))
      [ -f "$EXTERNALS_NATIVE/out-debug/$plat/$bname" ] && debug_count=$((debug_count + 1))
      [ -f "$EXTERNALS_NATIVE/out-size/$plat/$bname" ] && size_count=$((size_count + 1))
      [ -f "$EXTERNALS_NATIVE/out-speed/$plat/$bname" ] && speed_count=$((speed_count + 1))
    done < "$bins_file"

    total=$(wc -l < "$bins_file" | tr -d ' ')
    plat_display=$(echo "$plat" | sed 's/\// \//')
    echo "| $plat_display | $balanced_count | $debug_count | $size_count | $speed_count | $total |"
  done

  echo ""
} > "$MD_FILE"

echo "Generated: $MD_FILE"
echo "Profiles covered: ${PROFILES[*]}"
echo "Platforms covered: ${PLATFORMS[*]}"
