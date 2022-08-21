---
title: "Configure Miscellaneous System Components"
weight: 336
---

## Update `/etc/fstab`

For **both** a new Gentoo installation and encryption of an existing
installation, the `/etc/fstab` file needs to be checked and updated as needed.

This is apparently required for a new installation because the default
`/etc/fstab` in stage3 is just a template.  But for an existing installation,
because the file system has been recreated on the LUKS partition, its partition
identifiers -- including but are not limited to its UUID -- are changed, so an
update to `/etc/fstab` is needed too.  Even if the block device name is used in
`/etc/fstab` to identify the partition, the block device for the file system is
also changed after LUKS configuration from `/dev/sda2` to `/dev/mapper/gentoo`
for example, so an update is still necessary.

When updating the content of `/etc/fstab`, please make sure that the new
partition identifier (i.e. the first field in a line) is for the file system
*on* the LUKS partition rather than the LUKS partition itself.  The LUKS
partition is just like an encrypted container for other partitions; it cannot
be mounted directly.  Instead, the file system on the LUKS partition ultimately
stores the system files.

### Identify the File System by UUID

The file system's UUID can be retrieved using the `blkid` command, with the
LUKS partition's mapping device node under `/dev/mapper` as the argument:

```console
# blkid /dev/mapper/gentoo
/dev/mapper/gentoo: UUID="f50a9ad7-a0fc-4e77-9d34-5b98823958ab" BLOCK_SIZE="4096" TYPE="ext4"
```

In this example, the UUID is `f50a9ad7-a0fc-4e77-9d34-5b98823958ab`.

```diff
- UUID=5b91813d-554e-47af-b803-6799c94f8ee5     /           ext4    noatime     0 1
+ UUID=f50a9ad7-a0fc-4e77-9d34-5b98823958ab     /           ext4    noatime     0 1
```

### Identify the File System by Block Device

The new block device identifier for the file system on the LUKS partition is
determined by the name [specified in `/etc/crypttab`][auto-unlock-crypttab].
If the name is `gentoo`, then the new block device for the file system is
`/dev/mapper/gentoo`.

```diff
- /dev/sda2             /           ext4    noatime     0 1
+ /dev/mapper/gentoo    /           ext4    noatime     0 1
```

[auto-unlock-crypttab]: {{< relref "auto-unlock.md#set-up-automatic-unlock-for-systemd" >}}

## New Installation Only: Configure System and Install Tools

If a new Gentoo installation is being performed, then please follow the instructions in the following Handbook chapters:

1. [Configuring the system](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Networking_information)

   Note: The *Filesystem information* section can be skipped because it is for
   filling in `/etc/fstab`, which should have been already done through the
   above instructions.

2. [Installing system tools](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools)
