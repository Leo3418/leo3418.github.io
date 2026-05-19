---
title: "Enable LUKS2 and Argon2 Support for Packages"
weight: 332
---

Because the LUKS partition uses LUKS2 and Argon2id, support for these LUKS
configurations must be enabled for all software packages that unlock the LUKS
partition.

## Set USE Flags

The following USE settings need to be added to `/etc/portage/package.use`:

```
sys-apps/systemd cryptsetup
sys-boot/grub device-mapper
sys-fs/cryptsetup argon2 -static-libs
```

The detailed instructions to do this are [available in the
Handbook][handbook-use-flags].

[handbook-use-flags]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Working/USE#Declaring_USE_flags_for_individual_packages

The USE flag settings for `sys-fs/cryptsetup` above should not change anything
as they are the same as the package's default USE flag settings, so they do not
need to be explicitly declared; rather, they are included for completeness.
The `argon2` USE flag must be enabled for Argon2id support.  The `static-libs`
USE flag must be disabled so `cryptsetup` can be built into the initramfs by
dracut, or else the LUKS partition could not be unlocked during boot.
{.notice--success}

## GRUB 2.12 and Lower Only: Add Patches for GRUB

GRUB has gained built-in support for LUKS2 and Argon2id support since 2.14, so
users of GRUB 2.14 or higher do not need to manually patch its source code to
manually add LUKS2 and Argon2id support.  These users can skip this step and
move on to the next one.

Users who need to use an older GRUB release for any reason, including 2.12 and
2.06, need to patch its source code to add LUKS2 and Argon2id support.  See
[the appendix]({{% relref "../../patch-grub" %}}) for instructions.

## New Installation Only: Initialize Portage

If a new Gentoo installation is being performed, then please follow the
instructions in the following Handbook sections under the *Configuring Portage*
chapter:
1. [Installing a Gentoo ebuild repository snapshot from the web](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Installing_a_Gentoo_ebuild_repository_snapshot_from_the_web)
2. [Optional: Selecting mirrors](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Optional:_Selecting_mirrors)
3. [Optional: Updating the Gentoo ebuild repository](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Optional:_Updating_the_Gentoo_ebuild_repository)
4. [Reading news items](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Reading_news_items)
5. [Choosing the right profile](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Choosing_the_right_profile)
6. [Optional: Adding a binary package host](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Optional:_Adding_a_binary_package_host)
7. [Optional: Configuring the USE variable](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Optional:_Configuring_the_USE_variable)
8. [Optional: Configure the ACCEPT_LICENSE variable](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Optional:_Configure_the_ACCEPT_LICENSE_variable)

## Rebuild Packages

First, build `sys-boot/grub` (with any patches applied, if needed).  Before
starting the build, please make sure that in the output of `emerge`,
`GRUB_PLATFORMS="efi-64"` is enabled for `sys-boot/grub`.  In other words,
please check that `efi-64` is listed *without* a minus sign (`-`) in front of
it under `GRUB_PLATFORMS`.  If this is not true, the Handbook has [related
instructions to fix it][handbook-grub-emerge].
```console
# emerge --ask --verbose sys-boot/grub

These are the packages that would be merged, in order:

Calculating dependencies... done!
[ebuild  N     ] sys-boot/grub-2.06-r2:2/2.06-r2::gentoo  USE="device-mapper fon
ts nls themes -doc -efiemu -libzfs -mount -sdl (-test) -truetype" GRUB_PLATFORMS
="efi-64 pc -coreboot -efi-32 -emu -ieee1275 (-loongson) -multiboot -qemu (-qemu
-mips) -uboot -xen -xen-32 -xen-pvh" 8171 KiB

Total: 1 package (1 new), Size of downloads: 8171 KiB

Would you like to merge these packages? [Yes/No]
```

Next, update the system's world set to apply the USE flag changes:
```console
# emerge --ask --verbose --update --deep --newuse @world
```

[handbook-grub-emerge]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#Emerge
