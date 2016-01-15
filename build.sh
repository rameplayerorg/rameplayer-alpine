#!/bin/sh

# locally built packages should be in apk repositories
# packages: kmod imagemagick alpine-sdk

RPI_FIRMWARE_COMMITID=1a3022d5c181e51f3d5437ddd82531007e86b5d0
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

file_update() {
	local tmp=$(mktemp)
	local to="$1"
	shift
	"$@" > $tmp
	if [ -e "$to" ] && cmp -s "$to" "$tmp"; then
		echo "No update for $to"
		rm "$tmp"
	else
		echo "Updated $to"
		chmod a+r "$tmp"
		mv "$tmp" "$to"
	fi
}

file_update "$TARGET"/config.txt cat <<EOF
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
file_update "$TARGET"/cmdline.txt cat <<EOF
modules=loop,squashfs,sd-mod,usb-storage blacklist=fbcon quiet
EOF

# boot logo, requires imagemagic installed
file_update "$TARGET"/fbsplash.ppm  convert logo_fb0.png ppm:-
file_update "$TARGET"/fbsplash1.ppm convert logo_fb1.png ppm:-

for dts in dts/*.dts; do
	local overlay=$(basename $dts .dts)
	file_update "$TARGET"/overlays/$overlay.dtb \
		dtc -@ -I dts -O dtb dts/$overlay.dts
done
