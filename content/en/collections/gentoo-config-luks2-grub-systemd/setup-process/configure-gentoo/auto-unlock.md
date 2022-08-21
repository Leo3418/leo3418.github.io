---
title: "Let Passphrase Be Asked Only Once During Boot"
weight: 334
---

With the LUKS configuration achieved at this point, there will be two different
passphrase prompts during boot: one from GRUB, and the other from systemd.
Once GRUB unlocks the LUKS partition, it loads the kernel and initramfs on it,
so the initramfs can start systemd to complete system boot; however, GRUB
cannot pass the passphrase or the unlock state to systemd, so to systemd, the
LUKS partition will still be locked.

![systemd asks for passphrase for the second time during the boot
process]({{< static-path img systemd-unlock.png >}})

Having to enter the same passphrase twice during boot degrades the user
experience.  To solve this problem, a key file can be created and added to
LUKS.  The key file will be accessible by systemd during the initramfs stage,
and systemd can use it to unlock the LUKS partition without asking for a
passphrase.

The key file will be embedded in the initramfs, and because the initramfs is
stored in the LUKS partition, the key file is inaccessible unless the LUKS
partition is unlocked.  After the correct passphrase is entered in GRUB, the
LUKS partition is unlocked, the initramfs is loaded, and the key file becomes
available.  The passphrase is still the only way to unlock the LUKS partition
when it is locked, unless a copy of the key file is available outside the LUKS
partition, or another key is added.  Therefore, this method eliminates the
second passphrase prompt without compromising the LUKS partition's security
while it is locked.

## Create a Key File

For the sake of security, the key file must be a unique file.  Do not use files
that can be easily replicated or acquired by someone else as a key file, such
as simple plain text files and music files.  Use of a new, randomly-created
file is recommended.  The following commands allow such a file to be created
and added to systemd's standard location for LUKS key files --
`/etc/cryptsetup-keys.d`:

```console
# mkdir /etc/cryptsetup-keys.d
# dd if=/dev/urandom of=/etc/cryptsetup-keys.d/gentoo.key bs=1 count=4096
```

The key file's security is pivotal to the security of data on the LUKS
partition.  It shall be treated in the same manner as SSH private keys and PGP
private keys.  Therefore, its file permission shall be limited to `root` access
only since unlocking a LUKS partition always requires superuser privilege.

```console
# chmod 600 /etc/cryptsetup-keys.d/gentoo.key
```

## Add the Key File to LUKS

Once the key is created and secured, it can be added to the LUKS partition.
Remember that some encryption parameters, including but not limited to
`--pbkdf` and `--hash`, apply on a per-key basis, so they need to be specified
for the key individually again:

```console
# cryptsetup luksAddKey /dev/sda2 /etc/cryptsetup-keys.d/gentoo.key --pbkdf argon2id --hash sha512
```

## Set Up Automatic Unlock for systemd

To let systemd unlock and open the LUKS partition automatically, systemd must
know the mapping device's name it should use.  This is specified from file
`/etc/crypttab`.

Before populating the file's content, the LUKS partition's UUID is needed.  It
is available in the output of command `cryptsetup luksDump`:

```console {hl_lines=[7]}
# cryptsetup luksDump /dev/sda2
LUKS header information
Version:       	2
Epoch:         	4
Metadata area: 	16384 [bytes]
Keyslots area: 	16744448 [bytes]
UUID:          	b8360e90-66e4-4ff5-84d1-c8e2174bf007
Label:         	(no label)
Subsystem:     	(no subsystem)
Flags:       	(no flags)

...
```

Once the UUID is obtained, it can be added to `/etc/crypttab`, where each line
represents a LUKS partition to unlock automatically and has the following
fields.  Fields are separated by white space.

1. The name of the mapping device for the LUKS partition, under `/dev/mapper`.
2. The LUKS partition specification, which can be its UUID (`UUID=` prefix
   needed).
3. The path to the key file used to automatically unlock the partition.  `-`
   can be used to replace the path if the key file is stored at a default path.
   The default paths are dependent on the value of the mapping device's name
   (i.e. field 1): if, for example, the name is `luks`, then
   `/etc/cryptsetup-keys.d/luks.key` is a default path.
4. Any options for the LUKS partition; can be left out if no options are to be
   specified.

More information about the file's format is given in the [`crypttab(5)` manual
page][man-crypttab.5].

For example, when the following content is added to `/etc/crypttab`, systemd
will unlock the partition with UUID `b8360e90-66e4-4ff5-84d1-c8e2174bf007` and
make it available at `/dev/mapper/gentoo`, using the key file at
`/etc/cryptsetup-keys.d/gentoo.key` since field 3's value is `-`.

```sh
# /etc/crypttab

gentoo UUID=b8360e90-66e4-4ff5-84d1-c8e2174bf007 -
```

Readers who have the LUKS partition on an SSD might want to enable
[TRIM][arch-wiki-trim] for it but should also **be aware of some [security
implications][arch-wiki-ssd-dm-crypt] associated with TRIM on LUKS** before
doing so.  To enable TRIM, add `discard` as an option for the LUKS partition to
field 4.

```sh
# /etc/crypttab

gentoo UUID=b8360e90-66e4-4ff5-84d1-c8e2174bf007 - discard
```

## Ensure the Files Will Be Added to initramfs

Finally, all these files that have just been created need to be included in the
initramfs.  This can be done by declaring them in dracut's configuration files,
under the `install_items` option.

```console
# mkdir /etc/dracut.conf.d
# echo 'install_items+=" /etc/crypttab "' >> /etc/dracut.conf.d/cryptsetup.conf
# echo 'install_items+=" /etc/cryptsetup-keys.d/gentoo.key "' >> /etc/dracut.conf.d/cryptsetup.conf
```

[man-crypttab.5]: https://man.archlinux.org/man/crypttab.5
[arch-wiki-trim]: https://wiki.archlinux.org/title/Solid_state_drive#TRIM
[arch-wiki-ssd-dm-crypt]: https://wiki.archlinux.org/title/Solid_state_drive#dm-crypt
