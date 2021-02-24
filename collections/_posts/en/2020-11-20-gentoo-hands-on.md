---
title: "My Gentoo Hands-on Experience"
lang: en
tags:
  - Gentoo
  - GNU/Linux
categories:
  - Blog
toc: true
asciinema-player: true
last_modified_at: 2021-02-23
---
{% include res-path.liquid %}
It has been six weeks since I published the last post on this site.  Myriad new
topics and ideas to write about have accumulated in my drafts for new articles,
but I was too busy to find enough time for converting them into high-quality
articles I have been endeavored to deliver.  Now, as I finally have got some
free time, I want to talk about one of the things I did during the past period:
trying out [Gentoo][gentoo], a *source-based* GNU/Linux distribution famous for
letting its users compile almost every component of the operating system,
including the Linux kernel.

[gentoo]: https://gentoo.org/

## Background

I have been using Fedora for more than two years and satisfied with it, but my
roommate's recent hop to Arch Linux drew my attention to other GNU/Linux
distributions that I had been aware of but had not bothered to research.  He
showed me a part of the installation progress, including creating disk
partitions with command-line programs, and installing the most basic set of
software enough to let the system boot entirely on its own ("*bootstrapping*").
Although I roughly learned the underlying steps of a general GNU/Linux
installation process from Debian and Fedora's installers, the idea of manually
invoking the commands for those tasks hence control the entire system
installation process sounded very cool.

So, I found myself looking at Gentoo's website, because it shares some traits
with Arch Linux: both are rolling-release distributions, do not provide an
official graphical installer, require users to perform the bulk of installation
tasks manually with commands but reward them with plenty of space for choosing
most of the system components at their own discretion.  That said, I favored
Gentoo over Arch Linux for some other reasons.  First, compiling packages on my
own looked challenging but still manageable, given that I had successfully
[compiled a utility for Raspberry Pi and created an RPM package for
it][vcgencmd].  Second, I found some positive reviews and comments on Portage,
Gentoo's package manager, for features like maintaining a plain-text file
`world` that records every package the user explicitly asks it to install and
can be used to duplicate a system with the same set of installed packages.

Because I was tasked with an assignment that required use of a messily-packaged
tool, the desire to keep my daily-driver system tidy made me sacrifice a system
installed on a virtual machine to run it.  With such a great interest in
Gentoo, I chose it for the new virtual machine.

The goal of the system was just to provide a minimal command-line environment
with software I would need.  That tool was solely based on command-line, and I
was fine with working in a terminal, so a graphical environment was not
essential.  In contrast, because Gentoo is a source-based distribution,
installing a desktop environment would mean significantly longer installation
time spent on compiling it.  Plus, this was the first time I carried out an
advanced manual GNU/Linux installation, so I wanted to start with just the
minimum.

[vcgencmd]: /2020/07/27/compile-vcgencmd-on-fedora.html

## Installation

The [Gentoo Handbook][handbook] was my primary installation guide as I
basically followed every step it instructed.  I made the following
customizations that required some extra tasks documented in not the Handbook
itself, but other articles in the Gentoo Wiki:

- I only created a single big partition and applied Btrfs to it, except the EFI
  System Partition (ESP) required for an UEFI installation (my virtual machine
  was configured to use UEFI).  The Handbook suggested creating multiple
  partitions for boot partition, swap partition, and the root file system
  itself, but by using Btrfs subvolumes to isolate boot, home and root, this
  was unnecessary.  For swap partition, I chose to go with [zram][zram], which
  is what Fedora uses since Fedora 33.

  From system recovery perspective, Btrfs is a great file system choice for a
  system based on a rolling distribution, because it supports [file system
  snapshots][btrfs-snapshots], which eases recovery of the system to a previous
  working state when an update breaks something.  Alternatively, LVM snapshots
  can be used for this purpose, but I felt [a Btrfs volume would be easier to
  manage than an LVM volume group][btrfs-vs-lvm].

- Gentoo suggested using the kernel source with its own modifications and
  patches ([`sys-kernel/gentoo-sources`][gentoo-sources]), but I was more
  interested in compiling the vanilla kernel
  ([`sys-kernel/vanilla-sources`][vanilla-sources]). Isn't it cool that when
  you run `uname -r`, all you see is just the kernel version itself, without
  any [extra labels added by your distribution vendor][dist-kernel]?

