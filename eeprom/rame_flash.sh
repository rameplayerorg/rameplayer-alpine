#!/bin/sh

# Build EEPROM binary with device tree overlay:
./eepmake rame_eeprom_settings.txt rame_eeprom.bin rame-eeprom-overlay.dtb

# Flash binary to EEPROM:
./eepflash.sh -w -f=rame_eeprom.bin -t=24c32
