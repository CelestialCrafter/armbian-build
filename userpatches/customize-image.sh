SETTINGS_PATH="/tmp/overlay/settings.json"

# packages
curl -fsSL https://pkgs.tailscale.com/stable/debian/sid.noarmor.gpg > /usr/share/keyrings/tailscale-archive-keyring.gpg
curl -fsSL https://pkgs.tailscale.com/stable/debian/sid.tailscale-keyring.list > /etc/apt/sources.list.d/tailscale.list

apt-get update
apt-get install -y vim podman catatonit nftables tailscale mpd

# users
useradd -s /usr/bin/bash -G sudo server
for user in root server; do
	jq --arg user "$user" -r '.user_passwords[$user]' $SETTINGS_PATH | passwd -s "$user"
done

# wifi
INTERFACE="$(jq -r '.wifi.interface' $SETTINGS_PATH)"

awk \
    -v interface=$INTERFACE \
    -v ssid="$(jq -r '.wifi.ssid' $SETTINGS_PATH)" \
    -v pw="$(jq -r '.wifi.password' $SETTINGS_PATH)" \
    '{gsub(/SSID/, ssid); gsub(/PASSWORD/, pw)}1' \
    /tmp/overlay/wifi.yaml > /etc/netplan/20-wifi.yaml
chmod 600 /etc/netplan/20-wifi.yaml

sed -i 's/\(ExecStart=/usr/lib/systemd/systemd-networkd-wait-online\)/\1 --timeout 30 -i /'$INTERFACE'/' /usr/lib/systemd/system/systemd-networkd-wait-online.service

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
cp /tmp/overlay/sshd_config /etc/ssh/sshd_config.d/overlay.conf

# mpd
cp /tmp/overlay/mpd.conf /etc/mpd.conf
systemctl enable mpd

# containers
mkdir -p /etc/containers/systemd/
cp /tmp/overlay/containers/* /etc/containers/systemd/

awk -v key="$(jq -r '.soft_serve_admin_key' $SETTINGS_PATH)" \
    '{gsub(/ADMIN_KEY$/, key)}1' \
    /tmp/overlay/containers/soft-serve.container > /etc/containers/systemd/soft-serve.container

