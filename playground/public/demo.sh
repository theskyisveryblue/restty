#!/bin/sh
# restty demo v4 - debug logging active
# -----------------------------------
FAST="0"
NO_WAIT="0"
PLAIN="0"

ESC=$(printf '\033')
CSI="${ESC}["
while [ "$#" -gt 0 ]; do
  arg="$1"
  case "$arg" in
    --fast) FAST=1 ;;
    --no-wait) NO_WAIT=1 ;;
    --plain) PLAIN=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./demo.sh [options]

Options:
  --fast      Shorter animation timings
  --no-wait   Exit immediately at the end (no keypress)
  --plain     Skip heavy animation, print showcase only
  -h, --help  Show this help
EOF
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
      exit 1
      ;;
  esac
  shift
done

# Check if stdout is a TTY
if ! [ -t 1 ]; then
  printf 'Interactive TTY not detected; run this in a terminal for full animation.\n'
  PLAIN=1
  NO_WAIT=1
fi

if [ "$FAST" -eq 1 ]; then
  TYPE_DELAY=0.005
  FRAME_DELAY=0.03
  SPIN_CYCLES=9
  PARTICLE_FRAMES=52
  WAVE_FRAMES=28
else
  TYPE_DELAY=0.012
  FRAME_DELAY=0.06
  SPIN_CYCLES=16
  PARTICLE_FRAMES=84
  WAVE_FRAMES=42
fi

# Try to get terminal size, fallback to 24x80
stty_size=$(stty size 2>/dev/null || echo "24 80")
TERM_ROWS=$(echo "$stty_size" | cut -d' ' -f1)
TERM_COLS=$(echo "$stty_size" | cut -d' ' -f2)
TERM_ROWS=${TERM_ROWS:-24}
TERM_COLS=${TERM_COLS:-80}

cleanup() {
  reset_seq="${CSI}0m${CSI}?25h${CSI}?1000l${CSI}?1002l${CSI}?1003l${CSI}?1006l${CSI}?2004l${CSI}?2027l"
  if [ -t 1 ]; then
    printf '%s' "${reset_seq}"
  fi
}
trap cleanup EXIT INT TERM

hide_cursor() { printf '%s?25l' "${CSI}"; }
show_cursor() { printf '%s?25h' "${CSI}"; }
clear_screen() { printf '%s2J%sH' "${CSI}" "${CSI}"; }
move() { printf '%s%d;%dH' "${CSI}" "$1" "$2"; }
sleep_frame() { sleep "${FRAME_DELAY}"; }

repeat_char() {
  char=$1
  count=$2
  out=""
  i=0
  while [ "$i" -lt "$count" ]; do
    out="${out}${char}"
    i=$((i + 1))
  done
  printf '%s' "$out"
}

pad_line() {
  text=$1
  width=$2
  printf '%-*.*s' "$width" "$width" "$text"
}

type_line() {
  row=$1
  col=$2
  text=$3
  color=${4:-"37"}

  move "$row" "$col"
  printf '%s38;5;%sm' "${CSI}" "$color"

  # POSIX way to iterate over characters
  i=1
  len=$(printf "%s" "$text" | wc -c)
  while [ "$i" -le "$len" ]; do
    ch=$(printf "%s" "$text" | cut -c "$i")
    printf '%s' "$ch"
    if [ "$PLAIN" -eq 0 ]; then
      sleep "${TYPE_DELAY}"
    fi
    i=$((i + 1))
  done
  printf '%s0m' "${CSI}"
}

draw_header() {
  title="restty webcontainer demo"
  subtitle="animated terminal capabilities"
  w=$((TERM_COLS - 6))
  top=1
  # Shell strings instead of arrays for colors
  colors="45 81 117 153 189 225 219 213 207 201 165 129 93"

  clear_screen
  hide_cursor

  move "$top" 2
  printf '┌'
  repeat_char "─" "$w"
  printf '┐'

  move $((top + 1)) 2
  printf '│ '
  i=1
  len=$(printf "%s" "$title" | wc -c)
  while [ "$i" -le "$len" ]; do
    c=$(printf "%s" "$title" | cut -c "$i")
    # Get color from space-separated list
    color_idx=$(( (i - 1) % 13 + 1 ))
    color=$(echo "$colors" | cut -d' ' -f"$color_idx")
    printf '%s38;5;%sm%s' "${CSI}" "$color" "$c"
    i=$((i + 1))
  done
  printf '%s0m' "${CSI}"
  pad_w=$((w - len - 1))
  if [ "$pad_w" -gt 0 ]; then
    repeat_char " " "$pad_w"
  fi
  printf '│'

  move $((top + 2)) 2
  printf '│ %s' "$(pad_line "${subtitle}" $((w - 1)))"
  printf '│'

  move $((top + 3)) 2
  printf '└'
  repeat_char "─" "$w"
  printf '┘'
}

