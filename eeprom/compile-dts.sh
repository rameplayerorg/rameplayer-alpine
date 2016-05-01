#!/bin/sh
DTC=~/git/dtc/dtc
$DTC -@ -I dts -O dtb rame-chassis05-eeprom-overlay.dts > rame-chassis05-eeprom-overlay.dtb
$DTC -@ -I dts -O dtb rame-chassis10-eeprom-overlay.dts > rame-chassis10-eeprom-overlay.dtb
$DTC -@ -I dts -O dtb rame-plain-extbuttons-eeprom-overlay.dts > rame-plain-extbuttons-eeprom-overlay.dtb
