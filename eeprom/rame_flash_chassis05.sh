#!/bin/sh

# Build EEPROM binary with device tree overlay:
./eepmake rame_chassis05_eeprom_settings.txt rame_chassis05_eeprom.bin rame-chassis05-eeprom-overlay.dtb

# Flash binary to EEPROM:
./eepflash.sh -w -f=rame_chassis05_eeprom.bin -t=24c32
