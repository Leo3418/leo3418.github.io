---
title: "Use Git to Manage Kernel Sources on Gentoo"
tags:
  - Gentoo
  - Git
  - GNU/Linux
categories:
  - Tutorial
toc: true
---

Gentoo offers its users a wide array of Linux kernel packages in the
`sys-kernel/*` category, each of which may install the kernel in a different
way.  In particular, the `sys-kernel/*-sources` packages (such as
`sys-kernel/gentoo-sources`, `sys-kernel/vanilla-sources`) install only the
kernel's source code and do nothing else.  This is suitable for users who
prefer to compile and install the kernel on their own but still would like to
let the system package manager update the kernel sources automatically.

However, having a `sys-kernel/*` package is not required to install and manage
the Linux kernel properly on Gentoo: even the kernel sources can be downloaded
and updated of the user's own accord without any package manager intervention.
This article introduces one such way, which is to use Git to manage kernel
sources (optionally with extra kernel patches as well) that are available from
a Git repository.

## What This Method Does and Does Not Help with

Before adopting this method of managing the kernel sources, it is better to
know the benefits of this method and situations where it might fail to meet the
anticipations.

This method is particularly effective than other methods to install the kernel
sources in the following use cases:

- When the Git commit history of the Linux project is being **bisected** to
  locate the exact commit that introduces a regression or another kind of bug.
  Reporters of helpful kernel bug reports that get resolved quickly and more
  effectively often use `git bisect` to pinpoint the problematic commit that
  triggers the bug being reported and include the commit's SHA-1 hash in the
  report.

- When one is trying to make and test small modifications to the kernel
  sources.  The fact that the kernel sources are downloaded with Git means that
  those modifications can be tracked and managed with Git more systematically
  than if no version control system was used.  Git commits can be created for
  the modifications, and each modification's purpose can be documented in the
  commit message.  The modifications can be reverted easily and be shared with
  others quickly by using `git format-patch` to export them as patches.

Despite these benefits, this method usually fails to do the following things:

- Substantially decrease kernel build time.  Under the impression that the
  reusable, intermediate object files (`*.o` files) generated by the compiler
  in a kernel build are kept in the same directory when the Git working tree in
  the directory is updated to a newer kernel release, it might seem that a lot
  of those object files could be reused, thus an updated kernel could take less
  time to build.  The reality is, the size of changes in a bugfix kernel
  release (for example, [changes from 5.16.10 to 5.16.11][diff-5.16.11]) is
  typically large enough to cause the bulk of those object files to be rebuilt,
  and not very much time is saved as a result.

  Nevertheless, in the occasional case where a bugfix kernel release contains a
  very small patch set (e.g. [5.16.9][diff-5.16.9]), using this method to
  manage the kernel sources still helps make the build significantly faster.

[diff-5.16.11]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/diff/?id=v5.16.11&id2=v5.16.10&dt=2
[diff-5.16.9]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/diff/?id=v5.16.9&id2=v5.16.8&dt=2

## Download the Kernel Sources' Git Repository

