---
title: "Prepare the LUKS Partition"
weight: 320
toc: false
---

First, double check the block device for the LUKS partition.  This can be done
by checking whether the size for the block device in the `lsblk` command's
output matches the LUKS partition's size:

```console
$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0   320M  1 loop /mnt/livecd
sda      8:0    0 119.2G  0 disk
├─sda1   8:1    0   100M  0 part
└─sda2   8:2    0 119.1G  0 part
sdb      8:16   0  14.6G  0 disk /mnt/cdrom
├─sdb1   8:17   0   370M  0 part
└─sdb2   8:18   0  10.5M  0 part
```

Next, ensure all existing important data on the LUKS partition has been backed
up.  If an existing Gentoo installation is being encrypted, then a full system
backup is required, so that the installation can be properly restored later on.
Available means of full system backup include but are not limited to these
ones:
- Partition images [created using `dd`][gentoo-wiki-dd]
- If ext4, ext3 or ext2 is used, partition clones made with [the `e2image`
  program][arch-wiki-e2image] from e2fsprogs
- If Btrfs is used, [Btrfs snapshots][arch-wiki-btrfs-snapshot] for **every**
  subvolume that are [sent][arch-wiki-btrfs-send] to a different place

Make sure the backup is stored somewhere outside the LUKS partition!  It is
strongly recommended that the backup is transferred to a different storage
media (e.g. a different drive or a network location), and the media is
immediately disconnected after the transfer completes.
{.notice--warning}

Once it is ready to erase the LUKS partition's content, the `cryptsetup`
program can be invoked to initialize it using LUKS2 and Argon2id as the PBKDF.
This is also an opportunity to customize some encryption parameters, like the
passphrase hash specified with the `--hash` option.  SHA-256 might be used as
the default, but SHA-512 might be a more secure choice on 64-bit systems as per
[this answer][se-infosec-sha512] on Information Security Stack Exchange:

> SHA-512 requires 64-bit operations that reduce the margin of a GPU based
> attacker's advantage, since modern GPU's don't do 64-bit as well.

Based on my benchmark on a Dell XPS 15 9570 with an Intel Core i7-8750H CPU,
using SHA-512 instead of SHA-256 per se does not have any impact on the LUKS
partition's unlock speed in GRUB.

```console
# cryptsetup luksFormat /dev/sda2 --type luks2 --pbkdf argon2id --hash sha512
```

`cryptsetup` will ask for the initial passphrase.  Once the operation
completes, the LUKS partition can be unlocked and opened for subsequent steps
using the same passphrase.  Opening the LUKS partition utilizes dm-crypt, a
feature provided by the Linux kernel's [device mapper][wikipedia-device-mapper]
framework, and thus creates a mapping device node under `/dev/mapper`.  The
mapping device's name needs to be specified in the `cryptsetup` command opening
the LUKS partition, such as:

```console
# cryptsetup luksOpen /dev/sda2 gentoo
```

This command creates the mapping device node for the unlocked LUKS partition at
`/dev/mapper/gentoo`, which can be used as a normal block device.  The
subsequent steps demonstrate some usage of it.

[gentoo-wiki-dd]: https://wiki.gentoo.org/wiki/Dd#Hard_disk_backup
[arch-wiki-e2image]: https://wiki.archlinux.org/title/Disk_cloning#Using_e2image
[arch-wiki-btrfs-snapshot]: https://wiki.archlinux.org/title/Btrfs#Snapshots
[arch-wiki-btrfs-send]: https://wiki.archlinux.org/title/Btrfs#Send/receive
[se-infosec-sha512]: https://security.stackexchange.com/a/112592
[wikipedia-device-mapper]: https://en.wikipedia.org/wiki/Device_mapper
