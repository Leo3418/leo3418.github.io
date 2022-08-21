---
title: "Preparations"
weight: 331
---

## Create a File System

Although the LUKS partition has been initialized, it does not contain a file
system yet.  Either a new file system needs to be created, or, if an existing
Gentoo installation is being encrypted, the full system backup is restored to
recreate the original file system on the LUKS partition.

The exact procedure to create or restore the file system depends on which file
system is going to be used and/or the backup's format (if applicable).  The
following are just some examples:

- Create a single ext4 file system:
  ```console
  # mkfs.ext4 /dev/mapper/gentoo
  ```
- Create a Btrfs volume:
  ```console
  # mkfs.btrfs /dev/mapper/gentoo
  ```
- Create an LVM physical volume:
  ```console
  # pvcreate /dev/mapper/gentoo
  ```

For more information about file system creation, please feel free to consult
[the relevant section in the Handbook][handbook-create-fs].

Then, unless an LVM physical volume was created, the file system on the LUKS
partition can be mounted normally as it was not on a LUKS partition:

```console
# mount /dev/mapper/gentoo /mnt/gentoo
```

Readers who choose to use LVM on the LUKS partition need to undertake more
steps so that one or more logical volumes are created, and then the logical
volumes that will store the system files for Gentoo can be mounted under
`/mnt/gentoo`.

Readers who are restoring a full system backup should also mount the restored
file system to `/mnt/gentoo` for subsequent steps.

[handbook-create-fs]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Creating_file_systems

## New Installation Only: Unpack stage3

If a new Gentoo installation is being performed, then please follow the
[Handbook's instructions][handbook-stage] to unpack stage3 to the new file
system.

[handbook-stage]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage

## Chroot

Please follow the [related steps listed in the Handbook][handbook-chroot] to
enter the system on the LUKS partition via `chroot`.

Please do not continue to the *Configure Portage* step after the *Chrooting*
step in the manual yet.
{.notice--warning}

[handbook-chroot]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Chrooting