The instructions in this article will download a stable kernel or a longterm
maintenance kernel from Git servers hosted on kernel.org for example.  The
clone URLs for the repository hosting these kernels are listed in the *Clone*
section at the bottom of [the repository's homepage][kernel-git-stable].  This
is the repository recommended to most users.

Advanced users may use sources of an alternative kernel too, as long as they
understand the purpose of the alternative kernel and how it relates to the
stable kernel.  Normal users are advised **against** using any of them because
they require more expert knowledge to use.
- [Prepatch/RC kernel][kernel-git-torvalds] (corresponds to
  `sys-kernel/git-sources`)
- [Zen kernel][kernel-zen] (corresponds to `sys-kernel/zen-sources`)
- [*linux-next* kernel][kernel-git-next] (corresponds to
  `sys-kernel/linux-next`)

Some kernel repositories have multiple branches for different kernel versions.
For instance, the repository for the stable and longterm kernels have
[branches][kernel-git-stable-refs] like `linux-5.16.y`, `linux-5.15.y`,
`linux-5.10.y`, and so on.  In this case, a specific kernel version may be
picked by selecting the corresponding branch with the `--branch` option for
`git clone`.

It is suggested that the Git repository is cloned under `/usr/src` because the
`sys-kernel/*-sources` packages also install the kernel sources to this
directory.  To allow [`eselect kernel`][eselect-kernel] to work with the kernel
sources being cloned, the name of the directory that will hold the repository's
working tree should start with the `linux-` prefix.  In particular, if the
repository's clone URL ends with `linux` or `linux.git`, then the directory's
name should be explicitly specified to be something different from `linux`.
Otherwise, the repository would be cloned into `/usr/src/linux` in this case,
and on Gentoo, `/usr/src/linux` is supposed to be *a symbolic link* pointing to
the directory containing the running kernel's sources.

To minimize the download size, adding `--depth 1` to the options for `git
clone` is recommended.  This causes only the files necessary for the latest
kernel release in the selected branch of the Git repository to be downloaded.

Accounting for these points, the commands for downloading the kernel sources'
Git repository may be invoked now.  For example, these commands download the
sources for the latest release in the Linux 5.15.y branch, which is a longterm
kernel branch, to `/usr/src/linux-5.15.y`.

```console
# cd /usr/src
# git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch linux-5.15.y linux-5.15.y
```

After the kernel sources have been downloaded, the `/usr/src/linux` symbolic
link should be set to point to the directory containing them.  There are
[several ways of doing this][usr-src-linux-symlink], and perhaps the easiest
way is to use `eselect kernel`:

```console
# eselect kernel list
Available kernel symlink targets:
  [1]   linux-5.15.y
# eselect kernel set linux-5.15.y
# ls -l /usr/src
total 4
lrwxrwxrwx 1 root root  12 Nov 14 18:00 linux -> linux-5.15.y
drwxr-xr-x 1 root root 504 Nov 14 17:59 linux-5.15.y
```

{{< asciicast poster="npt:13" >}}
{{< static-path res download-sources.cast >}}
{{< /asciicast >}}

Now, the kernel sources are ready to be built in the same way as the
`sys-kernel/*-sources` packages.  Patches can also be applied, though it is
strongly recommended that a Git commit is created for each patch applied, as
this will make kernel sources updates easier later.

[kernel-git-stable]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
[kernel-git-torvalds]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
[kernel-zen]: https://github.com/zen-kernel/zen-kernel
[kernel-git-next]: https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
[kernel-git-stable-refs]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/refs/
[eselect-kernel]: https://wiki.gentoo.org/wiki/Kernel/Upgrade#Default:_Setting_the_link_with_eselect
[usr-src-linux-symlink]: https://wiki.gentoo.org/wiki/Kernel/Upgrade#Set_symlink_to_new_kernel_sources

## Update the Downloaded Git Repository

No matter which kernel is chosen, as long as it is still supported, it is
usually subject to frequent updates, i.e. bugfix releases, that all users are
expected to install in time, as sometimes they might contain fixes for critical
security vulnerabilities or serious regressions.  Users of a non-longterm
stable kernel are also expected to update to a new mainline kernel in a few
weeks after the latter's release, which [happens every 9-10
weeks][linux-mainline-cadence], because the older kernel will reach end-of-life
soon after that.  Therefore, the kernel sources in the downloaded Git
repository should be updated on a reasonable frequency.  This section covers
the update instructions for each type of new kernel release.

[linux-mainline-cadence]: https://kernel.org/category/releases.html#when-is-the-next-mainline-kernel-version-going-to-be-released

### New Bugfix Release in the Same Branch

Changes in a new bugfix release can be downloaded and applied easily using just
some Git commands in the Git repository's working tree.  Before any Git
operations, the working directory should be changed to the working tree, which
can be accessed via the `/usr/src/linux` symbolic link assuming that it is set
up correctly:

```console
# cd /usr/src/linux
```

First, use `git fetch` to check for any updates:

```console
# git fetch
remote: Enumerating objects: 7766, done.
remote: Counting objects: 100% (7766/7766), done.
remote: Compressing objects: 100% (1032/1032), done.
remote: Total 6204 (delta 5216), reused 6153 (delta 5165), pack-reused 0
Receiving objects: 100% (6204/6204), 1.10 MiB | 6.38 MiB/s, done.
Resolving deltas: 100% (5216/5216), completed with 1534 local objects.
From https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux
   7cc36c3e1..3b17187f5  linux-5.15.y -> origin/linux-5.15.y
 * [new tag]             v5.15.3      -> v5.15.3
```

