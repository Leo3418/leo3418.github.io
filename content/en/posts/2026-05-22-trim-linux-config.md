---
title: "Trim Linux Kernel Configuration"
tags:
  - GNU/Linux
  - Gentoo
categories:
  - Tutorial
toc: true
---

Many Linux users who prefer to compile their own kernels definitely want to
reduce kernel compilation time and minimize the on-disk footprint of compiled
kernels and modules.  Achieving these goals is commonly done by trimming the
kernel configuration, which entails disabling kernel configuration options that
the user does not need.  Users can disable options for software features they
do not use and hardware that they do not own; for example, those who do not
need to use WireGuard can disable it in their kernel configuration, and those
who do not own an AMD graphics card or an AMD CPU with integrated graphics can
disable the `amdgpu` driver at kernel build time.

Gentoo Linux users are a significant group of users among those who compile
their own Linux kernels because the distribution makes it easy and also a norm
on itself for users to compile software packages on their own computers.
Therefore, trimming the kernel configuration is a frequently-mentioned topic
among Gentoo users.  This tutorial is intended for those Gentoo users who want
to trim their kernels.

With that said, the author does not foresee any reason this tutorial cannot be
applied to another GNU/Linux distribution.  However, the author has not tested
this tutorial's instructions on another distribution yet.  In addition, users
of other distributions probably do not need this tutorial at all, particularly
if they have never compiled a software package themselves.

## Effect

Generally, trimming the kernel configuration can reduce both kernel compilation
time and the modules' on-disk footprint by more than half.  The exact magnitude
may vary depending on factors like how aggressive the trimming is.  With Linux
6.18.2, the author successfully reduced the kernel compilation time from about
13 minutes to less than 6 minutes, as well as the size of modules from 832 MiB
to 164 MiB:

```console
# qlop --time --verbose sys-kernel/vanilla-kernel
2025-12-27T18:02:49 >>> sys-kernel/vanilla-kernel-6.18.2: 13′09″
2025-12-27T22:55:37 >>> sys-kernel/vanilla-kernel-6.18.2: 5′44″
```

```console
$ du --human-readable --summarize /lib/modules/*
832M	/lib/modules/6.18.2-gentoo-dist
164M	/lib/modules/6.18.2-localmod
```

## Requirements

Unless otherwise noted, the steps listed below should be performed on **the
computer on which the trimmed kernel will run**.

## Install Tools Required for Kernel Compilation

Gentoo users can skip this step because the tools required to compile the
kernel are already installed on every Gentoo system by default.

