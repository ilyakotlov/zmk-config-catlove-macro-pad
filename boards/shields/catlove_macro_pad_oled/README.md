# Catlove Macro Pad OLED

Separate hardware revision for the existing `nice_nano_v2` target on ZMK v0.3.
The original `catlove_macro_pad` shield and build are unchanged. The board target
comes from the existing project's build.yaml, not from identification of a new PCB.

## Wiring

| Function | nRF52840 GPIO | nice!nano / Pro Micro pin |
| --- | --- | --- |
| R0 | P0.06 | D1 |
| R1 | P0.08 | D0 |
| R2 | P0.17 | D2 |
| R3, encoder push switch row | P1.00 | D6 |
| C0 | P0.20 | D3 |
| C1 | P0.22 | D4 |
| C2 | P0.24 | D5 |
| C3 | P0.11 | D7 |
| EC11 A | P0.31 | A3 / D21 |
| EC11 B | P0.29 | A2 / D20 |
| EC11 C (rotation common) | GND | GND |
| OLED SDA | P1.15 | A0 / D18 |
| OLED SCL | P0.02 | A1 / D19 |

P1.00 is exposed as D6 in ZMK v0.3's
`app/boards/arm/nice_nano/arduino_pro_micro_pins.dtsi`. It is unused by this
revision's matrix, encoder rotation, I2C, USB, onboard LED and power control.
The original revision also used this pin, as a column.
UART0 is explicitly disabled because its default pins are R0/R1; Studio uses USB CDC.
I2C default and sleep pinctrl states are both remapped away from R2/C0.

The 12 MX switches occupy R0–R2/C0–C3. The encoder push switch is the
13th key at R3/C0: wire `C0 (P0.20) -> switch -> diode -> R3 (P1.00)`,
with the diode's cathode/stripe toward R3. Switch and diode may exchange order
in this series connection. All key diodes must use the same col2row direction
(cathode toward the row). The push switch is NOT connected to ground;
the rotary encoder's separate common C pin is connected to ground.
The logical scan matrix is 4x4 with only 13 populated positions.

Reset and ON/OFF remain hardware circuits and are not modeled in the shield.

## Test layout and display

```
1  2  3  4
5  6  7  8
9  0  -  =     MUTE (encoder push)
```

Clockwise raises volume; counterclockwise lowers it. If the physical encoder
reports the opposite direction, exchange A/B or the two sensor-binding arguments.
The encoder defaults to 80 transitions and 20 detents per revolution, matching
the original transition count; verify this against the actual EC11 variant.

OLED parameters assume the usual 0.91-inch SSD1306: **128x32, I2C address 0x3C**.
Confirm those on the module; size alone does not prove its address or geometry.
Use 3.3 V-compatible power and I2C pull-ups. The stock ZMK status screen is enabled.

ZMK Studio over USB is enabled, including the 13-key physical layout. As in the
original shield, Studio locking is disabled. If Studio has saved a previous layout,
restore the stock layout in Studio to use this test keymap. Existing Bluetooth
pairing/settings may persist when changing revisions.

## Build

The existing GitHub Actions workflow builds both entries in build.yaml.
In an initialized ZMK v0.3 west workspace with the required SDK and modules:

```sh
west build -s zmk/app -d build/catlove_macro_pad_oled -b nice_nano_v2 \
  -S studio-rpc-usb-uart -- \
  -DSHIELD=catlove_macro_pad_oled \
  -DZMK_CONFIG=/absolute/path/to/zmk-config-catlove-macro-pad/config \
  -DZMK_EXTRA_MODULES=/absolute/path/to/zmk-config-catlove-macro-pad \
  -DCONFIG_ZMK_STUDIO=y
```

Output: `build/catlove_macro_pad_oled/zephyr/zmk.uf2`.
For the original revision, use `catlove_macro_pad` as the shield and build directory.
Compilation does not verify soldering, OLED address, diode polarity or encoder detents.