The output of `git fetch` in this example shows that Linux 5.15.3 is now
available, and the `origin/linux-5.15.y` remote branch is also updated
accordingly.

To apply the updates, **rebase** the local branch against the remote branch:

```console
# git rebase origin/linux-5.15.y
Successfully rebased and updated refs/heads/linux-5.15.y.
```

A `git rebase` operation instead of `git pull` is strongly recommended because
a rebase can cleanly reapply any kernel patches applied locally before in the
Git commit history.

Finally, to verify that the kernel sources have been updated successfully, 
`git show` may be used to check if the latest commit is for the new bugfix
release.  Note, however, that if there are any locally-applied kernel patches,
then `git show` might output the last commit for those patches instead of the
commit bearing the latest bugfix release's tag.

```console
# git show
commit 3b17187f5ca1f5d0c641fdc90a6a7e38afdf8fae (HEAD -> linux-5.15.y, tag: v5.15.3, origin/linux-5.15.y)
Author: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Date:   Thu Nov 18 19:17:21 2021 +0100

    Linux 5.15.3

...
```

{{< asciicast poster="npt:5.5" >}}
{{< static-path res update-bugfix.cast >}}
{{< /asciicast >}}

Once the kernel sources have been updated, a new kernel is ready to be built
from it.  Note that some steps are unnecessary in an upgrade to a new bugfix
release of the same kernel:

- The `/usr/src/linux` symbolic link does not need to be updated since the
  updated kernel sources are still stored in the same directory as before.

- Usually, if there is already a configuration file for the kernel at
  `/usr/src/linux/.config`, then there is no need to make any modifications to
  it or replace it because it can be reused directly.

### New Mainline Kernel in a Different Branch

When a new mainline kernel is to be installed, it is strongly recommended to
download its sources to a new directory in `/usr/src` instead of keep reusing
the existing copy of the Git repository.  This can be done by executing the
[steps to download the kernel sources' Git repository][download-steps] again
but changing the branch name and directory name for the new kernel.  For
example, the following commands download the `linux-5.16.y` branch and sets
`/usr/src/linux` to point to it:

```console
# cd /usr/src
# git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch linux-5.16.y linux-5.16.y
# eselect kernel set linux-5.16.y
```

Do not forget to [adjust the configuration file for the new
kernel][kernel-upgrade-config] in this case.  Also, any kernel patches applied
locally before might need to be reapplied manually to the new kernel sources.

Downloading the sources for the new kernel to a different directory provides
the following benefits:

- If the new mainline kernel does not work as optimally as the previous one, it
  is possible to temporarily roll back to the previous kernel quickly.

- The odds of accidentally applying a configuration file for a different kernel
  are smaller.

- The names of directories under `/usr/src` that contain the kernel sources
  accurately and precisely indicate the kernel releases they are for.
  Otherwise, for example, if the `linux-5.16.y` branch were downloaded through
  the pre-existing Git repository stored at `/usr/src/linux-5.15.y`, then this
  single directory might contain sources for either of those branches, which
  could be confusing when the `linux-5.16.y` branch was checked out in
  `/usr/src/linux-5.15.y`.  Renaming `/usr/src/linux-5.15.y` to a more general
  name like `/usr/src/linux-stable` could resolve the accuracy issue but would
  compromise the precision of information given by the directory name.

Though not recommended, it is still possible to download and check out the new
mainline kernel's branch in the existing Git repository.  For example, the
following commands check out the `linux-5.16.y` branch and attempt to minimize
the download size for the operation:

```console
# cd /usr/src/linux
# git fetch --depth 1 origin linux-5.16.y:linux-5.16.y
# git checkout linux-5.16.y
```

In this case, do not forget to update kernel configuration and reapply local
kernel patches for the new kernel too.

[download-steps]: #download-the-kernel-sources-git-repository
[kernel-upgrade-config]: https://wiki.gentoo.org/wiki/Kernel/Upgrade#Adjusting_the_.config_file_for_the_new_kernel

## General Kernel Management Tips

The tips in this section are applicable to both users who follow this article
to use Git to manage kernel sources and those who use a `sys-kernel/*-sources`
package.

### Compile and Install a Kernel Without `genkernel`

Using `genkernel` is quite a popular way to build a custom kernel among users
who are new to the process; however, it is [introduced as an alternative
way][handbook-genkernel] to build the kernel in the Gentoo Handbook.  Building
a kernel without `genkernel` is definitely possible and is not very hard.

Before starting to compile and install a kernel, it is strongly recommended to
install a package that provides the `/sbin/installkernel` utility, such as
`sys-kernel/installkernel`.  This is because, if the installation scripts in
the kernel sources cannot locate `/sbin/installkernel`, they will perform
[their own kernel installation logic][linux-install.sh], which is to install
the kernel's executable image to [`/boot/vmlinuz` if it is
compressed][vmlinuz-etymology] or `/boot/vmlinux` if it is not; however, some
bootloaders might not support these installation paths.  For example, GRUB 2
searches the kernel's image using [`/boot/vmlinuz-*` and `/boot/vmlinux-*`
patterns][grub-10_linux]; the extra hyphen causes GRUB 2 to disregard
`/boot/vmlinuz` and `/boot/vmlinux`.  Once `/sbin/installkernel` is installed,
the kernel sources' Makefiles will call it to handle kernel installation
instead, and the `/sbin/installkernel` provided by
`sys-kernel/installkernel` installs the kernel's image to `/boot/vmlinuz-*` or
`/boot/vmlinux-*` (with the hyphen), so bootloaders like GRUB 2 can properly
detect it.

