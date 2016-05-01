#!/bin/sh

# Build EEPROM binary with device tree overlay:
./eepmake rame_plain-extbuttons_eeprom_settings.txt rame_plain-extbuttons_eeprom.bin rame-plain-extbuttons-eeprom-overlay.dtb

# Flash binary to EEPROM:
./eepflash.sh -w -f=rame_plain-extbuttons_eeprom.bin -t=24c32
