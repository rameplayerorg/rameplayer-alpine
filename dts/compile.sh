#!/bin/sh
DTC=~/git/dtc/dtc
$DTC -@ -I dts -O dtb rame-overlay.dts > rame-overlay.dtb

$DTC -@ -I dts -O dtb rame-cid1-r1kbd-overlay.dts > rame-cid1-r1kbd-overlay.dtb
$DTC -@ -I dts -O dtb rame-cid2-textlcd-overlay.dts > rame-cid2-textlcd-overlay.dtb
$DTC -@ -I dts -O dtb rame-cid3-r2kbd-overlay.dts > rame-cid3-r2kbd-overlay.dtb
$DTC -@ -I dts -O dtb rame-cid5-audio-overlay.dts > rame-cid5-audio-overlay.dtb
$DTC -@ -I dts -O dtb rame-cid4-lcd-overlay.dts > rame-cid4-lcd-overlay.dtb
$DTC -@ -I dts -O dtb rame-cid6-rtc-overlay.dts > rame-cid6-rtc-overlay.dtb