- I wished to use the latest stable kernel (5.9) instead of the latest LTS
  kernel (5.4) Gentoo would install by default.  To do this, I had to define a
  rule in `/etc/portage/package.accept_keywords` to use latest kernel versions
  that were not marked as stable by Gentoo.  It is advisable to ensure the
  Linux kernel headers package `sys-kernel/linux-headers` is on the latest
  version in companion, too.  Because I was using Btrfs, the file system tools
  `btrfs-progs` should be on the latest version as well in order to [use
  bleeding-edge Btrfs features offered by the latest kernel][btrfs-progs].

  ```
  # /etc/portage/package.accept_keywords

  # Use the latest upstream stable kernel
  sys-kernel/vanilla-sources

  # Use the latest kernel headers in companion
  sys-kernel/linux-headers

  # Use the latest btrfs-progs in companion
  sys-fs/btrfs-progs
  ```

- Although Gentoo's default init system is OpenRC, which might be easier to
  configure for a first-time installer like me, I wanted to use systemd because
  it supports [user services][systemd-user-srv] and I could not find the
  equivalent thing for OpenRC.

  The Handbook fairly mentioned some caveats and steps specific to systemd, but
  it was easy to forget enabling some basic services for vital system
  functionality:

  ```console
  (chroot) # systemctl preset-all
  ```

  I forgot to do this before rebooting into the installed system, and the
  system could not connect to network due to disabled
  `systemd-networkd.service`.

[handbook]: https://wiki.gentoo.org/wiki/Handbook:Main_Page
[zram]: https://wiki.gentoo.org/wiki/Zram
[btrfs-snapshots]: https://fedoramagazine.org/btrfs-snapshots-backup-incremental/
[btrfs-vs-lvm]: /2020/10/08/fedora-raw-image-btrfs.html#reasons-to-use-btrfs
[gentoo-sources]: https://packages.gentoo.org/packages/sys-kernel/gentoo-sources
[vanilla-sources]: https://packages.gentoo.org/packages/sys-kernel/vanilla-sources
[dist-kernel]: https://www.kernel.org/category/releases.html#distribution-kernels
[btrfs-progs]: https://btrfs.wiki.kernel.org/index.php/FAQ#Do_I_have_to_keep_my_btrfs-progs_at_the_same_version_as_my_kernel.3F
[systemd-user-srv]: https://wiki.archlinux.org/index.php/systemd/User

### Tinkering with Kernel Configuration

I found the most time-consuming step in system installation being compiling the
kernel.  After all, there could be some performance penalty in a virtual
machine which caused kernel compilation to be longer than usual.  The most
effective way to reduce kernel build time is to deactivate irrelevant kernel
configuration options, like hardware support for hardware not installed on your
system.

However, the prodigious amount of kernel configuration options and obscurity of
the options' effects can make this difficult.  I was impressed by the countless
models of hardware supported by Linux, but disabling *every* single option for
hardware I did not have would be an ordeal.  I was not sure about whether some
options could be safely disabled either, because their purposes were not fully
understood by me.

So, I ended up deactivating only the options that would add very much compile
time if enabled *and* were for something I was sure I did not need, like the
following for instance:

- GPU support (`i915` for Intel iGPUs, `radeon`, `amdgpu` and `nouveau` for
  NVIDIA GPUs).  Every module listed here would take a while to compile. The
  virtual machine would not directly interface with my computer's physical GPU;
  it would use the virtualization software's graphics card, which was supported
  by other kernel modules.  Note that when compiling a kernel to be directly
  used on a physical computer, you might need to enable some of them, depending
  on what GPU is installed.

- [InfiniBand][infiniband].  I had not even heard of this until I saw it in
  kernel configuration, so I supposed I did not need it.  However, this
  heuristic is probably not applicable to other types of kernel configuration
  options.  For example, there were some options for additional system calls
  activated by default, but I would not deactivate them only because I have not
  heard about them, since some programs might have dependency on them that is
  beyond my ken.

You might be able to disable some other hardware options without degrading
system functionality.  On a desktop PC without wireless connectivity, options
for Wi-Fi, Bluetooth, NFC and other hardware alike can be safely deactivated.
If your computer is so old that it does not support NVMe, NVMe options may be
disabled as well.

