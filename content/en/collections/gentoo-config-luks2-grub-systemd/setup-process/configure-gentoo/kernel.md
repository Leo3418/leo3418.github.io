---
title: "Configure the Linux Kernel"
weight: 335
---

Because LUKS relies on dm-crypt, a feature provided by the Linux kernel, the
encrypted system's kernel must be configured with dm-crypt support enabled.  In
addition, to allow the LUKS partition to be unlocked during boot, an initramfs
with the `cryptsetup` program needs to be created.

## Enable Required Kernel Configuration Options

If a [distribution kernel][dist-kernel] package is being used with the default
kernel configuration it ships, then this step can be skipped because the
required options are all enabled in the default configuration.
{.notice--success}

Gentoo Wiki gives [a list of kernel configurations][kernel-config] that need to
be enabled for dm-crypt support.  Note that if the `--hash sha512` option is
used in the commands run previously, then the cryptographic API functions for
SHA512 need to be enabled.

```
[*] Cryptographic API --->
    <*> SHA384 and SHA512 digest algorithms
```

Because the root file system is encrypted as part of the full disk encryption
configuration, the options that enable initramfs support are required.
However, the options for enabling tcrypt support are optional.

Enabling these options as built-ins (`<*>`, `y`) instead of modules (`<M>`,
`m`) is recommended because they will always be in use when the system on the
LUKS partition is running.

Next, build and install the kernel with the updated configuration to let it
take effect.

[kernel-config]: https://wiki.gentoo.org/wiki/Dm-crypt#Kernel_Configuration
[dist-kernel]: https://wiki.gentoo.org/wiki/Project:Distribution_Kernel

## Install Tools for initramfs

Because dracut will be used to build the initramfs, please first ensure it is
installed:

```console
# emerge --ask --noreplace sys-kernel/dracut
```

Then, before building the initramfs, any other user-space programs required to
mount the file system on the LUKS partition also need to be installed, so they
can be embedded in the initramfs.  Depending on the file system used on the
LUKS partition, the package that should be installed varies.  Gentoo Handbook
contains [a list of packages for common file systems][handbook-fs-tools], which
can be referenced to determine the correct package.

Examples:
- Btrfs:
  ```console
  # emerge --ask --noreplace sys-fs/btrfs-progs
  ```
- LVM:
  ```console
  # emerge --ask --noreplace sys-fs/lvm2
  ```

[handbook-fs-tools]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#Filesystem_tools

## Update initramfs

Now that everything pertaining to initramfs for the LUKS configuration is
ready, make a new initramfs with the `cryptsetup` program and the key file for
automatic unlock from systemd:

```console
# dracut --force "" "$(cat /usr/src/linux/include/config/kernel.release)"
```
