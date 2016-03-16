#!/bin/sh

# locally built packages should be in apk repositories
# packages: kmod imagemagick alpine-sdk
# other:    sudo ln -s $PWD/rame.modules /etc/mkinitfs/features.d/

RPI_FIRMWARE_COMMITID=fa931b468e18df9be6a379991a0d74264dc3e4c7
INITRAMFS_FEATURES="base bootchart ext4 keymap kms mmc rame squashfs usb"
TARGET=$PWD/_image

# Build our packages first
local ret=0
for A in lua-cqueues-pushy rameplayer-webui rameplayer-utils rameplayer-backend rameplayer; do
	(cd ramepkg/$A ; abuild -r) || ret=1
done
[ "$ret" == 0 ] || return $ret

# Prepare kernels, initramfs, modloop and dtbs
kernel_new="$(apk fetch --simulate linux-rpi linux-rpi2|sort -u)"
kernel_old="$(cat .rpi_kernel 2>/dev/null)"
[ "${kernel_old}" != "${kernel_new}" ] && rm -rf "$TARGET"/boot

# Ugly hack to fix mkinitfs using local filesystem features
# instead of the package ones
export features_dir=/etc/mkinitfs/features.d/

mkdir -p "$TARGET"/boot "$TARGET"/overlays "$TARGET"/cache
[ ! -e $TARGET/boot/vmlinuz-rpi  ] && update-kernel -f rpi  -a armhf -F "$INITRAMFS_FEATURES" "$TARGET"/boot
[ ! -e $TARGET/boot/vmlinuz-rpi2 ] && update-kernel -f rpi2 -a armhf -F "$INITRAMFS_FEATURES" "$TARGET"/boot
if [ -e "$TARGET"/boot/dtbs ]; then
	mv -f "$TARGET"/boot/dtbs/*.dtb "$TARGET"
	[ -e "$TARGET"/boot/dtbs/overlays ] && mv -f "$TARGET"/boot/dtbs/overlays/*.dtb "$TARGET"/overlays
	rm -rf "$TARGET"/boot/dtbs "$TARGET"/boot/System.map-rpi*
fi
[ "${kernel_old}" != "${kernel_new}" ] && echo "${kernel_new}" > .rpi_kernel

# apk repository
mkdir -p "$TARGET"/apks/armhf
apk fetch --purge --output "$TARGET"/apks/armhf --recursive \
	alpine-base acct strace tmux rameplayer \
	&& \
apk index --description "Rameplayer build $(date)" --rewrite-arch armhf \
	--index "$TARGET"/apks/armhf/APKINDEX.tar.gz \
	--output "$TARGET"/apks/armhf/APKINDEX.tar.gz \
	"$TARGET"/apks/armhf/*.apk \
	&& \
abuild-sign "$TARGET"/apks/armhf/APKINDEX.tar.gz \
	|| { rm -f "$TARGET"/apks/armhf/APKINDEX.tar.gz ; exit 1; }
touch "$TARGET"/apks/.boot_repository

# RPi firmware and boot config
local OLD_FW="$(cat .rpi_firmware_commitid 2>/dev/null)"
for fw in bootcode.bin fixup.dat start.elf ; do
	if [ "${RPI_FIRMWARE_COMMITID}" != "${OLD_FW}" -o ! -e $TARGET/$fw ]; then
		curl --remote-time https://raw.githubusercontent.com/raspberrypi/firmware/${RPI_FIRMWARE_COMMITID}/boot/${fw} \
			--output "$TARGET"/${fw} || exit 1
	fi
done
echo -n "${RPI_FIRMWARE_COMMITID}" > .rpi_firmware_commitid

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
disable_overscan=1
config_hdmi_boost=7
hdmi_clock_change_limit=20
hdmi_force_hotplug=1
include user/ramehw.txt
include user/ramecfg.txt
include user/config.txt
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

# firmware version
file_update "$TARGET"/rameversion.txt echo "dev-$(date +%Y%m%d)"
