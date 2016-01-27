#!/bin/sh

# Build EEPROM binary with device tree overlay:
./eepmake rame_r2_eeprom_settings.txt rame_r2_eeprom.bin rame-r2-eeprom-overlay.dtb

# Flash binary to EEPROM:
./eepflash.sh -w -f=rame_r2_eeprom.bin -t=24c32
