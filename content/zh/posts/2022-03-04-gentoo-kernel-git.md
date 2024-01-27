---
title: "在 Gentoo 上使用 Git 管理内核源码"
tags:
  - Gentoo
  - Git
  - GNU/Linux
categories:
  - 教程
toc: true
lastmod: 2022-03-04
---

Gentoo 软件仓库的 `sys-kernel/*` 类别下有若干 Linux 内核软件包可供用户选择；不同的软件包安装内核的方式也不相同。其中，`sys-kernel/*-sources` 软件包（例如 `sys-kernel/gentoo-sources`、`sys-kernel/vanilla-sources`）只安装内核源代码文件，不进行任何其它操作。这样的特性适合想自己手动编译并安装内核、但仍然希望系统软件包管理器自动更新内核源码的用户。

然而，想要在 Gentoo 上妥善安装并管理内核，并不一定非要安装 `sys-kernel/*` 软件包：即使是内核源码，也可以由用户自行手动下载与更新，不需要软件包管理器的干预。本文就将介绍一种这样的方法，即使用 Git 来管理通过 Git 仓库提供的内核源码（并可附带管理外来的内核补丁）。

## 本方法的功能与限制

读者在决定采用本方法之前，建议先了解它有哪些好处、以及它在什么情况下可能达不到预期的效果。

在下列使用场景中，本方法相对于其它安装内核的方法而言更加高效：

- 使用**二分法**（`git bisect`），在 Git 提交历史中查找导致退化或者其它类型的 bug 的确切提交。内核 bug 报告人员如果想帮助开发者快速高效地解决 bug，就会使用 `git bisect` 定位导致该 bug 的具体提交，然后在报告中提及该提交的 SHA-1 散列值。

- 对内核代码进行小规模的修改、并且对这些修改进行测试。因为内核代码是通过 Git 下载的，所以相比于不使用任何版本控制系统而言，对代码作过的修改就能被更系统地追踪与管理。每项修改都可以通过创建 Git 提交的方式保存下来，并且每项修改的目的都能在提交信息中记录。修改可以轻松撤销，还可以轻松以补丁形式导出（`git format-patch`）分享给他人。

虽然有这些优点，但本方法在以下方面有局限性：

- 对内核构建时间的显著缩减。构建内核期间，编译器会在内核源码树中生成诸多目标文件（`*.o` 文件），作为中间产物。在通过 Git 更新源码树后，这些目标文件仍然处在相同的位置，因此从直觉上来说，它们有机会被重新使用，内核构建的时间按理说也应该能缩减。实际上，本方法通常并不能显著节省内核构建时间，因为即使是级别最低的 bug 修复更新（例如 [5.16.10 到 5.16.11 的更新][diff-5.16.11]），更新的规模也足以导致许多目标文件需要重新编译。

  尽管如此，在偶尔出现的规模很小的 bug 修复更新（如 [5.16.9][diff-5.16.9]）时，此方法还是能省下很多时间的。

[diff-5.16.11]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/diff/?id=v5.16.11&id2=v5.16.10&dt=2
[diff-5.16.9]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/diff/?id=v5.16.9&id2=v5.16.8&dt=2

## 下载内核源码 Git 仓库

本文中的步骤将通过从 kernel.org 上的 Git 服务器下载稳定版本或长期维护版本的内核进行示范。下载这些内核源码时需使用的 URL 可在[源码仓库主页][kernel-git-stable]下方的 *Clone* 部分中找到。对于大部分用户，稳定版本和长期维护版本都是推荐的内核版本。

高级用户可选择下载其它的内核，前提是他们能理解他们选择的内核和稳定版本内核的关系。对于一般用户而言，**不建议**选用其它内核，因为使用它们需要掌握更高深的知识。
- [Prepatch/RC 内核][kernel-git-torvalds] （对应 `sys-kernel/git-sources`）
- [Zen 内核][kernel-zen]（对应 `sys-kernel/zen-sources`）
- [*linux-next* 内核][kernel-git-next]（对应 `sys-kernel/linux-next`）

某些内核仓库会在不同分支中提供好几个内核版本。比如，稳定版本和长期维护版本内核的仓库就有 `linux-5.16.y`、`linux-5.15.y` 和 `linux-5.10.y` 等[分支][kernel-git-stable-refs]。下载此类仓库时，可以通过使用 `git clone` 的 `--branch` 选项选择其中一个分支的方式来选取内核版本。

