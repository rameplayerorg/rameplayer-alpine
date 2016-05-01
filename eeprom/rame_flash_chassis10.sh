#!/bin/sh

# Build EEPROM binary with device tree overlay:
./eepmake rame_chassis10_eeprom_settings.txt rame_chassis10_eeprom.bin rame-chassis10-eeprom-overlay.dtb

# Flash binary to EEPROM:
./eepflash.sh -w -f=rame_chassis10_eeprom.bin -t=24c32
