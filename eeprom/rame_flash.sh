#!/bin/sh


## Build EEPROM binary with device tree overlay:
#./eepmake rame_eeprom_settings.txt rame_eeprom.bin rame-overlay.dtb

# Build EEPROM binary without device tree overlay:
./eepmake rame_eeprom_settings.txt rame_eeprom.bin


# Flash binary to EEPROM:
./eepflash.sh -w -f=rame_eeprom.bin -t=24c32
