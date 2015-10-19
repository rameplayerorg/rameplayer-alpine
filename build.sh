#!/bin/sh

# locally built packages should be in apk repositories
# packages: kmod imagemagick alpine-sdk

RPI_FIRMWARE_COMMITID=ba7a8fb709adab287495f4e836b1cd3e5c9db409
TARGET=$PWD/_image

# Build our packages first
local ret=0
for A in lua-cqueues-pushy rameplayer-webui rameplayer-backend; do
	(cd ramepkg/$A ; abuild -r) || ret=1
done
[ "$ret" == 0 ] || return $ret

# Prepare kernels, initramfs, modloop and dtbs
mkdir -p "$TARGET"/boot "$TARGET"/overlays "$TARGET"/cache
[ ! -e $TARGET/boot/vmlinuz-rpi  ] && update-kernel -f rpi  -a armhf "$TARGET"/boot
[ ! -e $TARGET/boot/vmlinuz-rpi2 ] && update-kernel -f rpi2 -a armhf "$TARGET"/boot
mv -f "$TARGET"/boot/dtbs/*.dtb "$TARGET"
mv -f "$TARGET"/boot/dtbs/overlays/*.dtb "$TARGET"/overlays
rm -rf "$TARGET"/boot/dtbs "$TARGET"/boot/System.map-rpi*

# apk repository
if [ ! -e $TARGET/apks ]; then
	mkdir -p "$TARGET"/apks/armhf
	apk fetch --output "$TARGET"/apks/armhf --recursive \
		alpine-base acct openssh tzdata strace tmux ffmpeg \
		raspberrypi omxplayer rsync dhcpcd eudev dbus \
		rameplayer-webui rameplayer-backend \
		&& \
	apk index --description "Rameplayer build $(date)" \
		--rewrite-arch armhf -o "$TARGET"/apks/armhf/APKINDEX.tar.gz "$TARGET"/apks/armhf/*.apk \
		&& \
	abuild-sign "$TARGET"/apks/armhf/APKINDEX.tar.gz \
		|| { rm -rf "$TARGET"/apks; exit 1; }
	touch "$TARGET"/apks/.boot_repository
fi

# RPi firmware and boot config
for fw in bootcode.bin fixup.dat start.elf ; do
	[ ! -e $TARGET/$fw ] && \
		curl https://raw.githubusercontent.com/raspberrypi/firmware/${RPI_FIRMWARE_COMMITID}/boot/${fw} -o "$TARGET"/${fw}
done

if [ ! -e "$TARGET"/config.txt ]; then
	cat <<EOF > $TARGET/config.txt
disable_splash=1
boot_delay=0
[pi1]
gpu_mem_256=128
gpu_mem_512=256
cmdline=cmdline-rpi.txt
kernel=boot/vmlinuz-rpi
initramfs boot/initramfs-rpi 0x08000000
[pi2]
gpu_mem=256
cmdline=cmdline-rpi2.txt
kernel=boot/vmlinuz-rpi2
initramfs boot/initramfs-rpi2 0x08000000
[all]
dtparam=i2c,spi
disable_overscan=1
config_hdmi_boost=4
hdmi_clock_change_limit=20
include usercfg.txt
EOF

	#local _opts="alpine_dev=mmcblk0p1 modules=loop,squashfs,sd-mod,usb-storage quiet chart"
	local _opts="alpine_dev=mmcblk0p1 modules=loop,squashfs,sd-mod,usb-storage blacklist=fbcon quiet"
	echo "BOOT_IMAGE=/boot/vmlinuz-rpi  $_opts" > $TARGET/cmdline-rpi.txt
	echo "BOOT_IMAGE=/boot/vmlinuz-rpi2 $_opts" > $TARGET/cmdline-rpi2.txt
fi

# boot logo, requires imagemagic installed
[ ! -e "$TARGET"/fbsplash.ppm ] && convert logo.png "$TARGET"/fbsplash.ppm
