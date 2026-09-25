#!/usr/bin/env bash
# Local build + flash for Catlove Macro Pad v2 (OLED) on nice!nano v2.
# Needs Docker Desktop running. Steps:
#   1. builds settings_reset + catlove_macro_pad_oled (ZMK v0.3) in Docker
#   2. flashes settings_reset to NICENANO, then the OLED firmware
set -euo pipefail
cd "$(dirname "$0")"
REPO="$PWD"
OUT="$REPO/firmware"
IMAGE="zmkfirmware/zmk-build-arm:3.5"
VOLUME="zmk-catlove-workspace"
DRIVE="/Volumes/NICENANO"

command -v docker >/dev/null || { echo "Docker not found. Install Docker Desktop and start it."; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker is not running. Start Docker Desktop."; exit 1; }
mkdir -p "$OUT"

echo "==> Building firmware (first run downloads ZMK/Zephyr, takes a few minutes)"
docker run --rm -v "$VOLUME":/work -v "$REPO":/zmk-config -w /work "$IMAGE" bash -euc '
  if [ ! -d .west ]; then
    mkdir -p config && cp /zmk-config/config/west.yml config/
    west init -l config
  fi
  cp /zmk-config/config/west.yml config/
  west update --fetch-opt=--filter=tree:0
  west zephyr-export >/dev/null
  west build -p -s zmk/app -d build/reset -b nice_nano_v2 -- -DSHIELD=settings_reset
  west build -p -s zmk/app -d build/oled -b nice_nano_v2 -S studio-rpc-usb-uart -- \
    -DSHIELD=catlove_macro_pad_oled \
    -DZMK_CONFIG=/zmk-config/config \
    -DZMK_EXTRA_MODULES=/zmk-config \
    -DCONFIG_ZMK_STUDIO=y
  grep -E "^CONFIG_(ZMK_DISPLAY|SSD1306|LV_COLOR_DEPTH_1|LV_Z_BITS_PER_PIXEL|I2C)=" build/oled/zephyr/.config
  cp build/reset/zephyr/zmk.uf2 /zmk-config/firmware/settings_reset-nice_nano_v2.uf2
  cp build/oled/zephyr/zmk.uf2  /zmk-config/firmware/catlove_macro_pad_oled-nice_nano_v2.uf2
'
echo "==> Built: $OUT"; ls -l "$OUT"

flash() {
  local file="$1" what="$2"
  echo
  echo ">>> Double-tap RESET on the nice!nano to enter the bootloader ($what)..."
  until [ -d "$DRIVE" ]; do sleep 1; done
  sleep 1
  echo "    NICENANO found, copying $(basename "$file")"
  cp -X "$file" "$DRIVE/" 2>/dev/null || true   # board reboots mid-copy; that is normal
  until [ ! -d "$DRIVE" ]; do sleep 1; done
  echo "    Done: $what flashed."
}

flash "$OUT/settings_reset-nice_nano_v2.uf2" "settings reset"
echo "    Settings are wiped. Remove the macropad from Bluetooth devices on your computer."
flash "$OUT/catlove_macro_pad_oled-nice_nano_v2.uf2" "Catlove OLED firmware"
echo
echo "All done. The OLED should show the status screen now."
