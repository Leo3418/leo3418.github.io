---
title: "Enable LUKS2 and Argon2 Support for Packages"
weight: 332
vars:
  patches_base_url: "res/collections/gentoo-config-luks2-grub-systemd"
  memregion_patch: "4500-grub-2.06-runtime-memregion-alloc.patch"
  argon2_patch: "5000-grub-2.06-luks2-argon2-v4.patch"
  aur_patch: "9500-grub-AUR-improved-luks2.patch"
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

## Add Patches for GRUB 2.06

GRUB 2.06 has [limited support for LUKS2][arch-wiki-grub-luks2].  Although code
implementing partial LUKS2 support exists in this version, the bootloader files
installed using the default procedure do not support LUKS2.  Argon2id is not
supported at all in this version either.

Luckily, after applying the following patches to GRUB 2.06, LUKS2 support can
be added to the installed bootloader files automatically, and Argon2id is
supported too.

- [`{{< param vars.memregion_patch >}}`]({{< patchesBaseURL.inline >}}
{{- relURL .Page.Params.vars.patches_base_url -}}
{{< /patchesBaseURL.inline >}}/{{< param vars.memregion_patch >}}): A patch set
  that allows GRUB to allocate new consecutive and large memory chunks, which
  is a prerequisite for Argon2 support in GRUB.  Argon2 enhances the security
  of LUKS by increasing the size of memory required for unlocking computations,
  so GRUB must be able to allocate more memory when needed.  This patch set was
  cherry-picked from [changes staged for the next GRUB
  release][grub-git-memregion-patch].

- [`{{< param vars.argon2_patch >}}`]({{< patchesBaseURL.inline />}}/{{< param
  vars.argon2_patch >}}): The patch set that adds Argon2 support itself to
  GRUB.  It was [submitted to the grub-devel mailing
  list][grub-devel-argon2-v4], but the GRUB project's maintainers have not
  responded with regards to it yet.

- [`{{< param vars.aur_patch >}}`]({{< patchesBaseURL.inline />}}/{{< param
  vars.aur_patch >}}): A patch [included][aur-git-grub-install-luks2-patch] in
  the [`grub-improved-luks2-git`][aur-grub-improved-luks2-git] package on the
  AUR, which is what the Arch Wiki's GRUB article recommends for users seeking
  great LUKS2 support in GRUB.  This patch allows the `grub-install` command to
  automatically install bootloader files with LUKS2 support.

The numbers in front of the patches' file names are there only to control the
order in which they are applied (patches with a smaller ordinal are applied
first).  As long as the order is maintained, these numbers' values are
arbitrary.
{.notice--info}

To apply these patches to Gentoo's GRUB package -- `sys-boot/grub`, add them as
[Portage user patches][gentoo-wiki-etc-portage-patches] to
`/etc/portage/patches/sys-boot/grub-2.06`.  Patches at this location are
applied to all Gentoo revisions of GRUB 2.06 (`-r3`, `-r4`, etc.).  The
following commands may be used to do this:

{{< commands.inline >}}
{{ $content := `# mkdir -p /etc/portage/patches/sys-boot/grub-2.06
# cd /etc/portage/patches/sys-boot/grub-2.06
` }}
{{- $patches := slice
    .Page.Params.vars.memregion_patch
    .Page.Params.vars.argon2_patch
    .Page.Params.vars.aur_patch
}}
{{- range $patches }}
{{- $url := printf "%s/%s" $.Page.Params.vars.patches_base_url . | absURL }}
{{- $content = print $content "# curl -O " $url | println }}
{{- end }}
{{- highlight $content "console" }}
{{< /commands.inline >}}

Readers who are interested in learning more about Portage's user patch feature
are welcome to read [another article on this website][portage-user-patches]
that discusses it in depth.
{.notice--success}

Because the patch set for Argon2 support modifies the file
`grub-core/Makefile.core.def`, according to the [`sys-boot/grub`
ebuild][ebuild-sys-boot:grub], the `GRUB_AUTOGEN` environment variable must be
set.  **Otherwise, any builds of the package with the patch set applied would
fail.**  The environment variable can be set exclusively for all Gentoo
revisions of `sys-boot/grub-2.06` in file
`/etc/portage/env/sys-boot/grub-2.06`:

```console
# mkdir -p /etc/portage/env/sys-boot
# echo 'GRUB_AUTOGEN=1' >> /etc/portage/env/sys-boot/grub-2.06
```

[arch-wiki-grub-luks2]: https://wiki.archlinux.org/title/GRUB#LUKS2
[grub-git-memregion-patch]: https://git.savannah.gnu.org/cgit/grub.git/log/?qt=range&q=8afa5ef45..1df293482
[grub-devel-argon2-v4]: https://lists.gnu.org/archive/html/grub-devel/2021-08/msg00027.html
[aur-grub-improved-luks2-git]: https://aur.archlinux.org/packages/grub-improved-luks2-git
[aur-git-grub-install-luks2-patch]: https://aur.archlinux.org/cgit/aur.git/tree/grub-install_luks2.patch?h=grub-improved-luks2-git&id=27612416769e544d2c08d29932fff69129cb143a
[gentoo-wiki-etc-portage-patches]: https://wiki.gentoo.org/wiki//etc/portage/patches
[portage-user-patches]: {{< relref "2021-03-01-portage-user-patches" >}}
[ebuild-sys-boot:grub]: https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-boot/grub/grub-2.06-r4.ebuild?id=56e6e30263e56771de876c0e053561a54fd19ed1#n13

## New Installation Only: Initialize Portage

If a new Gentoo installation is being performed, then please follow the
instructions in the following Handbook sections under the *Configuring Portage*
chapter:
1. [Installing a Gentoo ebuild repository snapshot from the web](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Installing_a_Gentoo_ebuild_repository_snapshot_from_the_web)
2. [Optional: Updating the Gentoo ebuild repository](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Optional:_Updating_the_Gentoo_ebuild_repository)
3. [Reading news items](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Reading_news_items)
4. [Choosing the right profile](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Choosing_the_right_profile)

## Rebuild Packages

First, build `sys-boot/grub` with the patches applied.  Before starting the
build, please make sure that in the output of `emerge`,
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
