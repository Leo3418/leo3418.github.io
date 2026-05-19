---
title: "Appendix: Patch GRUB 2.12/2.06 to Add LUKS2 and Argon2 Support"
weight: 1001
date: 2026-05-19
vars:
  memregion_patch: "4500-grub-2.06-runtime-memregion-alloc.patch"
  argon2_patch_206: "5000-grub-2.06-luks2-argon2-v4.patch"
  argon2_patch_212: "grub-2.12-luks2-argon2-v4.patch"
  aur_patch: "9500-grub-AUR-improved-luks2.patch"
---

At the time of writing, the latest release of GRUB, which is 2.14, has
built-in LUKS2 and Argon2id support.  Therefore, users who can use the latest
GRUB release do not need to patch its source code to add LUKS2 and Argon2
support, hence they can ignore the information on this page.

However, users of older GRUB releases, including 2.12 and 2.06, need to patch
them.  Neither GRUB 2.12 nor GRUB 2.06 has built-in support for Argon2id; GRUB
2.06 even has more limitations on LUKS2 support.  Therefore, both GRUB 2.12 and
GRUB 2.06 need some patches for LUKS2 and Argon2 support.

## GRUB 2.12

GRUB 2.12 only needs one patch [`{{< param vars.argon2_patch_212 >}}`](
{{< patchesBaseURL.inline >}}
{{- partial "static-path.html" (dict
    "page" (index .Page.Ancestors.Reverse 2) "type" "res") -}}
{{< /patchesBaseURL.inline >}}/{{< param vars.argon2_patch_212 >}}) to get
support for LUKS2 with Argon2.  This patch was originally [submitted to the
grub-devel mailing list][grub-devel-argon2-v4] and targeted GRUB 2.06; I ported
it to GRUB 2.12, and it still works.

To apply this patch to Gentoo's GRUB package -- `sys-boot/grub`, add it as a
[Portage user patch][gentoo-wiki-etc-portage-patches] to
`/etc/portage/patches/sys-boot/grub-2.12`.  Patches at this location are
applied to all Gentoo revisions of GRUB 2.12 (`-r1`, `-r2`, etc.).  The
following commands may be used to do this:

{{< commands.inline "2.12" "argon2_patch_212" >}}
{{- $grubVer := .Get 0 }}
{{- $patches := split (.Get 1) " " }}
{{- $patches = apply $patches "printf" "vars.%s" "." }}
{{- $patches = apply $patches "page.Param" "." }}

{{ $content := print
    "# mkdir -p /etc/portage/patches/sys-boot/grub-" $grubVer | println }}
{{ $content := print $content
    "# cd /etc/portage/patches/sys-boot/grub-" $grubVer | println }}
{{- $baseURL := partial "static-path.html" (dict
    "page" (index .Page.Ancestors.Reverse 2) "type" "res" "abs" true) }}
{{- range $patches }}
{{- $content = print $content "# curl -O " $baseURL "/" . | println }}
{{- end }}
{{- highlight $content "console" }}
{{< /commands.inline >}}

Readers who are interested in learning more about Portage's user patch feature
are welcome to read [another article on this website][portage-user-patches]
that discusses it in depth.
{.notice--success}

Because this patch modifies the file `grub-core/Makefile.core.def`, according
to the [`sys-boot/grub` ebuild][ebuild-sys-boot:grub], the `GRUB_AUTOGEN` and
`GRUB_AUTORECONF` environment variables must be set.  **Otherwise, any builds
of the package with the patch applied would fail.**  The environment variable
can be set exclusively for all Gentoo revisions of `sys-boot/grub-2.12` in file
`/etc/portage/env/sys-boot/grub-2.12`:

```console
# mkdir -p /etc/portage/env/sys-boot
# echo -e 'GRUB_AUTOGEN=1\nGRUB_AUTORECONF=1' >> /etc/portage/env/sys-boot/grub-2.12
```

[grub-devel-argon2-v4]: https://lists.gnu.org/archive/html/grub-devel/2021-08/msg00027.html
[grub-2.12-argon2]: https://lists.gnu.org/archive/html/grub-devel/2022-11/msg00094.html
[gentoo-wiki-etc-portage-patches]: https://wiki.gentoo.org/wiki//etc/portage/patches
[portage-user-patches]: {{< relref "2021-03-01-portage-user-patches" >}}
[ebuild-sys-boot:grub]: https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-boot/grub/grub-2.12.ebuild?id=76418694270557b6feb75381912a39569ee28d45#n6

## GRUB 2.06

GRUB 2.06's support for LUKS2 is [more limited][arch-wiki-grub-luks2].
Although code implementing partial LUKS2 support exists in this version, the
bootloader files installed using the default procedure do not support LUKS2.

Luckily, after applying the following patches to GRUB 2.06, LUKS2 support can
be added to the installed bootloader files automatically, and Argon2id is
supported too.

- [`{{< param vars.memregion_patch >}}`]({{< patchesBaseURL.inline />}}/{{<
  param vars.memregion_patch >}}): A patch set that allows GRUB to allocate new
  consecutive and large memory chunks, which is a prerequisite for Argon2
  support in GRUB.  Argon2 enhances the security of LUKS by increasing the size
  of memory required for unlocking computations, so GRUB must be able to
  allocate more memory when needed.  This patch set was cherry-picked from
  [GRUB 2.12][grub-git-memregion-patch].

- [`{{< param vars.argon2_patch_206 >}}`]({{< patchesBaseURL.inline />}}/{{<
  param vars.argon2_patch_206 >}}): The patch set that adds Argon2 support
  itself to GRUB.  This patch is equivalent to the only patch needed for GRUB
  2.12 mentioned above.

- [`{{< param vars.aur_patch >}}`]({{< patchesBaseURL.inline />}}/{{< param
  vars.aur_patch >}}): A patch [included][aur-git-grub-install-luks2-patch] in
  the [`grub-improved-luks2-git`][aur-grub-improved-luks2-git] package on the
  AUR, which is what the Arch Wiki's GRUB article recommends for users seeking
  great LUKS2 support in GRUB.  This patch allows GRUB 2.06's `grub-install`
  command to automatically install bootloader files with LUKS2 support.

The numbers in front of the patches' file names are there only to control the
order in which they are applied (patches with a smaller ordinal are applied
first).  As long as the order is maintained, these numbers' values are
arbitrary.
{.notice--info}

Similar to the case of GRUB 2.12, add these patches as Portage user patches to
`/etc/portage/patches/sys-boot/grub-2.06`:

{{< commands.inline "2.06" "memregion_patch argon2_patch_206 aur_patch" />}}

Then, add the required environment variables to
`/etc/portage/env/sys-boot/grub-2.06`:

```console
# mkdir -p /etc/portage/env/sys-boot
# echo -e 'GRUB_AUTOGEN=1\nGRUB_AUTORECONF=1' >> /etc/portage/env/sys-boot/grub-2.06
```

[arch-wiki-grub-luks2]: https://wiki.archlinux.org/title/GRUB#LUKS2
[grub-git-memregion-patch]: https://git.savannah.gnu.org/cgit/grub.git/log/?qt=range&q=8afa5ef45..1df293482
[aur-grub-improved-luks2-git]: https://aur.archlinux.org/packages/grub-improved-luks2-git
[aur-git-grub-install-luks2-patch]: https://aur.archlinux.org/cgit/aur.git/tree/grub-install_luks2.patch?h=grub-improved-luks2-git&id=27612416769e544d2c08d29932fff69129cb143a