```console
# emerge --ask --noreplace sys-kernel/installkernel
```

Assuming that a kernel configuration file has been created, compiling and
installing the kernel without an initramfs is as simple as just running these
commands as described in the Handbook:

```console
# cd /usr/src/linux
# make -j "$(nproc)"
# make modules_install
# make install
```

In case an initramfs is needed, the Handbook recommends `sys-kernel/dracut` for
building it.  With Dracut, an initramfs can be built and installed without very
much effort:

```console
# cd /usr/src/linux
# dracut --force "" "$(cat include/config/kernel.release)"
```

If it is uncertain whether an initramfs is necessary, it is recommended to just
build and install one to avoid potential boot failure.  Whether or not the
initramfs is redundant can be determined later after more knowledge is gained
and more experiment is done.  In the short term, getting a bootable system is
usually more important than getting a minimal system.
{.notice--info}

After the kernel (and the initramfs, if it is needed) is installed, the
configuration of any bootloader used to boot the system should be updated, so
the new kernel can show up in the bootloader's menu and thus be booted.  The
exact steps to update the configuration vary depending on which bootloader is
used.  For GRUB 2, the following command updates the bootloader configuration:

```console
# grub-mkconfig -o /boot/grub/grub.cfg
```

A script can even be created to eliminate the need to type these commands every
time when a new kernel is to be built:

```bash
#!/usr/bin/env bash

set -e

cd /usr/src/linux

# Compile and install kernel
make -j "$(nproc)"
make modules_install
make install

# Build and install initramfs
KERNEL_RELEASE="$(cat include/config/kernel.release)"
dracut --force "" "${KERNEL_RELEASE}"

# Update bootloader configuration
grub-mkconfig -o /boot/grub/grub.cfg
```

This leaves kernel configuration as the only challenging task in building a
kernel manually.

[handbook-genkernel]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Alternative:_Genkernel
[linux-install.sh]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/arch/x86/boot/install.sh?h=v5.16.11#n37
[vmlinuz-etymology]: https://en.wikipedia.org/wiki/Vmlinux#Etymology
[grub-10_linux]: https://git.savannah.gnu.org/cgit/grub.git/tree/util/grub.d/10_linux.in?h=grub-2.06#n167

### Clean Up Files for an Old Kernel

`app-admin/eclean-kernel` is a tool that automates file clean-up for old
kernels.  Although an old kernel's files can be removed manually, using a tool
like `eclean-kernel` makes the process less error-prone.

To preserve only the newest kernel and let `eclean-kernel` clean up the rest
kernels, the following command may be used:

```console
# eclean-kernel -n 1
```

{{< asciicast poster="npt:3.5" >}}
{{< static-path res eclean-kernel.cast >}}
{{< /asciicast >}}