scene_boot() {
  y=6
  x=4
  bar_width=$((TERM_COLS - 18))
  [ "$bar_width" -lt 18 ] && bar_width=18

  steps="booting_webcontainer_bridge probing_terminal_capabilities warming_glyph_and_color_pipeline syncing_demo_assets"

  set -- $steps
  while [ "$#" -gt 0 ]; do
    step_raw="$1"
    shift
    step=$(echo "$step_raw" | tr '_' ' ')
    s=0
    while [ "$s" -lt "$SPIN_CYCLES" ]; do
      pct=$(( (s + 1) * 100 / SPIN_CYCLES ))
      fill=$(( pct * bar_width / 100 ))
      empty=$(( bar_width - fill ))

      # Spinner
      spin_chars="|/-\\"
      sp_idx=$(( (s % 4) + 1 ))
      sp=$(printf "%s" "$spin_chars" | cut -c "$sp_idx")

      move "$y" "$x"
      printf '%s38;5;39m[%s] %s' "${CSI}" "$sp" "$(pad_line "$step" 36)"
      printf '%s0m' "${CSI}"

      move $((y + 1)) "$x"
      printf '  %s38;5;46m' "${CSI}"
      repeat_char "█" "$fill"
      printf '%s38;5;240m' "${CSI}"
      repeat_char "░" "$empty"
      printf '%s0m %3d%%' "${CSI}" "$pct"

      if [ "$PLAIN" -eq 0 ]; then
        sleep_frame
      fi
      s=$((s + 1))
    done
    y=$((y + 3))
  done
}

scene_wave() {
  row=$((TERM_ROWS - 5))
  start_col=4
  width=$((TERM_COLS - 8))
  palette="196 202 208 214 220 226 190 154 118 82 46 47 48 49 51 45 39 33 27 21 57 93 129 165"
  p_len=24

  [ "$row" -lt 12 ] && row=12
  [ "$width" -lt 24 ] && width=24

  move $((row - 1)) "$start_col"
  printf '%s38;5;250m%s%s0m' "${CSI}" "$(pad_line "color wave renderer sweep" "$width")" "${CSI}"

  frame=0
  while [ "$frame" -lt "$WAVE_FRAMES" ]; do
    move "$row" "$start_col"
    col=0
    while [ "$col" -lt $((width / 2)) ]; do
      idx_pos=$(( (col + frame) % p_len + 1 ))
      idx=$(echo "$palette" | cut -d' ' -f"$idx_pos")
      printf '%s48;5;%sm  ' "${CSI}" "$idx"
      col=$((col + 1))
    done
    printf '%s0m' "${CSI}"
    if [ "$PLAIN" -eq 0 ]; then
      sleep_frame
    fi
    frame=$((frame + 1))
  done
}

