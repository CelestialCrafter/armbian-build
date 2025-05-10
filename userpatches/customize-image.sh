SETTINGS_PATH="/tmp/overlay/settings.json"

# wifi
INTERFACE="$(jq -r '.wifi.interface' $SETTINGS_PATH)"
cat /tmp/overlay/wifi.yaml

awk \
    -v iface=$INTERFACE \
    -v ssid="$(jq -r '.wifi.ssid' $SETTINGS_PATH)" \
    -v pw="$(jq -r '.wifi.password' $SETTINGS_PATH)" \
    '{gsub(/SSID/, ssid); gsub(/PASSWORD/, pw); gsub(/INTERFACE/, iface)}1' \
    /tmp/overlay/wifi.yaml > /etc/netplan/20-wifi.yaml
chmod 600 /etc/netplan/20-wifi.yaml

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

