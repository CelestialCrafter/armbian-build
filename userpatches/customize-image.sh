curl -fsSL https://pkgs.tailscale.com/stable/debian/sid.noarmor.gpg > /usr/share/keyrings/tailscale-archive-keyring.gpg
curl -fsSL https://pkgs.tailscale.com/stable/debian/sid.tailscale-keyring.list > /etc/apt/sources.list.d/tailscale.list

apt-get update
apt-get install -y vim podman catatonit nftables tailscale mpd git fish