On most non-Gentoo distributions, the tools required to compile the kernel need
to be installed first.  Users can consult these resources for more information
about this:
- [Linux kernel
  documentation](https://docs.kernel.org/admin-guide/quickly-build-trimmed-linux.html#install-build-requirements)
- The distribution's documentation on this matter, if any; for example:
  - [Arch Linux](https://wiki.archlinux.org/title/Kernel#Compilation)
  - [Debian](https://kernel-team.pages.debian.net/kernel-handbook/)
  - [Fedora](https://docs.fedoraproject.org/en-US/quick-docs/kernel-build-custom/)

## Install and Boot into a Generic Kernel

A **generic kernel** is one configured to be compatible with the widest range
of computers and user workflows, and it supports as many devices and
commonly-used software features as possible.

On virtually every GNU/Linux distribution, the distribution's default kernel is
such a generic kernel, so users can just boot into it.

Gentoo users can install and use `sys-kernel/gentoo-kernel-bin`, a pre-compiled
distribution kernel that works as a generic kernel:
```console
# emerge --ask --noreplace --oneshot sys-kernel/gentoo-kernel-bin
```

Users who have Secure Boot enabled should let their Secure Boot configuration
accept Gentoo Distribution Kernel's signing key to ensure that the kernel can
boot.  The signing key is available at
`/usr/src/linux-[release]-gentoo-dist/certs/signing_key.x509`.  Those using
`sys-boot/shim` for Secure Boot can run the following command to achieve this,
with `[version]` being replaced by the actual version of the generic kernel:
```console
# mokutil --import /usr/src/linux-[version]-gentoo-dist/certs/signing_key.x509
```

Once installed, boot into the generic kernel to perform subsequent steps.

## Plug in and Enable As Many Devices As Possible

The purpose of connecting as many devices as possible to the computer is to
load as many useful kernel modules as possible.  When a device is connected,
normally the kernel modules needed for its functionality will be automatically
loaded.  A subsequent step in this tutorial will generate a trimmed kernel
configuration that enables loaded modules and disables modules that are not
loaded, so having a module loaded now ensures its inclusion in that generated
configuration.  As a result, the user will get a configuration that both is
compatible with all their devices to the maximum extent and has as many
unnecessary options as possible disabled.

The author would plug in and enable these types of devices for this step:

- USB devices: peripherals, external drives, adapters...
- On-board wireless interfaces, like Wi-Fi and Bluetooth, as well as a Wi-Fi
  network and any Bluetooth devices
- Any external monitors
- An SD card if the computer has a built-in SD card reader
- On a laptop with a webcam or microphone privacy switch: turn off each switch
  so the corresponding input device is available

Generally, a device can be disconnected as soon as it has been connected to,
recognized by, and initialized by the system; there is no need to keep the
device connected for an extended period.  This is because, once a kernel module
has been loaded for a device, it typically will not be automatically unloaded
when the device is disconnected.

## Download and Extract Kernel Source

The goal of this step is to have a copy of the Linux kernel source tree where
the user can run the `make` command to invoke the kernel build system ready
locally.  The kernel version in this source tree should match the kernel
version that the user would like to use.

There are several sources from which users can download the kernel source:

- A tarball from [kernel.org](https://kernel.org/).

- A local clone of a Git repository that contains the kernel source.  In this
  case, it is strongly recommended that users create a *shallow* clone by
  specifying the `--depth 1` option in the `git clone` command to avoid
  downloading the entire Git commit history of the Linux kernel, which is very
  big.

  For example, the following command clones Linux 6.18.2's source from [the
  Linux kernel's official Git repository][git.kernel.org-stable]:
  ```console
  $ git clone --branch v6.18.2 --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
  ```

- Gentoo users can install kernel source using Portage by installing a
  `sys-kernel/*-sources` package.  Each package installs the source under the
  `/usr/src` directory.
  - Gentoo users who have [a distribution kernel
    package][gentoo-wiki-dist-kernel] installed (`sys-kernel/*-kernel` and
    `sys-kernel/gentoo-kernel-bin`) should **not** use the kernel source
    installed by that package under `/usr/src`!  They must use a different copy
    of the kernel source obtained through another method.  This is because that
    kernel source is incomplete and does not support running the kernel build
    system.

[git.kernel.org-stable]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/
[gentoo-wiki-dist-kernel]: https://wiki.gentoo.org/wiki/Distribution_Kernel#Current_packages

Once the kernel source is downloaded and extracted, enter the directory that
contains it to perform the subsequent steps.

## Generate a Trimmed Kernel Configuration

This step will produce a trimmed kernel configuration using the kernel build
system's `localmodconfig` Make target, which disables kernel configuration
options for inactive modules that came with the running kernel but are not
currently loaded.

1. Get the running kernel's configuration.  This configuration will be used as
   the starting point (the "seed") of the trimmed configuration.

   Some distributions' kernels make their own configuration available at path
   `/proc/config.gz`.  In this case, use the following command to create the
   seed configuration:
   ```console
   $ zcat /proc/config.gz > config-seed
   ```

   If `/proc/config.gz` does not exist, some other distributions install kernel
   configurations at `/boot/config-[release]`, so check this path instead:
   ```console
   $ cp "/boot/config-$(uname -r)" config-seed
   ```

2. Initialize file `.config` with the seed configuration.  `.config` is the
   kernel configuration filename recognized by the kernel build system.
   ```console
   $ cp config-seed .config
   ```

3. Generate a trimmed configuration.
   ```console
   $ yes '' | make localmodconfig
   ```
   `yes ''` lets `make localmodconfig` use the default value for all options
   that `.config` does not have a setting for.  `make localmodconfig` disables
   modules that are enabled in `.config` but are not currently loaded.

4. Create a **configuration snippet** that lists the configuration options for
   all modules just disabled by `make localmodconfig`.  The configuration
   snippet will make subsequent steps easier.  With the following command, the
   snippet will be called `localmod-all.config`.
   ```console
   $ scripts/diffconfig -m config-seed .config > localmod-all.config
   ```

   The snippet should look like this:
   ```
   # CONFIG_6LOWPAN is not set
   # CONFIG_8139CP is not set
   # CONFIG_8139TOO is not set
   ...
   ```

## Re-enable Vital Configuration Options

The previous step has disabled inactive modules in the kernel configuration.
However, **just because a module was inactive does not mean it would never be
useful.**  For example, the `exfat` module for the exFAT filesystem might be
inactive because the user had not mounted an exFAT volume during the current
boot when they ran `make localmodconfig`, but the user might later need to plug
in a USB drive formatted with exFAT; in this case, if the trimmed kernel would
not have the `exfat` module, the user would not be able to mount the drive.
Therefore, modules that might be needed later should be re-enabled, or else the
system's functionality could be reduced.

To make subsequent steps easier, it is recommended that the user make a copy of
the configuration snippet created previously, then the user modify the copy to
re-enable vital configuration options.  The copy can be created with this
command:
```console
$ cp localmod-all.config localmod-select.config
```

The copy is called `localmod-select.config`.  Open it, go through the disabled
options, then spot and delete `# [option name] is not set` lines for options
that should be re-enabled.

The options to re-enable may vary depending on the user's needs, but for all
users, the author recommends re-enabling at least options matching these
regular expressions:

- Filesystems: `CONFIG_.*_FS`
- Cryptographic functions, which are vital for information security:
  `CONFIG_CRYPTO_.*`
- Human interface device (HID) support, which peripheral devices often rely on:
  `CONFIG_HID_.*`
- USB support proper:
  - `CONFIG_USB_.*`
  - `CONFIG_SND_USB_.*`
  - `CONFIG_TYPEC_.*_ALTMODE` for devices with USB-C ports supporting Alternate
    Modes
  - `CONFIG_USB4_NET` for devices with USB4 or Thunderbolt ports
- SD/MMC cards:
  - `CONFIG_MMC`
  - `CONFIG_MMC_BLOCK`
- Bluetooth: `CONFIG_BT_HIDP`
- Webcams:
  - `CONFIG_I2C_MUX`
  - `CONFIG_MEDIA_SUPPORT`
- Networking:
  - `CONFIG_NET_SCH_.*`
  - `CONFIG_TCP_CONG_.*`
  - `CONFIG_TUN`
- Firewalls:
  - `CONFIG_IP_SET`
  - `CONFIG_IP_NF_TARGET_.*`
  - `CONFIG_NETFILTER_.*`
  - `CONFIG_NF_.*`
  - `CONFIG_NFT_.*`
  - `CONFIG_IP6_NF_TARGET_.*` for IPv6-enabled networks

To search for disabled options, run the following command with `[pattern]`
replaced by the options' regular expression.  The `-n` option to `grep` enables
line numbers in the output, which makes it easier to locate the options' lines
in the snippet.
```console
$ grep -n '[pattern] is not set' localmod-select.config
```

For example:
```console
$ grep -n 'CONFIG_.*_FS is not set' localmod-select.config
```

When it is uncertain whether an option should be re-enabled, these resources
may be utilized to make a decision:

- Search the option's name online on these websites to learn about what the
  option does:
  - [kernelconfig.io](https://www.kernelconfig.io/index.html); however, the
    author has noticed that it occasionally fails to show results for a
    configuration option that does exist.
  - [Linux Kernel Driver Database](https://cateee.net/lkddb/web-lkddb/); very
    comprehensive, but less easy to search on
  - A search engine

- Check if any software package requires the option to be enabled.  If a
  package requires it, it is recommended to enable it, especially when the user
  uses the package.  This can be easily checked using the ebuilds in the Gentoo
  ebuild repository:

  1. On a Gentoo system, enter the directory where the Gentoo ebuild repository
     locates:
     ```console
     $ cd /var/db/repos/gentoo
     ```

     Or, on any distribution, clone the repository with Git:
     ```console
     $ git clone --depth 1 https://anongit.gentoo.org/git/repo/gentoo.git
     $ cd gentoo
     ```

  2. Use the following command to search for any package that requires the
     option.  If the command prints anything, then there exists packages that
     require the option.  Otherwise, no package is known to require the option.
     ```console
     $ grep -nrsw [option name without 'CONFIG_']
     ```

     For example, to search for any package that requires option
     `CONFIG_BT_HIDP`:
     ```console
     $ grep -nrsw BT_HIDP
     ```

## Compile and Install a Trimmed Kernel

Once the user has re-enabled vital configuration options by deleting their
lines in `localmod-select.config`, a trimmed kernel is ready to be compiled.

1. Run this command to create a new trimmed configuration, which will have
   inactive modules disabled but modules selected by the user re-enabled:
   ```console
   $ scripts/kconfig/merge_config.sh -m -r config-seed localmod-select.config
   ```

2. To avoid having the kernel build system overwrite the running kernel's files
   with the trimmed kernel's files when it installs the trimmed kernel, set the
   `CONFIG_LOCALVERSION` option to a different value for the trimmed kernel:
   ```console
   $ echo 'CONFIG_LOCALVERSION="-localmod"' >> .config
   ```

   This will ensure that the trimmed kernel's files will have different names
   from those of the running kernel's files.  If this is not done, and the
   trimmed kernel cannot boot for any reason, this may result in a broken
   system because the working kernel's files have been overwritten with the
   trimmed kernel's files.  **Users should ensure that at least one working
   kernel is installed at any time.**

3. Compile the kernel and modules:
   ```console
   $ make -j "$(nproc)"
   ```

   If the compilation ends with an error, run the above command again to get
   shorter output, which should make the detailed error message easier to find.
   The error message may look like the following one and complain about
   `certs/signing_key.x509`:

   ```
   make[3]: *** No rule to make target '/var/tmp/portage/sys-kernel/gentoo-kernel-6.18.2/temp/kernel_key.pem', needed by 'certs/signing_key.x509'.  Stop.
   make[2]: *** [scripts/Makefile.build:556: certs] Error 2
   make[2]: *** Waiting for unfinished jobs....
   make[1]: *** [Makefile:2010: .] Error 2
   make: *** [Makefile:248: __sub-make] Error 2
   ```

   This error is because the kernel configuration enables module signing, and
   the module signing key specified in the configuration is unavailable.  To
   solve it, reset the module signing key path to the default to let the kernel
   build system generate a new key, then try again:
   ```console
   $ echo 'CONFIG_MODULE_SIG_KEY="certs/signing_key.pem"' >> .config
   $ make -j "$(nproc)"
   ```

4. Install the modules:
   ```console
   # make INSTALL_MOD_STRIP="--strip-unneeded" modules_install
   ```

   The `INSTALL_MOD_STRIP="--strip-unneeded"` option enables stripping, which
   saves disk space.

5. Install the kernel:
   ```console
   # make install
   ```

6. If Secure Boot is enabled, sign the trimmed kernel just installed to ensure
   that the firmware will allow it to boot.  The trimmed kernel can be
   identified by string `-localmod` at the end of its release string.

7. Reboot into the trimmed kernel to verify that it boots.  The trimmed kernel
   can be identified by string `-localmod` at the end of its release string.
   If the kernel does not boot, reboot into the previous working kernel to
   rebuild the trimmed kernel if necessary.

## Test the Trimmed Kernel

Once the trimmed kernel successfully boots, the user should verify the system's
functionality by testing their common workflows, such as:

- Run and test programs that rely on certain kernel configuration options, such
  as:
  - Networking tools: Firewalls, VPN programs...
  - Virtualization tools: Container engines, emulators, virtual machines...

- Connect and test devices like:
  - Speakers, any microphones, and any headsets
  - USB devices
  - Wi-Fi, Bluetooth, and other wireless devices
  - External monitors, especially on a laptop with a USB-C port that supports
    video output
  - SD cards
  - Laptop webcam

If any issue occurs, `dmesg` output could be useful for troubleshooting.

If something no longer works because a kernel configuration option was
disabled, re-enable it by deleting its line in file `localmod-select.config`,
then recompile a new trimmed kernel by following the above section's
instructions from the beginning.

If all needed kernel functions are working, then kernel configuration trimming
is successful!

## Maintenance

After a successful kernel configuration trimming, a few additional wrap-up
tasks may be performed to make reusing the trimmed configuration easier in
future kernel updates.

### Create a Configuration Snippet for Re-enabled Modules

After users have finalized their `localmod-select.config` file, they can create
another configuration snippet that reflects the modules they have re-enabled:
```console
$ scripts/diffconfig -m localmod-select.config localmod-all.config | sed 's/^# \(CONFIG_.*\) is not set$/\1=m/' > re-enabled-modules.config
```

With this snippet called `re-enabled-modules.config`, in the future, generating
a new trimmed configuration for a newer kernel version will be as easy as:

1. Follow the ["Generate a Trimmed Kernel Configuration"]({{% relref
   "#generate-a-trimmed-kernel-configuration" %}}) section again to generate a
   new trimmed configuration for the new kernel version using `make
   localmodconfig`, then create a new `localmod-all.config` file.

2. Run this command:
   ```console
   $ scripts/kconfig/merge_config.sh -m -r config-seed localmod-all.config re-enabled-modules.config
   ```

   There is no need to go through modules disabled in `localmod-all.config`
   and re-enable the vital ones again, unless the user would like to enable
   some newly-available modules in the new kernel version.

### Generate a Configuration Snippet for Webcam

Users can generate a standalone configuration snippet just for the options
needed for their webcam device, so when they generate a new trimmed kernel
configuration in the future, they can use this snippet and stop worrying about
forgetting to turn off the privacy switch before trimming.

1. Disable the webcam using the privacy switch, so the webcam is unavailable.

2. Reboot into a generic kernel.

3. Generate a kernel configuration with the webcam disabled:
   ```console
   $ cp config-seed .config
   $ yes '' | make localmodconfig
   $ cp .config config-webcam-off
   ```

4. Toggle the privacy switch to enable the webcam.

5. Generate another kernel configuration with the webcam enabled:
   ```console
   $ cp config-seed .config
   $ yes '' | make localmodconfig
   $ cp .config config-webcam-on
   ```

6. Generate the snippet:
   ```console
   $ scripts/diffconfig -m config-webcam-off config-webcam-on > webcam.config
   ```

In the future, generating a new trimmed configuration with options needed for
the webcam enabled can be done with the command below (assuming the user has
created `re-enabled-modules.config` for re-enabled modules by following the
previous instructions).  The webcam snippet should be applied before the one
re-enabling modules because the webcam snippet might disable some modules that
should be re-enabled.
```console
$ scripts/kconfig/merge_config.sh -m -r config-seed localmod-all.config webcam.config re-enabled-modules.config
```

### Trim Gentoo Distribution Kernel

Gentoo users who use `sys-kernel/gentoo-kernel` or `sys-kernel/vanilla-kernel`
can let these distribution kernel packages build trimmed kernels by applying
the configuration snippets they have created.  To do so, copy the snippets to
the `/etc/kernel/config.d` directory:
```console
# cp localmod-all.config /etc/kernel/config.d/10-localmod-all.config
# cp re-enabled-modules.config /etc/kernel/config.d/20-re-enabled-modules.config
```

In addition, if the user has generated a snippet for webcam:
```console
# cp webcam.config /etc/kernel/config.d/15-webcam.config
```

Numerical prefixes are added to these snippets' filenames in
`/etc/kernel/config.d` to control the order in which they are applied to a
distribution kernel's default configuration.  Distribution kernel packages
apply them in the lexical order of
filenames[^gentoo-wiki-dist-kernel-config.d].

[^gentoo-wiki-dist-kernel-config.d]: <https://wiki.gentoo.org/wiki/Distribution_Kernel#Using_.2Fetc.2Fkernel.2Fconfig.d>