scene_particles() {
  y_top=10
  y_bot=$((TERM_ROWS - 8))
  x_left=4
  x_right=$((TERM_COLS - 4))

  [ "$y_bot" -le "$y_top" ] && return 0
  [ "$x_right" -le "$x_left" ] && return 0

  move 9 4
  printf '%s38;5;250mparticle field (bounce simulation)%s0m' "${CSI}" "${CSI}"

  # Particles: x, y, vx, vy
  # We'll use a simple loop for few particles in POSIX sh
  num_particles=8
  # Initial positions/velocities encoded in strings
  px="10 20 30 40 15 25 35 45"
  py="11 12 13 14 15 16 11 12"
  vx="1 1 -1 -1 1 -1 1 -1"
  vy="1 -1 1 -1 -1 1 1 -1"
  colors="45 51 81 117 154 190 226 220"
  glyphs="· * ✦ · * ✦ · *"

  f=0
  while [ "$f" -lt "$PARTICLE_FRAMES" ]; do
    # Clear old positions
    p=1
    while [ "$p" -le "$num_particles" ]; do
      cur_x=$(echo "$px" | cut -d' ' -f"$p")
      cur_y=$(echo "$py" | cut -d' ' -f"$p")
      move "$cur_y" "$cur_x"
      printf ' '
      p=$((p + 1))
    done

    # Update and Draw
    new_px=""
    new_py=""
    new_vx=""
    new_vy=""
    p=1
    while [ "$p" -le "$num_particles" ]; do
      cur_x=$(echo "$px" | cut -d' ' -f"$p")
      cur_y=$(echo "$py" | cut -d' ' -f"$p")
      cur_vx=$(echo "$vx" | cut -d' ' -f"$p")
      cur_vy=$(echo "$vy" | cut -d' ' -f"$p")
      cur_col=$(echo "$colors" | cut -d' ' -f"$p")
      cur_gly=$(echo "$glyphs" | cut -d' ' -f"$p")

      nx=$((cur_x + cur_vx))
      ny=$((cur_y + cur_vy))

      if [ "$nx" -le "$x_left" ] || [ "$nx" -ge "$x_right" ]; then
        cur_vx=$(( -cur_vx ))
        nx=$((cur_x + cur_vx))
      fi
      if [ "$ny" -le "$y_top" ] || [ "$ny" -ge "$y_bot" ]; then
        cur_vy=$(( -cur_vy ))
        ny=$((cur_y + cur_vy))
      fi

      new_px="${new_px}${nx} "
      new_py="${new_py}${ny} "
      new_vx="${new_vx}${cur_vx} "
      new_vy="${new_vy}${cur_vy} "

      move "$ny" "$nx"
      printf '%s38;5;%sm%s%s0m' "${CSI}" "$cur_col" "$cur_gly" "${CSI}"
      p=$((p + 1))
    done
    px=$new_px
    py=$new_py
    vx=$new_vx
    vy=$new_vy

    if [ "$PLAIN" -eq 0 ]; then
      sleep_frame
    fi
    f=$((f + 1))
  done
}

scene_showcase() {
  row=$((TERM_ROWS - 12))
  [ "$row" -lt 14 ] && row=14

  move "$row" 4
  printf '%s38;5;117mstyles:%s0m %s1mbold%s0m %s3mitalic%s0m %s4munderline%s0m %s9mstrike%s0m' \
    "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}"

  move $((row + 1)) 4
  printf '%s38;5;117municode:%s0m 你好 世界  日本語  🇺🇸 🇯🇵  👨‍👩‍👧  ⠋⠙⠹⠸  ┌─┬─┐' "${CSI}" "${CSI}"

  move $((row + 2)) 4
  printf '%s38;5;117mtruecolor:%s0m %s38;2;255;100;0morange%s0m %s38;2;120;200;255msky%s0m %s38;2;160;255;160mmint%s0m' \
    "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}" "${CSI}"

  move $((row + 3)) 4
  printf '%s38;5;117mnerd symbols:%s0m 󰄛            ' "${CSI}" "${CSI}"
}

scene_outro() {
  row=$((TERM_ROWS - 3))
  move "$row" 4
  printf '%s38;5;46mDemo complete.%s0m run %s1m./test.sh%s0m for a static capability sweep.' \
    "${CSI}" "${CSI}" "${CSI}" "${CSI}"
}

# Main Execution
draw_header

if [ "$PLAIN" -eq 1 ]; then
  scene_showcase
  scene_outro
else
  type_line 5 4 "Launching animated demo scenes..." 81
  scene_boot
  scene_particles
  scene_wave
  scene_showcase
  scene_outro
fi

if [ "$NO_WAIT" -eq 0 ]; then
  move "$TERM_ROWS" 1
  printf '%s38;5;245mPress enter to exit...%s0m' "${CSI}" "${CSI}"
  read -r _
fi

show_cursor
move "$TERM_ROWS" 1
printf '\n'
