#!/bin/sh -e

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

makefile root:shadow 0640 "$tmp"/etc/shadow <<'EOF'
root:$6$aX.E08MuE1v0fNlH$ihmYbDsEOp6UH.LSD6HkO/eV9fCY5tkeSvpMyrZsWzdlpNggdAvSdb8fiigSoisKahylx2zH4QV/ewrfGsa3T1:16947:0:::::
bin:!::0:::::
daemon:!::0:::::
adm:!::0:::::
lp:!::0:::::
sync:!::0:::::
shutdown:!::0:::::
halt:!::0:::::
mail:!::0:::::
news:!::0:::::
uucp:!::0:::::
operator:!::0:::::
man:!::0:::::
postmaster:!::0:::::
cron:!::0:::::
ftp:!::0:::::
sshd:!::0:::::
at:!::0:::::
squid:!::0:::::
gdm:!::0:::::
xfs:!::0:::::
games:!::0:::::
named:!::0:::::
mysql:!::0:::::
postgres:!::0:::::
apache:!::0:::::
nut:!::0:::::
cyrus:!::0:::::
vpopmail:!::0:::::
ntp:!::0:::::
postfix:!::0:::::
smmsp:!::0:::::
distcc:!::0:::::
guest:!::0:::::
nobody:!::0:::::
chrony:!:16721:0:99999:7:::
messagebus:!:0:0:99999:7:::
mosquitto:!:0:0:99999:7:::
EOF

makefile root:root 0644 "$tmp"/etc/rame-upgrade.conf <<EOF
FIRMWARE_URI="rsync://dev.rameplayer.org/rameplayer-master/"
EOF
ln -sf /usr/share/zoneinfo/Europe/Helsinki "$tmp"/etc/localtime
echo "Europe/Helsinki" > "$tmp"/etc/timezone

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback
EOF

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/repositories <<EOF
/media/mmcblk0p1/apks
EOF
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
evtest
rameplayer
EOF
ln -sf /media/mmcblk0p1/cache "$tmp"/etc/apk/cache

mkdir -p "$tmp"/root/.ssh
makefile root:root 0600 "$tmp/root/.ssh/authorized_keys" <<'EOF'
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL3uxJ64ChnZfolbCNkHi//EN5oKot0sBQ4ETnBNyy645OETeDnJvz4E7ZeqIGZ/QynmIbPwJiXQ/ENbXkFldDE= fabled
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPTZweBlih7IDA3x0yaJ2CX4/6k48UB7YV5CKtSDsJBmIz+QUMuFHZjq/TyuiBlj9sCNCzBrAtSTFKe0asSMvmw= tonic
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBKTBG1h5g2jtORtzEjiYHfbWr14d0MN6krdH1BwxMNXSwyUS4YlGTXbK36IDRa3kPNW0OYs/Wv2Slkm2wntytrQ= iqqmut
ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBACiJESE40hxEwyaQ3PXjptQZDV33ap+eD+y4jEFsNEkyDg3pemZcuSfqMWozgCcAZpcjKFfHEB3thoHjgWQxIXR5ADJHh6wPVzgHTRWPPLtcmJ0OIglS1/IbQJtB+R4psg+Oj5JbYNwDY9zvtslQRDi4htHuvquZPJm7feIejX5T6Zxrw== kunkku
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEArlsTgtXL0shOkrU6NczD0UpWaAPDgptBd9EWZ0kw9+9EpaQkRZXCBIs+xWITngMrnOdVfiRDbSrtOaCtNCHpSa/iXA3F+FFzpMJyglU9SKKzTp16lmQv97rMOlDC2bIYgj3ei1oHYOt/Nzhbww5wvM8T0loS0Gfz0/9oCK1r9Kq9Q7ZbRLk5uFxDMmih80dVGBlHcDUtzX3a4XEURVqIwSlautgl9daszIvdTLrnzO7qQ2fA7sOncnhCKW05nVy5eblK1Ewv7bQwApZOUBkuZjYnEbc0BrvdRB5OpKnt7wRqTs9vpBnQl5/0GO0zfHg1m8gc+aiz6y/VdpPd8iekcw== tonic
EOF

tar -c -C "$tmp" etc root | gzip -9n > $HOSTNAME.apkovl.tar.gz
