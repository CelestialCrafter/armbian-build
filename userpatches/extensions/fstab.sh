function format_partitions__fstab() {
	echo "PARTUUID=5bdfc84e-e755-4d4d-91a3-c43668353bc9 /home btrfs subvol=@home,defaults 0 2
	PARTUUID=5bdfc84e-e755-4d4d-91a3-c43668353bc9 /var btrfs subvol=@var,defaults 0 2" >> $SDCARD/etc/fstab
}