~~But, if I am not mistaken, it seems that kernel compilation on recent CPUs,
including even some old Intel dual-core laptop CPUs, can [complete within ten
minutes][kernel-build-time].  I have not tried building a kernel on a system
physically installed on my computer instead of a virtual machine yet, so I
cannot imagine completing the build in such a short time.~~  (**Edit:** Well, I
did make a mistake here.  the kernel build times concerned in the linked
webpage is only for building the kernel itself (i.e. the runtime of `make
vmlinux` or a similar command); the bulk of the kernel building process would
be compiling the kernel modules if a generic kernel configuration is used.  In
fact, I have tried to compile the kernel natively on my laptop with a dual-core
Intel Core i5-7200U, which could build the kernel itself in about 9 minutes but
would spend nearly an hour building the enabled kernel modules.)  If this is
the case, the time spent going through the endless kernel configuration list is
very likely to exceed compile time saved by deactivating some options, so you
can simply use a kernel configuration with best compatibility, such as the one
created by [`genkernel`][genkernel].

[infiniband]: https://en.wikipedia.org/wiki/InfiniBand
[kernel-build-time]: https://openbenchmarking.org/test/pts/build-linux-kernel
[genkernel]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Alternative:_Using_genkernel

## Interacting with `ebuild` Files

An [`ebuild`][ebuild] file defines a Portage package.  It is similar to
`PKGBUILD` in Arch Linux's pacman and RPM SPEC file in Fedora, CentOS, RHEL,
etc.  I have not tried to write a custom `ebuild` for package not in Gentoo's
official package catalog like I did for [Raspberry Pi's `userland` package on
Fedora][userland], but I found it very pleasant to work with existing ones
provided by Gentoo packagers.

Since I was using Btrfs and wanted to use snapshots for quicker system
recovery, I planned to install [Snapper][snapper-gentoo].  It came to my
attention that the latest upstream version of Snapper was 0.8.14, but the
latest `ebuild` in Gentoo's official repository was for 0.8.9.

My experience in maintaining the `userland` package and some other RPM SPECs I
wrote for desktop GUI programs told me that when the upstream released a new
version of the program, I could usually just bump the version number in the RPM
SPEC and rebuild the updated package without problems.  To my surprise, for
Gentoo's `ebuild`, the file itself need not be changed at all in most cases,
because a Portage package's version is defined in its *file name*.  This meant
that all I needed to do in order to build Snapper 0.8.14 was to simply rename
`snapper-0.8.9-r1.ebuild` to `snapper-0.8.14.ebuild`!

{% include asciinema-player.html name="custom-ebuild.cast" poster="npt:31" %}

On Fedora, if I want to install a custom package like a normal package shipped
by Fedora, I will build the package from the RPM SPEC I have written and copy
it to a custom repository designated for my self-built packages.  I must save
the RPM SPEC file somewhere else because it is not included in the generated
package.  Should I want to change the SPEC file, I need to find the saved SPEC
file, modify it, rebuild the package, and copy it to my RPM repository again.

On Gentoo, the whole process is more streamlined: after I am satisfied with my
custom `ebuild` file, I only need to drop the `ebuild`, instead of a prebuilt
package in any form, into my own repository.  If I want to make changes to the
package later, I can modify the `ebuild` at the same place, without reaching
out to a file stored somewhere else.  All files required to build and install
the package can be maintained within a single location, which is my own custom
`ebuild` repository.

Below is a table comparing the experience of maintaining a self-defined package
on Fedora and Gentoo.  Thanks to Portage being designed as a package manager
for a source-based distribution, no extra step is required for building the
package on Gentoo.

| Task | On Fedora | On Gentoo |
| :--- | :-------: | :-------: |
| Define package metadata and how the package is built | Write an RPM SPEC | Write an `ebuild` |
| Build the package | `rpmbuild -bb SPEC` | **Not necessary**<br>(Performed automatically when installing the package with `emerge`) |
| Add the package to custom software repository | Copy the generated RPM to the repository | Copy the `ebuild` to the repository |
| Install the package | `dnf install PKG` | `emerge --ask PKG` |
| Bump package version | Modify package version in RPM SPEC | Rename the `ebuild` file |
| Build updated package | `rpmbuild -bb SPEC` | **Not necessary**<br>(Performed automatically when updating the package with `emerge`) |
| Update the package in custom software repository | Copy the new RPM to the repository | **Already done**<br>(When the `ebuild` file was renamed) |
| Install the updated package | `dnf upgrade PKG` | `emerge --ask --update PKG` |

More information about creating a custom `ebuild` repository can be found in
[this Gentoo Wiki article][custom-ebuild-repo].  The ["simple version bump"
section][ebuild-ver-bump] precisely describes how I installed Snapper 0.8.14
when the latest version distributed by Gentoo was just 0.8.9.  You might also
wish to [assign your own custom repository a higher
priority][ebuild-repo-priority] so Portage will prefer packages in it to those
in the official Gentoo repository.

