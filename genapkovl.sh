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

local tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

makefile root:root 0644 "$tmp"/etc/password <<EOF
root:x:0:0:root:/root:/bin/ash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
news:x:9:13:news:/usr/lib/news:/sbin/nologin
uucp:x:10:14:uucp:/var/spool/uucppublic:/sbin/nologin
operator:x:11:0:operator:/root:/bin/sh
man:x:13:15:man:/usr/man:/sbin/nologin
postmaster:x:14:12:postmaster:/var/spool/mail:/sbin/nologin
cron:x:16:16:cron:/var/spool/cron:/sbin/nologin
ftp:x:21:21::/var/lib/ftp:/sbin/nologin
sshd:x:22:22:sshd:/dev/null:/sbin/nologin
at:x:25:25:at:/var/spool/cron/atjobs:/sbin/nologin
squid:x:31:31:Squid:/var/cache/squid:/sbin/nologin
gdm:x:32:32:GDM:/var/lib/gdm:/sbin/nologin
xfs:x:33:33:X Font Server:/etc/X11/fs:/sbin/nologin
games:x:35:35:games:/usr/games:/sbin/nologin
named:x:40:40:bind:/var/bind:/sbin/nologin
mysql:x:60:60:mysql:/var/lib/mysql:/sbin/nologin
postgres:x:70:70::/var/lib/postgresql:/bin/sh
apache:x:81:81:apache:/var/www:/sbin/nologin
nut:x:84:84:nut:/var/state/nut:/sbin/nologin
cyrus:x:85:12::/usr/cyrus:/sbin/nologin
vpopmail:x:89:89::/var/vpopmail:/sbin/nologin
ntp:x:123:123:NTP:/var/empty:/sbin/nologin
postfix:x:207:207:postfix:/var/spool/postfix:/sbin/nologin
smmsp:x:209:209:smmsp:/var/spool/mqueue:/sbin/nologin
distcc:x:240:2:distccd:/dev/null:/sbin/nologin
guest:x:405:100:guest:/dev/null:/sbin/nologin
nobody:x:65534:65534:nobody:/:/sbin/nologin
chrony:x:100:1000:Linux User,,,:/var/log/chrony:/sbin/nologin
messagebus:x:101:101:Linux User,,,:/dev/null:/sbin/nologin
mosquitto:x:102:102:mosquitto:/var/empty:/sbin/nologin
EOF

makefile root:root 0644 "$tmp"/etc/shadow <<EOF
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
makefile root:root 0600 "$tmp/root/.ssh/authorized_keys" <<EOF
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL3uxJ64ChnZfolbCNkHi//EN5oKot0sBQ4ETnBNyy645OETeDnJvz4E7ZeqIGZ/QynmIbPwJiXQ/ENbXkFldDE= fabled
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPTZweBlih7IDA3x0yaJ2CX4/6k48UB7YV5CKtSDsJBmIz+QUMuFHZjq/TyuiBlj9sCNCzBrAtSTFKe0asSMvmw= tonic
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBKTBG1h5g2jtORtzEjiYHfbWr14d0MN6krdH1BwxMNXSwyUS4YlGTXbK36IDRa3kPNW0OYs/Wv2Slkm2wntytrQ= iqqmut
ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBACiJESE40hxEwyaQ3PXjptQZDV33ap+eD+y4jEFsNEkyDg3pemZcuSfqMWozgCcAZpcjKFfHEB3thoHjgWQxIXR5ADJHh6wPVzgHTRWPPLtcmJ0OIglS1/IbQJtB+R4psg+Oj5JbYNwDY9zvtslQRDi4htHuvquZPJm7feIejX5T6Zxrw== kunkku
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAhLtZzUCdYr0MwT+DAAvmyLySgyKTGIAwa5A+cmXJe5ocBVEHu2pH6dOkSjtk8drpmP211vETFRYg3Kzg7SPnQiaX87LcdbdMJX8u8WTUjT4lTMPrRwbyLvR77/pCaa0HeiTJrKwgktLAOpdLeTX+gVS+D5CVnKErRmDg4eGDsWM= tonic
EOF

tar -c -C "$tmp" etc root | gzip -9n > $HOSTNAME.apkovl.tar.gz
