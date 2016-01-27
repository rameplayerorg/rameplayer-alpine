#!/bin/sh
DTC=~/git/dtc/dtc
$DTC -@ -I dts -O dtb rame-r2-eeprom-overlay.dts > rame-r2-eeprom-overlay.dtb