```
# /etc/portage/repos.conf/local.conf

[local]
location = /var/db/repos/local
priority = -999  # Gentoo's repository has a priority of -1000
```

[ebuild]: https://wiki.gentoo.org/wiki/Ebuild
[userland]: /2020/07/27/compile-vcgencmd-on-fedora.html#use-dnf-to-install-the-program
[snapper-gentoo]: https://packages.gentoo.org/packages/app-backup/snapper
[custom-ebuild-repo]: https://wiki.gentoo.org/wiki/Custom_ebuild_repository
[ebuild-ver-bump]: https://wiki.gentoo.org/wiki/Custom_ebuild_repository#Simple_version_bump_of_an_ebuild_in_the_local_repository
[ebuild-repo-priority]: https://wiki.gentoo.org/wiki/Ebuild_repository#Priorities

## Recommendation

I am probably not able to give complete and responsible advice about what kind
of people should use Gentoo, because I have neither used it as a daily driver
nor installed some popular applications on it except Git, Vim and tmux.  But I
still hope my ephemeral experience with it can give some ideas about the group
of users Gentoo is most suitable for.

Gentoo is a great distribution for the following kinds of users:

- People who need to build a lot of programs that are not packaged by common
  GNU/Linux distributions and/or the bleeding-edge version of packages, and
  want to manage these programs with the system's package manager.  For
  example, the author of <http://rglinuxtech.com/>, which I discovered when
  searching for a solution to [the Raspberry Pi USB issue][raspi-usb], seems to
  enjoy building the `rc` versions of Linux kernel.  If he would like to let
  the system's package mamager take care of the `rc` kernels, then Gentoo would
  be the distribution for him.

  Of course, you may choose to manage self-built programs on your own, but
  chances are it is hard to maintain the list of files that belong to each
  program, which may lead to leftover files after you uninstall a program.  One
  possible solution is [GNU Stow][stow], but you must remember to run it every
  time you modify an installed program.  Portage and custom `ebuild` files can
  streamline the entire maintenance process: write the `ebuild` (which is very
  similar to a shell script that builds and installs the program), run
  `emerge`, and let Portage handle everything else.

- Any users who are familiar with a distribution alike, e.g. Arch Linux, but
  want to fine-tune compiler options to get the best performance, or want to
  get rid of systemd and use OpenRC instead.  systemd has taken over the
  majority of popular GNU/Linux distributions, including Arch Linux, which
  claims that it only officially supports systemd despite being a distribution
  strived to give user eclectic choices on packages.

- People with a good foundation of knowledge on GNU/Linux and want to learn
  more about the internals of the operating system.  Speaking of myself, I
  learned about Linux kernel's capabilities and knowledge about kernel modules
  in the process of configuring the kernel, and perhaps no other mainstream
  GNU/Linux distribution could offer me the incentive to delve into this realm.

These kinds of users should think twice before deciding to use Gentoo:

- Users who are choosing a distribution for a computer with constrained
  hardware resources.  On weak CPUs, including the ARM chip on my Raspberry Pi
  and the virtualized CPU of my virtual machine, kernel compilation can take
  hours, if not forever.  Source code of programs you have built can also
  occupy a few gigabytes that might be precious space if your disk is not
  large.  On my Gentoo installation with only a few user-installed programs and
  no desktop environment, the size of source code archives for all installed
  packages is 1223 MiB, and Linux 5.9.8's source tree takes 1074 MiB.  More
  space would be occupied if I had installed a desktop environment.

  ```console
  $ du -s -B M /var/cache/distfiles /usr/src/linux-5.9.8
  1223M	/var/cache/distfiles
  1074M	/usr/src/linux-5.9.8
  ```

  Gentoo leaves the job of building software packages to users themselves,
  whereas other binary-based distributions compile the programs for the users.
  By choosing a binary-based distribution, you can have some other people
  complete the performance-hungry job for you, which might be preferable if
  your computer is not a powerful one.

- People who are still new to GNU/Linux and/or building software from source.
  You can definitely learn a lot from configuring and using Gentoo, but it
  requires some basic knowledge, skills, and understanding of GNU/Linux.  I
  would suggest starting with another distribution that is more easy to set up
  and maintain, then consider switching to Gentoo only when you are confident
  about installing Arch Linux.

[raspi-usb]: /2020/09/21/raspi4-fedora-usb-complex.html
[stow]: https://www.gnu.org/software/stow/