内核 Git 仓库的建议下载目标位置是 `/usr/src`，因为 `sys-kernel/*-sources` 软件包也会将内核源码安装至该位置。为了允许 [`eselect kernel`][eselect-kernel] 识别到通过 Git 下载的内核源码，该仓库在本地的目录的名称应以 `linux-` 作为前缀。这里需要特别注意的是，如果该仓库的下载 URL 以 `linux` 或 `linux.git` 结尾，那么强烈建议将该仓库的目录名称明确指定为与 `linux` 不同的名称。否则，该仓库就会被下载到 `/usr/src/linux`，而在 Gentoo 上，`/usr/src/linux` 一般是个*符号链接*，指向当前正在运行的内核的源码目录。

为了将下载的文件大小最小化，建议在运行 `git clone` 时使用 `--depth 1` 选项。这样一来，只有选定分支中的最新内核版本的文件会被下载。

综合考虑这几点后，就可以运行下载存有内核源码的 Git 仓库的命令了。例如，以下命令会将 Linux 5.15.y 分支（也是一个长期维护的分支）中的最新版本内核的源码下载到 `/usr/src/linux-5.15.y`。

```console
# cd /usr/src
# git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch linux-5.15.y linux-5.15.y
```

完成内核源码的下载后，还应让 `/usr/src/linux` 符号链接指向存有刚下载的源码的目录。实现这一操作的方法[有很多种][usr-src-linux-symlink]，而其中最方便的应该就是使用 `eselect kernel`：

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

到这一步，就可以开始按照与使用 `sys-kernel/*-sources` 时相同的方法来构建内核源码了。任何需要的补丁也可以在此时应用，不过强烈建议为每个应用的补丁创建一个 Git 提交，以方便后续的内核源码更新。

[kernel-git-stable]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
[kernel-git-torvalds]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
[kernel-zen]: https://github.com/zen-kernel/zen-kernel
[kernel-git-next]: https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
[kernel-git-stable-refs]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/refs/
[eselect-kernel]: https://wiki.gentoo.org/wiki/Kernel/Upgrade/zh-cn#.E9.BB.98.E8.AE.A4.EF.BC.9A.E4.BD.BF.E7.94.A8_eselect_.E8.AE.BE.E7.BD.AE.E9.93.BE.E6.8E.A5
[usr-src-linux-symlink]: https://wiki.gentoo.org/wiki/Kernel/Upgrade/zh-cn#.E8.AE.BE.E7.BD.AE.E4.B8.80.E4.B8.AA.E7.AC.A6.E5.8F.B7.E9.93.BE.E6.8E.A5.E5.88.B0.E6.96.B0.E7.9A.84.E5.86.85.E6.A0.B8.E6.BA.90.E4.BB.A3.E7.A0.81

## 更新下载后的 Git 仓库

无论选用什么版本的内核，只要其仍然受支持，其就会经常收到 bug 修复更新。因为此类更新常常会修复关键的安全漏洞和严重的退化，所以用户应当及时更新。同时，使用非长期支持的稳定版本内核的用户，还应该[每隔 9 到 10 个星期][linux-mainline-cadence]，在新的主线内核推出后，尽快迁移到新内核版本，因为旧的内核版本很快就会停止支持。因此，下载后的 Git 仓库中的内核源码应该以合理频率更新。本小节将介绍每种内核更新情形下应进行的操作。

[linux-mainline-cadence]: https://kernel.org/category/releases.html#when-is-the-next-mainline-kernel-version-going-to-be-released

### 同一分支下的 Bug 修复更新

Bug 修复更新的下载和应用非常容易，只需要在 Git 仓库下运行少量 Git 命令即可完成。在进行任何 Git 操作前，应先切换至仓库目录下。如果 `/usr/src/linux` 符号链接配置正确的话，可以直接使用它快速完成目录切换：

```console
# cd /usr/src/linux
```

首先，运行 `git fetch` 检查更新：

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

在此例中，`git fetch` 的输出显示 Linux 5.15.3 已经发布，并且 `origin/linux-5.15.y` 远程分支也相应地更新了。

