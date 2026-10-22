#!/bin/sh
# restty test v2
ESC=$(printf '\033')
CSI="${ESC}["

cleanup() {
  reset_seq="${CSI}0m${CSI}?25h${CSI}?1000l${CSI}?1002l${CSI}?1003l${CSI}?1006l${CSI}?2004l${CSI}?2027l"
  printf '%s' "${reset_seq}"
}
trap cleanup EXIT

printf '%s' "${CSI}?25l"  # hide cursor
printf '%s' "${CSI}2J${CSI}H"  # clear screen, home

printf '%s\n' "restty terminal capability test"
printf '%s\n' "---------------------------------"

# Styles
printf '\n%s\n' "Styles:"
printf '%s\n' "${CSI}1mBold${CSI}0m ${CSI}2mDim${CSI}0m ${CSI}3mItalic${CSI}0m ${CSI}4mUnderline${CSI}0m ${CSI}9mStrike${CSI}0m ${CSI}7mReverse${CSI}0m"

# Underline styles (single/double) if supported
printf '%s\n' "${CSI}4:1mUnderline (single)${CSI}0m ${CSI}4:2mUnderline (double)${CSI}0m"

# Basic colors 16
printf '\n%s\n' "Base 16 colors:"
i=0
while [ "$i" -le 15 ]; do
  printf '%s' "${CSI}48;5;${i}m  ${CSI}0m"
  if [ $(( (i+1) % 8 )) -eq 0 ]; then printf '\n'; fi
  i=$((i + 1))
done

# 256-color ramp
printf '\n%s\n' "256-color ramp (6x6x6):"
r=0
while [ "$r" -le 5 ]; do
  g=0
  while [ "$g" -le 5 ]; do
    b=0
    while [ "$b" -le 5 ]; do
      idx=$((16 + r*36 + g*6 + b))
      printf '%s' "${CSI}48;5;${idx}m  ${CSI}0m"
      b=$((b + 1))
    done
    printf ' '
    g=$((g + 1))
  done
  printf '\n'
  r=$((r + 1))
done

# Grayscale ramp
printf '\n%s\n' "Grayscale ramp:"
i=232
while [ "$i" -le 255 ]; do
  printf '%s' "${CSI}48;5;${i}m  ${CSI}0m"
  i=$((i + 1))
done
printf '\n'

# Truecolor
printf '\n%s\n' "Truecolor:"
printf '%s\n' "${CSI}38;2;255;100;0mOrange${CSI}0m ${CSI}38;2;120;200;255mSky${CSI}0m ${CSI}38;2;160;255;160mMint${CSI}0m"
printf '%s\n' "${CSI}48;2;60;60;60m  ${CSI}0m ${CSI}48;2;120;40;40m  ${CSI}0m ${CSI}48;2;40;120;40m  ${CSI}0m"

# Box drawing
printf '\n%s\n' "Box drawing:"
printf '┌──────────────────────────────┐\n'
printf '│  mono renderer box drawing   │\n'
printf '└──────────────────────────────┘\n'

# Braille / block elements
printf '\n%s\n' "Braille / block elements:"
printf '⠀⠁⠂⠄⡀⢀⣀⣿  ░▒▓█  ▁▂▃▄▅▆▇█\n'

# Combining marks / graphemes
printf '\n%s\n' "Combining marks / graphemes:"
printf '%s' "${CSI}?2027h"
printf 'é  ñ  ä  ô  ZWJ: 👨‍👩‍👧  Flags: 🇺🇸 🇯🇵\n'

# Wide chars (CJK)
printf '\n%s\n' "CJK / wide characters:"
printf '你好 世界  日本語  한글  가나다  漢字\n'

# Nerd symbols (PUA)
printf '\n%s\n' "Nerd symbols:"
printf '󰄛                \n'

# Cursor styles (block/underline/bar)
printf '\n%s\n' "Cursor styles (if supported by renderer):"
printf '%s' "${CSI}2 q"  # block
printf 'block ' 
printf '%s' "${CSI}4 q"  # underline
printf 'underline '
printf '%s' "${CSI}6 q"  # bar
printf 'bar\n'

# Mouse mode SGR enable/disable (do not leave enabled before read)
printf '%s' "${CSI}?1000h${CSI}?1002h${CSI}?1006h${CSI}?1000l${CSI}?1002l${CSI}?1006l"

printf '\n%s\n' "Done. Press enter to restore cursor."
read -r _

cleanup
printf '%s\n' "ok"
