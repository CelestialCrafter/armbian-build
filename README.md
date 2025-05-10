# armbian-build

arbian build configs for my radxa rock 5b+

## instructions

1. comment out the `wifi` section in `userpatches/overlay/customize-image.fish` if needed
    if you commented it out, you can also leave out the `wifi` section in `settings.json`
2. create `userpatches/overlay/settings.json` with this format:
    ```json
    {
        "wifi": {
            "interface": "WIFI INTERFACE",
            "ssid": "WIFI SSID",
            "password": "WIFI PASSWORD"
        },
        "passwords": {
            "root": "ROOT PW",
            "server": "SERVER PW",
        }
    }
    ```
4. edit or remove `userpatches/extensions/fstab.sh`
4. edit the `users` section in `userpatches/overlay/customize-image.fish`
6. run `./compile.sh celestial-homelab`
8. set `$DEVICE` to a nvme drive, and `$IMG` to `output/images/ARMBIAN IMAGE.img`
10. run `./write-img.sh` (with `root` perms)
