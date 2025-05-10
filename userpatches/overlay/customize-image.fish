set -g SETTINGS_PATH "/tmp/overlay/settings.json"

# users
useradd -s /usr/bin/fish -G sudo celestial
usermod -s /usr/bin/fish root

for user in string split "\0" (jq -r '.passwords | to_entries | map("\(.key)\0\(.value)") | .[]' $SETTINGS_PATH)
	set -l name user[1]
	set -l password user[2]

	usermod -p $password $name
end

# wifi
INTERFACE=(jq -r '.wifi.interface' $SETTINGS_PATH)
install -m 600 (awk \
    -v iface=$INTERFACE \
    -v ssid="$(jq -r '.wifi.ssid' $SETTINGS_PATH)" \
    -v pw="$(jq -r '.wifi.password' $SETTINGS_PATH)" \
    '{gsub(/SSID/, ssid); gsub(/PASSWORD/, pw); gsub(/INTERFACE/, iface)}1' \
    /tmp/overlay/wifi.yaml | psub) \
    /etc/netplan/20-wifi.yaml

mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
echo "[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --timeout 30 -i $INTERFACE" > \
    /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf

# armbian stuff
rm /etc/update-motd.d/*
rm /etc/profile.d/armbian-*

systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer
systemctl disable dpkg-db-backup.timer
systemctl disable man-db.timer

# misc
armbian-add-overlay /tmp/overlay/fan-control.dts
echo "user_overlays=fan-control" >> /boot/armbianEnv.txt

echo "celestial-homelab" > /etc/hostname

# ssh
install -o root -g root /tmp/overlay/celestial-homelab_ed25519 /etc/ssh/celestial-homelab_ed25519
cp /tmp/overlay/sshd_config /etc/ssh/sshd_config.d/overlay.conf

# mpd
cp /tmp/overlay/mpd.conf /etc/mpd.conf
systemctl enable mpd

# containers
podman load -i /tmp/overlay/celestials-closet.tar
mkdir -p /etc/containers/systemd/
cp /tmp/overlay/containers/* /etc/containers/systemd/

