#!/bin/sh
DTC=~/git/dtc/dtc
$DTC -@ -I dts -O dtb rame-eeprom-overlay.dts > rame-eeprom-overlay.dtb
