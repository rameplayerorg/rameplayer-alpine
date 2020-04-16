#!/bin/sh

# Usage: ./build.sh [directory]
#
# Image will be built on given directory or if not given,
# _image under current directory.

# locally built packages should be in apk repositories
# packages: kmod imagemagick alpine-sdk fakeroot
# other:    sudo ln -s $PWD/rame.modules /etc/mkinitfs/features.d/

RPI_FIRMWARE_COMMITID=11a76e07ef1b6304a378c4ee3da200fe6facea46
INITRAMFS_FEATURES="base bootchart ext4 keymap kms mmc rame squashfs usb"
TARGET="$1"
if [ -z "$TARGET" ]; then
	# default value for image directory
	TARGET=$PWD/_image
fi

# Build our packages first
ret=0
for A in rameplayer-keys rameplayer-webui rameplayer-utils rameplayer-backend rameplayer; do
	(cd ramepkg/$A ; abuild -r 2>&1) || ret=1
done
[ "$ret" == 0 ] || return $ret

# Prepare kernels, initramfs, modloop and dtbs
kernel_new="$(apk fetch --repositories-file $PWD/repositories --simulate linux-rpi linux-rpi2|sort -u)"
kernel_old="$(cat .rpi_kernel 2>/dev/null)"
[ "${kernel_old}" != "${kernel_new}" ] && rm -rf "$TARGET"/boot "$TARGET"/overlays "$TARGET"/*.dtb

# Ugly hack to fix mkinitfs using local filesystem features
# instead of the package ones
export features_dir=/etc/mkinitfs/features.d/

mkdir -p "$TARGET"/boot "$TARGET"/overlays "$TARGET"/cache "$TARGET"/media
[ ! -e $TARGET/boot/vmlinuz-rpi  ] && update-kernel --repositories-file $PWD/repositories -f rpi  -a armhf --media -p rameplayer-keys -F "$INITRAMFS_FEATURES" "$TARGET"
[ ! -e $TARGET/boot/vmlinuz-rpi2 ] && update-kernel --repositories-file $PWD/repositories -f rpi2 -a armhf --media -p rameplayer-keys -F "$INITRAMFS_FEATURES" "$TARGET"
rm -rf "$TARGET"/boot/System.map*
[ "${kernel_old}" != "${kernel_new}" ] && echo "${kernel_new}" > .rpi_kernel

# apk repository
mkdir -p "$TARGET"/apks/armhf
apk fetch --repositories-file $PWD/repositories --purge --output "$TARGET"/apks/armhf --recursive \
	alpine-base acct busybox evtest strace tmux rameplayer musl-dbg omxplayer-dbg \
	&& \
apk index \
	--description "Rameplayer build $(date)" \
	--rewrite-arch armhf \
	--index "$TARGET"/apks/armhf/APKINDEX.tar.gz \
	--output "$TARGET"/apks/armhf/APKINDEX.tar.gz \
	"$TARGET"/apks/armhf/*.apk \
	&& \
abuild-sign "$TARGET"/apks/armhf/APKINDEX.tar.gz \
	|| { rm -f "$TARGET"/apks/armhf/APKINDEX.tar.gz ; exit 1; }
touch "$TARGET"/apks/.boot_repository

# RPi firmware and boot config
OLD_FW="$(cat .rpi_firmware_commitid 2>/dev/null)"
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
		return 1
	else
		echo "Updated $to"
		chmod a+r "$tmp"
		mv "$tmp" "$to"
		return 0
	fi
}

file_update "$TARGET"/config.txt cat <<EOF
disable_splash=1
boot_delay=0
gpu_mem=256
gpu_mem_256=64
[pi0]
kernel=boot/vmlinuz-rpi
initramfs boot/initramfs-rpi 0x08000000
[pi1]
kernel=boot/vmlinuz-rpi
initramfs boot/initramfs-rpi 0x08000000
[pi2]
kernel=boot/vmlinuz-rpi2
initramfs boot/initramfs-rpi2 0x08000000
[pi3]
kernel=boot/vmlinuz-rpi2
initramfs boot/initramfs-rpi2 0x08000000
[all]
disable_overscan=1
config_hdmi_boost=5
hdmi_force_hotplug=1
audio_pwm_mode=2
include user/ramehw.txt
include user/ramecfg.txt
include user/config.txt
EOF

#modules=loop,squashfs,sd-mod,usb-storage quiet chart
file_update "$TARGET"/cmdline.txt cat <<EOF
modules=loop,squashfs,sd-mod,usb-storage fbcon=map:9 dwc_otg.fiq_fsm_mask=0x5 quiet
EOF

# boot logo, requires imagemagic installed
file_update "$TARGET"/fbsplash.ppm  convert logo_fb0.png ppm:-
file_update "$TARGET"/fbsplash1.ppm convert logo_fb1.png ppm:-

for dts in dts/*.dts; do
	overlay=$(basename $dts .dts)
	file_update "$TARGET"/overlays/${overlay%-overlay}.dtbo \
		dtc -@ -I dts -O dtb dts/$overlay.dts
done

# overlay
if [ ! -e "rame.apkovl.tar.gz" ] || [ "genapkovl.sh" -nt "rame.apkovl.tar.gz" ]; then
	fakeroot ./genapkovl.sh rame
fi
file_update "$TARGET"/rame.apkovl.tar.gz cat rame.apkovl.tar.gz
file_update "$TARGET"/factory.rst cat rame.apkovl.tar.gz

# firmware version
file_update "$TARGET"/rameversion.txt echo "dev-$(date +%Y%m%d)"

exit 0