然后，将本地分支**衍合**到远程分支，以应用更新：

```console
# git rebase origin/linux-5.15.y
Successfully rebased and updated refs/heads/linux-5.15.y.
```

此处强烈推荐使用 `git rebase` 而非 `git pull`，因为使用 `git rebase` 衍合可以将之前在本地应用过的内核补丁干净地重新应用到新版本的代码上。

最后，如果想确认内核源码成功更新的话，可以使用 `git show` 查看本地最新的提交是不是发布该新版本的提交。不过，值得注意的是，如果在本地应用了内核补丁的话，`git show` 可能会显示最后应用的内核补丁的提交，而非带有最新 bug 修复版本的标签的提交。

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

完成内核源码的更新后，就可以构建新的内核了。在构建同一内核分支中的 bug 修复更新时，有些步骤可以跳过：

- `/usr/src/linux` 符号链接无需更新，因为更新后的内核源码仍然存储在原路径。

- 通常，如果内核配置文件 `/usr/src/linux/.config` 仍然存在的话，那么可以直接用它来构建更新后的内核，无需修改或替换。

### 不同分支下的新主线内核

如果要安装新的主线内核，强烈建议将其源码下载到 `/usr/src` 下的一个新目录，而非继续使用之前下载的本地 Git 仓库副本。具体的操作步骤是再做一遍[下载内核源码 Git 仓库的步骤][download-steps]，但是将分支名称和目标目录名称为新的内核版本进行相应的修改。例如，以下命令下载 `linux-5.16.y` 分支，并将其指定为 `/usr/src/linux` 的目标：

```console
# cd /usr/src
# git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch linux-5.16.y linux-5.16.y
# eselect kernel set linux-5.16.y
```

操作完成后，别忘了[为新的主线内核调整内核配置][kernel-upgrade-config]。与此同时，之前在本地应用过的内核补丁可能也需要在新的内核源码上重新应用。

将新内核的源码下载到新的目录有以下优点：

- 如果新的主线内核不好用，可以快速地暂时回退到上个内核版本。

- 误应用给不同版本内核使用的配置的几率更小。

- `/usr/src` 下的内核源码目录的名字可以精准地标注该目录下存储的源码的版本。否则，比如说，如果在存放于 `/usr/src/linux-5.15.y` 的已有 Git 仓库下下载 `linux-5.16.y` 分支，那么同一个文件夹下的源码既有可能是 `linux-5.15.y` 的、也有可能是 `linux-5.16.y` 的，在 `linux-5.16.y` 分支被签出时可能造成困惑。而将 `/usr/src/linux-5.15.y` 重命名为像 `/usr/src/linux-stable` 这样的更笼统的名称，虽然可以规避准确性方面的问题，但也牺牲了目录名称的精确度。

虽然并不推荐此操作，但是在已有的 Git 仓库中下载签出新的主线内核的分支在操作层面仍然是可行的。例如，以下命令签出 `linux-5.16.y` 分支，并将下载的文件大小最小化：

```console
# cd /usr/src/linux
# git fetch --depth 1 origin linux-5.16.y:linux-5.16.y
# git checkout linux-5.16.y
```

同样地，在这种情况下，也需要为新内核更新内核配置并重新应用本地内核补丁。

[download-steps]: #下载内核源码-git-仓库
[kernel-upgrade-config]: https://wiki.gentoo.org/wiki/Kernel/Upgrade/zh-cn#.E5.AF.B9.E6.96.B0.E5.86.85.E6.A0.B8.E8.B0.83.E6.95.B4_.config_.E6.96.87.E4.BB.B6

## 通用内核管理技巧

本小节中介绍的技巧既适用于按照本文方法使用 Git 管理内核源码的用户，也适合使用 `sys-kernel/*-sources` 软件包的用户。

### 不使用 `genkernel` 来编译并安装内核

在刚开始接触内核构建与定制的用户当中，使用 `genkernel` 是一种很流行的方法；但是，这种方法在 Gentoo 手册中毕竟是[作为一种备选方法介绍的][handbook-genkernel]。不使用 `genkernel` 构建内核不仅可行，操作也并不难，并且[在手册中也是被作为一种主要方法介绍的][handbook-manual-build]。

