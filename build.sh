#!/bin/sh

# locally built packages should be in apk repositories
# packages: kmod imagemagick alpine-sdk

RPI_FIRMWARE_COMMITID=fa627390f76d7d3c38e80fc88ad1cc6697c04334
TARGET=$PWD/_image

# Build our packages first
local ret=0
for A in lua-cqueues-pushy rameplayer-webui rameplayer-utils rameplayer-backend rameplayer; do
	(cd ramepkg/$A ; abuild -r) || ret=1
done
[ "$ret" == 0 ] || return $ret

# Prepare kernels, initramfs, modloop and dtbs
mkdir -p "$TARGET"/boot "$TARGET"/overlays "$TARGET"/cache
[ ! -e $TARGET/boot/vmlinuz-rpi  ] && update-kernel -f rpi  -a armhf "$TARGET"/boot
[ ! -e $TARGET/boot/vmlinuz-rpi2 ] && update-kernel -f rpi2 -a armhf "$TARGET"/boot
if [ -e "$TARGET"/boot/dtbs ]; then
	mv -f "$TARGET"/boot/dtbs/*.dtb "$TARGET"
	mv -f "$TARGET"/boot/dtbs/overlays/*.dtb "$TARGET"/overlays
	rm -rf "$TARGET"/boot/dtbs "$TARGET"/boot/System.map-rpi*
fi

# apk repository
if [ ! -e $TARGET/apks ]; then
	mkdir -p "$TARGET"/apks/armhf
	apk fetch --output "$TARGET"/apks/armhf --recursive \
		alpine-base acct strace tmux rameplayer \
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

file_from_stdin() {
	local tmp=$(mktemp)
	cat > $tmp
	if cmp "$1" "$tmp"; then
		echo "No update for $1"
		rm "$tmp"
	else
		echo "Updated $1"
		mv "$tmp" "$1"
	fi
	chmod a+r "$1"
}

file_from_stdin "$TARGET"/config.txt <<EOF
disable_splash=1
boot_delay=0
[pi1]
gpu_mem_256=64
gpu_mem_512=256
kernel=boot/vmlinuz-rpi
initramfs boot/initramfs-rpi 0x08000000
[pi2]
gpu_mem=256
kernel=boot/vmlinuz-rpi2
initramfs boot/initramfs-rpi2 0x08000000
[all]
dtparam=i2c,spi
disable_overscan=1
config_hdmi_boost=4
hdmi_clock_change_limit=20
hdmi_force_hotplug=1
include usercfg.txt
EOF

#modules=loop,squashfs,sd-mod,usb-storage quiet chart
file_from_stdin "$TARGET"/cmdline.txt <<EOF
modules=loop,squashfs,sd-mod,usb-storage blacklist=fbcon quiet
EOF

# boot logo, requires imagemagic installed
if [ ! "$TARGET"/fbsplash.ppm -nt logo.png ]; then
	echo "Updating $TARGET/fbsplash.ppm"
	convert logo.png "$TARGET"/fbsplash.ppm
fi
