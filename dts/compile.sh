#!/bin/sh
DTC=~/git/dtc/dtc

$DTC -@ -I dts -O dtb rame-cid1-r1kbd-overlay.dts > rame-cid1-r1kbd.dtbo
$DTC -@ -I dts -O dtb rame-cid2-textlcd-overlay.dts > rame-cid2-textlcd.dtbo
$DTC -@ -I dts -O dtb rame-cid3-r2kbd-overlay.dts > rame-cid3-r2kbd.dtbo
$DTC -@ -I dts -O dtb rame-cid5-audio-overlay.dts > rame-cid5-audio.dtbo
$DTC -@ -I dts -O dtb rame-cid4-lcd-overlay.dts > rame-cid4-lcd.dtbo
$DTC -@ -I dts -O dtb rame-cid6-rtc-overlay.dts > rame-cid6-rtc.dtbo
$DTC -@ -I dts -O dtb rame-cid7-extbuttons-overlay.dts > rame-cid7-extbuttons.dtbo