开始编译并安装内核之前，强烈推荐先安装一个提供 `/sbin/installkernel` 工具的软件包，例如 `sys-kernel/installkernel`。这是因为，如果内核源码中的安装脚本未找到 `/sbin/installkernel`，其就会执行[自己的内核安装逻辑][linux-install.sh]，将内核本体安装到 [`/boot/vmlinuz`（如果内核是压缩过的）][vmlinuz-etymology]或者 `/boot/vmlinux`（如果没有压缩）；但是，一些引导程序可能不支持这些内核安装路径。例如，GRUB 2 搜索内核本体时检查的路径是 [`/boot/vmlinuz-*` 和 `/boot/vmlinux-*`][grub-10_linux]；这个多出来的连字符就会导致 GRUB 2 忽略 `/boot/vmlinuz` 和 `/boot/vmlinux` 路径。`/sbin/installkernel` 安装好后，内核源码中的 Makefile 就会调用它来安装内核，而 `sys-kernel/installkernel` 提供的 `/sbin/installkernel` 会将内核本体安装到 `/boot/vmlinuz-*` 或 `/boot/vmlinux-*`（即带有连字符的路径），允许诸如 GRUB 2 的引导程序识别到它。

```console
# emerge --ask --noreplace sys-kernel/installkernel
```

在已经准备好了内核配置文件的前提下，编译并安装内核本身（不带 initramfs）的操作很简单，只要运行以下手册中提及的命令即可：

```console
# cd /usr/src/linux
# make -j "$(nproc)"
# make modules_install
# make install
```

如果需要 initramfs 的话，手册建议使用 `sys-kernel/dracut` 进行构建。只需要运行下列命令，即可使用 dracut 构建并安装 initramfs：

```console
# cd /usr/src/linux
# dracut --force "" "$(cat include/config/kernel.release)"
```

如果不确定是否需要 initramfs 的话，建议直接构建并安装一个，以避免之后系统不能启动。至于到底需不需要 initramfs，可以在日后掌握了更多知识、做了更多实验之后再作更好的判断。在短期之内，装出能启动的系统比装出最精简的系统更重要。
{.notice--info}

当内核（以及 initramfs，如果需要的话）安装好后，启动系统所用的引导程序的配置也应当更新，以将新内核添加到引导程序的菜单中，允许使用新内核启动系统。具体的操作步骤随引导程序而异。如果是 GRUB 2 的话，以下命令可更新引导程序配置：

```console
# grub-mkconfig -o /boot/grub/grub.cfg
```

如果不想每次构建新内核时都手动输入这些命令的话，还可以通过创建一个脚本来避免：

```bash
#!/usr/bin/env bash

set -e

cd /usr/src/linux

# 编译并安装内核
make -j "$(nproc)"
make modules_install
make install

# 构建并安装 initramfs
KERNEL_RELEASE="$(cat include/config/kernel.release)"
dracut --force "" "${KERNEL_RELEASE}"

# 更新引导程序配置
grub-mkconfig -o /boot/grub/grub.cfg
```

这样一来，手动构建内核的过程中的唯一挑战就剩下了配置内核。

[handbook-genkernel]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel/zh-cn#.E5.A4.87.E9.80.89.EF.BC.9A.E4.BD.BF.E7.94.A8genkernel
[handbook-manual-build]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel/zh-cn#.E7.BC.96.E8.AF.91.E5.92.8C.E5.AE.89.E8.A3.85
[linux-install.sh]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/arch/x86/boot/install.sh?h=v5.16.11#n37
[vmlinuz-etymology]: https://zh.wikipedia.org/wiki/Vmlinux#vmlinuz
[grub-10_linux]: https://git.savannah.gnu.org/cgit/grub.git/tree/util/grub.d/10_linux.in?h=grub-2.06#n167

### 清理旧内核的文件

`app-admin/eclean-kernel` 是自动化旧内核文件的清理的工具。虽然手动清理旧内核的文件也是可行的，但是使用 `eclean-kernel` 这样的工具可以避免清理过程中出现错误。

如果只想保留最新的内核、让 `eclean-kernel` 清理剩下的内核的话，可运行以下命令：

```console
# eclean-kernel -n 1
```

{{< asciicast poster="npt:3.5" >}}
{{< static-path res eclean-kernel.cast >}}
{{< /asciicast >}}
