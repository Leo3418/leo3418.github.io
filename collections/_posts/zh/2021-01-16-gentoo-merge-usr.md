---
title: "合并 Gentoo 上的 `/usr` 目录"
lang: zh
tags:
  - Gentoo
categories:
  - 教程
toc: true
last_modified_at: 2021-03-05
---

*`/usr` 合并*是指在诸如 GNU/Linux 等的遵循[文件系统层次结构标准（FHS）][fhs]的系统上，将 `/bin`、`/lib`、`/lib64` 和 `/sbin` 中的内容分别迁移至 `/usr/bin`、`/usr/lib`、`/usr/lib64` 和 `/usr/sbin` 中，然后把 `/bin`、`/lib`、`/lib64` 和 `/sbin` 改成指向 `/usr` 中同名目录的符号链接（symbolic link）。如果想了解有关 `/usr` 合并的更多信息，可以参阅 [freedesktop.org][freedesktop] 和 [Fedora Wiki][fedora] 中的相关页面（皆为英文页面）。

现在绝大多数主流 GNU/Linux 发行版中的 `/usr` 合并大趋势应该是由 Fedora 在 2012 年牵头开始的；之后，包括 Debian 和 Arch Linux 在内的许多常见的发行版也都相应地完成了 `/usr` 合并。说起来这和 systemd 在 GNU/Linux 社区中的侵蚀也有点类似，都是由 Red Hat 想按照自己的方式定型当代 GNU/Linux 发行版的野心和 [Lennart Poettering 大肆为其背书][0pointer-de]开始、在 Fedora 上首秀，然后逐渐被其它发行版采纳。

而 Gentoo 却不是潮流的追随者，不仅是为数不多的默认不使用 systemd 的发行版，更没有跟随合并 `/usr` 的大势。目前，按照默认方式安装 Gentoo 后，`/bin`、`/lib`、`/lib64` 和 `/sbin` 仍然是独立的目录，而不是像其它发行版改成了符号链接。虽说如此，Gentoo 应该还是有实现 `/usr` 合并的计划的，因为他们在 Portage 中定义了一个 [`split-usr` USE 标志][split-usr]。现在这个 USE 标志是强制启用的，因为目前 `/bin`、`/lib`、`/lib64` 和 `/sbin` 这些目录还未合并，也就是分离（split）的状态；如果日后有一天 Gentoo 官方可以完全支持 `/usr` 合并了，那届时就可以让 `split-usr` 变成一个可选的 USE 标志。

这篇文章将向您展示的是，在目前 Gentoo 官方尚未支持的情况下，如何合并 `/usr`。我的旨意并不是说 `/usr` 合并有很多好处，`/usr` 合并的优点也不在本文的讨论范围之内。这篇文章唯一的目的是给那些知道自己想要合并 `/usr`、却不知道该怎么弄的用户提供一个教程。

{: .notice--danger}
虽然目前可以在 Gentoo 上合并 `/usr`，但请铭记，**目前 Gentoo 官方尚未支持 `/usr` 合并！**如果您不擅长处理系统问题，尤其是和符号链接相关的问题的话，那么不推荐合并 `/usr`。

{: .notice--danger}
目前已知有些软件包在 `/usr` 合并后的 Gentoo 系统上无法正常安装，例如 `dev-ml/dune`。此类安装问题通常需要修改软件包的 `ebuild` 来解决，因此除非您了解相关的流程，否则不建议合并 `/usr`。

[freedesktop]: https://www.freedesktop.org/wiki/Software/systemd/TheCaseForTheUsrMerge/
[fedora]: https://fedoraproject.org/wiki/Features/UsrMove#Detailed_Description
[fhs]: https://zh.wikipedia.org/zh-cn/%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F%E5%B1%82%E6%AC%A1%E7%BB%93%E6%9E%84%E6%A0%87%E5%87%86
[0pointer-de]: http://0pointer.de/blog/projects/the-usr-merge
[split-usr]: https://packages.gentoo.org/useflags/split-usr

## 不同的 `/usr` 合并方法

在开始前，有必要介绍一下目前 GNU/Linux 发行版中常见的两种不同的合并 `/usr` 的方式：

1. 将 `/bin` 并入 `/usr/bin`、`/lib` 并入 `/usr/lib`、`/lib64` 并入 `/usr/lib64`、`/sbin` 并入 `/usr/sbin`。这是 Fedora 和 Debian 采用的方式。
   {: #usr-merge-variant-1}

   ```console
   $ ls -dl /bin /lib /lib64 /sbin /usr/sbin
   lrwxrwxrwx 1 root root    7 Dec 13 14:11 /bin -> usr/bin
   lrwxrwxrwx 1 root root    7 Dec 13 14:11 /lib -> usr/lib
   lrwxrwxrwx 1 root root    9 Dec 13 14:11 /lib64 -> usr/lib64
   lrwxrwxrwx 1 root root    8 Dec 13 14:11 /sbin -> usr/sbin
   drwxr-xr-x 1 root root 7006 Dec 26 09:50 /usr/sbin
   ```

2. 在上述合并的基础上，再将 `/usr/sbin` 并入 `/usr/bin`。Arch Linux 目前采用这种方式；从已经支持 `split-usr` USE 标志的 Gentoo 软件包 [`sys-apps/baselayout` 的 `ebuild`][baselayout] 来看，Gentoo 应该也是准备采取这种方案。
   {: #usr-merge-variant-2}

   ```console
   $ ls -dl /bin /lib /lib64 /sbin /usr/sbin
   lrwxrwxrwx 1 root root 7 Dec 13 14:11 /bin -> usr/bin
   lrwxrwxrwx 1 root root 7 Dec 13 14:11 /lib -> usr/lib
   lrwxrwxrwx 1 root root 9 Dec 13 14:11 /lib64 -> usr/lib64
   lrwxrwxrwx 1 root root 7 Dec 13 14:11 /sbin -> usr/bin
   lrwxrwxrwx 1 root root 3 Dec 13 14:11 /usr/sbin -> bin
   ```

{: .notice--info}
上面的命令输出只是用于演示两种不同的合并 `/usr` 方法下的 `/usr/sbin` 的区别，可能会与您实际遇到的目录布局有所偏差。

本文将主要使用第一种方法，因为我用过 Fedora 和 Debian，对这种方法产生的文件系统布局更熟悉，而 Arch Linux 我还没用过。不过，即使您准备采取第二种方法，也可以参阅本教程。第二种是 Gentoo 合并 `/usr` 所计划采用的方式，因此使用该方法会稍微简单些，反倒是第一种方法略微复杂。如果这篇教程介绍的是完成一种更复杂的方案的步骤，那借助它来做一件更简单的事应该不在话下。虽说如此，您仍然需要能触类旁通，适当修改此教程中提到的命令，以满足您自己的情况和需求。

[baselayout]: https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-apps/baselayout/baselayout-2.7.ebuild#n192

## 前提条件

- `/usr` 合并既可以在新系统安装时完成，也可以在一个已经安装好的系统上进行。这两种情况下的操作步骤有所不同，本文将会在两个不同的小节中分别讨论。

- 在开始之前，您需要准备一个启动盘（例如用 Gentoo 安装光盘 ISO 映像制作的 USB 启动盘）。如果您是在安装新的 Gentoo 系统，那您肯定已经有了一个 Gentoo 安装盘；但是如果您准备在一个已经装好的系统上合并 `/usr` 的话，就需要找一个启动盘或者做一个了，因为有些步骤需要在您的系统不在运行时进行，此时就需要有另一个允许您对您的 Gentoo 系统进行任意操作的环境。
  {: #bootable-drive}

## 在系统安装时合并

以下步骤假设您是遵循 [Gentoo 手册][handbook]的步骤安装的系统。

1. 完成“安装 stage3”中的 [stage 压缩包的解压][unpack-stage]后，进入解压出的 `usr` 目录，然后从 stage 压缩包中重新解压 `./bin`、`./lib`、`./lib64` 和 `./sbin`。

   ```console
   livecd /mnt/gentoo # cd usr
   livecd /mnt/gentoo/usr # tar xpvf ../stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner ./{bin,lib,lib64,sbin}
   ```

2. 回到上层目录，然后将 `bin`、`lib`、`lib64` 和 `sbin` 替换为指向 `usr` 下同名目录的符号链接。

   ```console
   livecd /mnt/gentoo/usr # cd ..
   livecd /mnt/gentoo # rm -rf bin lib lib64 sbin
   livecd /mnt/gentoo # ln -s usr/bin bin
   livecd /mnt/gentoo # ln -s usr/lib lib
   livecd /mnt/gentoo # ln -s usr/lib64 lib64
   livecd /mnt/gentoo # ln -s usr/sbin sbin
   ```

   <div class="notice--primary" id="variant-2-usr-sbin">
   {{ "如果您准备采用[第二种 `/usr` 合并方案](#usr-merge-variant-2)，您应该在此基础上，将 `usr/sbin` 中的所有内容移到 `usr/bin` 中，然后把 `usr/sbin` 替换成指向 `usr/bin` 的符号链接：" | markdownify }}

   {{ "```console
livecd /mnt/gentoo # cd usr
livecd /mnt/gentoo/usr # mv sbin/* bin
livecd /mnt/gentoo/usr # rmdir sbin
livecd /mnt/gentoo/usr # ln -s bin sbin
```" | markdownify }}
   </div>

   如下所示，这样操作的结果是 `bin`、`lib`、`lib64` 和 `sbin` 变为符号链接：

   ```console
   livecd /mnt/gentoo # ls -l
   total 16
   lrwxrwxrwx 1 root root    7 Dec 28 04:07 bin -> usr/bin
   drwxr-xr-x 1 root root   10 Dec 23 05:20 boot
   drwxr-xr-x 1 root root 1686 Dec 23 05:25 dev
   drwxr-xr-x 1 root root 1546 Dec 23 06:32 etc
   drwxr-xr-x 1 root root   10 Dec 23 05:20 home
   lrwxrwxrwx 1 root root    7 Dec 28 04:07 lib -> usr/lib
   lrwxrwxrwx 1 root root    9 Dec 28 04:07 lib64 -> usr/lib64
   drwxr-xr-x 1 root root   10 Dec 23 05:20 media
   drwxr-xr-x 1 root root   10 Dec 23 05:20 mnt
   drwxr-xr-x 1 root root   10 Dec 23 05:20 opt
   drwxr-xr-x 1 root root    0 Dec 23 03:28 proc
   drwx------ 1 root root   10 Dec 23 05:20 root
   drwxr-xr-x 1 root root   10 Dec 23 05:20 run
   lrwxrwxrwx 1 root root    8 Dec 28 04:08 sbin -> usr/sbin
   drwxr-xr-x 1 root root   10 Dec 23 05:20 sys
   drwxrwxrwt 1 root root   10 Dec 23 06:32 tmp
   drwxr-xr-x 1 root root  128 Dec 23 05:29 usr
   drwxr-xr-x 1 root root   66 Dec 23 05:20 var
   ```

3. 继续按照 Gentoo 手册中的指示操作，直到您 [`chroot` 进了 `/mnt/gentoo`][chroot]。

4. 使用 `find -L /usr -type l` 命令找出 `/usr` 下所有损坏的符号链接。
   {: #sys-inst-4}

   ```console
   (chroot) livecd / # find -L /usr -type l
   /usr/sbin/resolvconf
   /usr/bin/awk
   ```

   上面的例子中，`/usr/sbin/resolvconf` 和 `/usr/bin/awk` 是损坏的符号链接，也就是说它们所指向的路径不存在。如果其它程序和脚本需要使用这些符号链接指向的文件时，就会出现错误。例如，许多软件包的构建都需要用到 `awk` 命令，而 `/usr/bin/awk` 符号链接断了，就会导致 `awk` 命令不可用，您在安装需要 `awk` 的软件包时就会遇到问题。

   ```console
   (chroot) livecd / # /usr/bin/awk
   bash: /usr/bin/awk: No such file or directory
   ```

   若要修复一个损坏的符号链接，首先切换到该链接所在的目录，然后用 `ls -l` 查看它所指向的路径。

   ```console
   (chroot) livecd / # cd /usr/bin/
   (chroot) livecd /usr/bin # ls -l awk
   lrwxrwxrwx 1 root root 15 Dec 23 05:26 awk -> ../usr/bin/gawk
   ```

   因为 `awk` 符号链接本来应该是在 `/bin` 下的，它就会被解析到 `/bin/../usr/bin/gawk`，也就是 `/usr/bin/gawk`，是一个合法路径。但是现在挪到 `/usr` 后，它被解析到 `/usr/bin/../usr/bin/gawk`，也就是 `/usr/usr/bin/gawk`，就是个不存在的路径，导致链接断开。修复起来也不难，将原来的链接删除，然后重新连到正确的目标即可：

   ```console
   (chroot) livecd /usr/bin # rm awk
   (chroot) livecd /usr/bin # ln -s gawk awk
   ```

   对于 `/usr/sbin/resolvconf` 来说，也是同样的操作：

   ```console
   (chroot) livecd / # cd /usr/sbin/
   (chroot) livecd /usr/sbin # ls -l resolvconf
   lrwxrwxrwx 1 root root 21 Dec 23 06:28 resolvconf -> ../usr/bin/resolvectl
   (chroot) livecd /usr/sbin # rm resolvconf
   (chroot) livecd /usr/sbin # ln -s ../bin/resolvectl resolvconf
   ```

   如果您现在再运行 `find -L /usr -type l` 的话，该命令应该不再输出任何内容，意味着所有损坏的符号链接都已被成功修复。

   <div class="notice--success">
   {{ "实际上，`find -L -type l` 可以用来在各种情景下搜索损坏的符号链接。`find` 虽说是个很基础的命令，但是非常强大，在各路 GNU/Linux 发行版上基本也都是预装。因此，完全没有必要安装任何诸如 `symlinks` 的其它软件包来寻找损坏的符号链接。" | markdownify }}

   {{ "`find(1)` 手册页面对此的描述如下：" | markdownify }}

   {{ "```
        -type c
               File is of type c:

               l      symbolic link; this is never true if the -L option or the
                      -follow  option is in effect, unless the symbolic link is
                      broken.  If you want to search for symbolic links when -L
                      is in effect, use -xtype.
```" | markdownify }}
   </div>

5. 屏蔽 `split-usr` USE 标志，让支持区分 `/usr` 合并后的系统的软件包在构建时可以为合并后的文件系统进行构建。由于 `split-usr` 是强制启用的 USE 标志，仅仅声明 `-split-usr` 是不够的；您需要在 `/etc/portage/profile/use.mask` 中屏蔽 `split-usr。
   {: #sys-inst-5}

   ```
   # /etc/portage/profile/use.mask

   # 屏蔽分离式 /usr 布局的 USE 标志
   split-usr
   ```

   如果想了解更多的话，请参阅[相关的 Gentoo Wiki 条目][use-mask]。

6. 按照 Gentoo 手册中的步骤，完成剩余的安装步骤。请记得[更新 `@world` 集合][update-world]以应用 `split-usr` USE 标志的改动。

   当您运行安装在 `/sbin` 或 `/usr/sbin` 中的命令时，您可能会遇到“command not found”的错误提示。例如，如果您准备安装 GRUB，那么在运行 `/usr/sbin/grub-install` 的时候就会碰到该错误。您可以用 `whereis` 确认您要运行的命令确实在 `/usr/sbin` 下。

   ```console
   (chroot) livecd ~ # grub-install --target=x86_64-efi --efi-directory=/boot
   bash: grub-install: command not found
   (chroot) livecd ~ # whereis grub-install
   grub-install: /usr/sbin/grub-install /usr/share/man/man8/grub-install.8.bz2
   ```

   导致这个问题的原因是 `/usr/sbin` 从 `PATH` 环境变量中消失了：

   ```console
   (chroot) livecd ~ # printenv PATH
   /usr/local/bin:/usr/bin:/opt/bin
   ```

   为了能完成系统安装，最简便、最快速的解决方法是使用 `export PATH="/usr/sbin:$PATH"`，暂时将 `/usr/sbin` 加到 `PATH` 中。但是，每次打开一个新的 shell 的时候都需要运行一次这个命令。要永久解决这个问题的话，请参阅下面的[“将 `/usr/sbin` 永久添加到 `PATH` 中”][add-sbin-to-path]小节。

   ```console
   (chroot) livecd ~ # export PATH="/usr/sbin:$PATH"
   (chroot) livecd ~ # printenv PATH
   /usr/sbin:/usr/local/bin:/usr/bin:/opt/bin
   (chroot) livecd ~ # grub-install --target=x86_64-efi --efi-directory=/boot
   Installing for x86_64-efi platform.
   Installation finished. No error reported.
   ```

[handbook]: https://wiki.gentoo.org/wiki/Handbook:Main_Page/zh-cn
[unpack-stage]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage/zh-cn#.E8.A7.A3.E5.8E.8Bstage.E5.8E.8B.E7.BC.A9.E5.8C.85
[chroot]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base/zh-cn#.E8.BF.9B.E5.85.A5.E6.96.B0.E7.8E.AF.E5.A2.83
[use-mask]: https://wiki.gentoo.org/wiki//etc/portage/profile/use.mask
[update-world]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base/zh-cn#.E6.9B.B4.E6.96.B0.40world.E9.9B.86.E5.90.88
[add-sbin-to-path]: #将-usrsbin-永久添加到-path-中

## 在已安装好的系统上合并

1. 从您准备的[启动盘][bootable-drive]启动您的电脑，然后[挂载][mount-root]您系统的 root 分区。以下步骤假设您将 root 分区挂载到了 `/mnt/gentoo` 下。切换到您分区被挂载的位置。

   ```console
   livecd ~ # cd /mnt/gentoo
   ```

2. 使用 `\cp` 命令和 `-r`、`--preserve=all` 和 `--remove-destination` 选项，将 `bin`、`lib`、`lib64` 和 `sbin` 中的内容分别复制到 `usr/bin`、`usr/lib`、`usr/lib64` 和 `usr/sbin` 中。

   ```console
   livecd /mnt/gentoo # \cp -rv --preserve=all --remove-destination bin/* usr/bin
   livecd /mnt/gentoo # \cp -rv --preserve=all --remove-destination lib/* usr/lib
   livecd /mnt/gentoo # \cp -rv --preserve=all --remove-destination lib64/* usr/lib64
   livecd /mnt/gentoo # \cp -rv --preserve=all --remove-destination sbin/* usr/sbin
   ```

   {: .notice--info}
   `cp` 的 `-v` 选项允许您查看复制进度。如果不需要，可以省略该选项。

   <div class="notice--info">
   {{ "在 `cp` 前面加一个反斜杠 `\` 可以忽略为 `cp` 设置的别名。如果您使用的是 Gentoo 安装光盘映像，那么 `cp` 默认的别称是 `cp -i`；这个 `-i` 选项会导致 `cp` 在每次覆写文件前都要求您手动确认。" | markdownify }}

   {{ "```console
livecd ~ # alias cp
alias cp='cp -i'
```" | markdownify }}

   {{ "如果使用 `\cp` 而非 `cp`，就可以忽略该别名。您也可以用 `unalias cp` 移除该别名，然后不加 `\`、正常调用 `cp`；也可以利用 `yes` 程序，使用 `yes | cp ... ` 向 `cp` 的标准输入传递一大堆 `y`，自动确认每个要覆写的文件。" | markdownify }}

   {{ "```console
livecd /mnt/gentoo # unalias cp
livecd /mnt/gentoo # cp -rv --preserve=all --remove-destination bin/* usr/bin
livecd /mnt/gentoo # cp -rv --preserve=all --remove-destination lib/* usr/lib
livecd /mnt/gentoo # cp -rv --preserve=all --remove-destination lib64/* usr/lib64
livecd /mnt/gentoo # cp -rv --preserve=all --remove-destination sbin/* usr/sbin
```" | markdownify }}

   {{ "```console
livecd /mnt/gentoo # yes | cp -rv --preserve=all --remove-destination bin/* usr/bin
livecd /mnt/gentoo # yes | cp -rv --preserve=all --remove-destination lib/* usr/lib
livecd /mnt/gentoo # yes | cp -rv --preserve=all --remove-destination lib64/* usr/lib64
livecd /mnt/gentoo # yes | cp -rv --preserve=all --remove-destination sbin/* usr/sbin
```" | markdownify }}

3. 将 `bin`、`lib`、`lib64` 和 `sbin` 替换为指向 `usr` 下同名目录的符号链接。

   ```console
   livecd /mnt/gentoo # rm -rf bin lib lib64 sbin
   livecd /mnt/gentoo # ln -s usr/bin bin
   livecd /mnt/gentoo # ln -s usr/lib lib
   livecd /mnt/gentoo # ln -s usr/lib64 lib64
   livecd /mnt/gentoo # ln -s usr/sbin sbin
   ```

   {: .notice--primary}
   如果您准备采用[第二种 `/usr` 合并方案][variant-2]，您应该在此基础上，将 `usr/sbin` 中的所有内容移到 `usr/bin` 中，然后把 `usr/sbin` 替换成指向 `usr/bin` 的符号链接。点击[此处][variant-2-usr-sbin]查看相关的命令。

4. 重启电脑，进入到您的系统中（不是启动盘）。只要您把 `/bin`、`/lib`、`/lib64` 和 `/sbin` 中的文件正确地复制到了 `/usr` 中、并正确地建立了符号链接，您的系统就应该能正常启动。

5. 修复 `/usr` 下损坏的符号链接，具体的步骤和在安装时合并 `/usr` 步骤中的[第 4 步][sys-inst-4]相同。不过，有一些符号链接是可以不用手动修复的：

   - 如果您同时使用 systemd 和 dracut，您可能会遇到一些名称类似 `dracut-*.service` 的链接。此种链接不需要手动修复，只需在屏蔽 `split-usr` USE 标志并重新编译 systemd **之后**重新安装 `sys-kernel/dracut` 即可。

   - `/usr/lib/modules/*.*.*/build` 和 `/usr/lib/modules/*.*.*/source` 也可以不修复。
   
   而其余的符号链接，如 `/usr/bin/awk` 和 `/usr/sbin/resolvconf`，就需要手动干预修复了。

6. 屏蔽 `split-usr` USE 标志，具体的步骤和在安装时合并 `/usr` 步骤中的[第 5 步][sys-inst-5]相同。

7. 更新 Portage 的 `@world` 集合，重新构建原本启用了 `split-usr` USE 标志的软件包，以应用新的 USE 标志变动。

   ```console
   # emerge --ask --update --deep --newuse @world
   ```
   
   如果您同时使用 systemd 和 dracut，您现在就可以运行下面的命令重新安装 dracut，从而修复损坏的 `dracut-*.service` 符号链接了。如果您不使用 dracut，**请勿**运行下面的命令，因为它会安装 dracut。
   
   ```console
   # emerge --ask --oneshot sys-kernel/dracut
   ```

[bootable-drive]: #bootable-drive
[mount-root]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks/zh-cn#.E6.8C.82.E8.BD.BD_root_.E5.88.86.E5.8C.BA
[variant-2]: #usr-merge-variant-2
[variant-2-usr-sbin]: #variant-2-usr-sbin
[sys-inst-4]: #sys-inst-4
[sys-inst-5]: #sys-inst-5

## 附加步骤

完成上述步骤后，您的系统的 `/usr` 目录就成功合并了，并且运行起来基本上应该和没合并前一样。虽说如此，但现在系统仍然有一些对正常运行没有大影响的小瑕疵，可以通过执行下面的附加步骤来解决。

### 将 `/usr/sbin` 永久添加到 `PATH` 中

{: .notice--primary}
如果您使用的是[第二种 `/usr` 合并方式][variant-2]的话，那么无需执行此步骤。

之前推测 [Gentoo 会如何完成 `/usr` 合并][variant-2]的时候简单提及过，`/usr/sbin` 会被合并到 `/usr/bin` 中。如果仔细看 [`sys-apps/baselayout` 的 `ebuild`][baselayout] 的话，您也许会发现，如果 `split-usr` USE 标志被禁用的话，`/usr/sbin` 会被从 `PATH` 环境变量中移除，毕竟所有本该在 `/usr/sbin` 里的命令都被挪到 `/usr/bin` 里了，而 `/usr/bin` 是在 `PATH` 里面的。

但是，如果您使用的是[第一种 `/usr` 合并方式][variant-1]，那么这样就会出现问题了。这种方式中，`/usr/sbin` 里的命令仍在原处，但在禁用了 `split-usr` USE 标志后 `PATH` 里就没有了 `/usr/sbin`，导致任何 `/usr/sbin` 中的命令都无法被直接调用，除非您在命令前面加上 `/usr/sbin/`。

我推荐的解决方式是在在 `/etc/env.d` 中创建一个文件，把 `/usr/sbin` 加回 `PATH`，就可以在系统全局层面解决这个问题。选择一个文件名（例如 `50baselayout-sbin`），然后在文件中写入如下的 `PATH` 和 `ROOTPATH` 定义：

```sh
# /etc/env.d/50baselayout-sbin

PATH="/usr/local/sbin:/usr/sbin"
ROOTPATH="/usr/local/sbin:/usr/sbin"
```

这里我不仅把 `/usr/sbin` 加了回来，还添上了 `/usr/local/sbin`，因为这个路径在 `sys-apps/baselayout` 的 `split-usr` USE 标志被禁用时也会被从 `PATH` 中移除。

随后，重新加载环境设置以应用更改：

```console
# /usr/sbin/env-update
$ source /etc/profile
```

如需关于使用 `/etc/env.d` 目录的更多信息，您可以参阅 [Gentoo 手册中的相关部分][etc-env.d]。

[variant-1]: #usr-merge-variant-1
[etc-env.d]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Working/EnvVar/zh-cn#.E5.85.A8.E5.B1.80.E5.8F.98.E9.87.8F.E7.9A.84.E5.AE.9A.E4.B9.89

### 移除 `emerge` 关于符号链接的提示信息

您在使用 `emerge` 更新或卸载软件时可能会遇到如下的提示信息：

```
 * One or more symlinks to directories have been preserved in order to
 * ensure that files installed via these symlinks remain accessible. This
 * indicates that the mentioned symlink(s) may be obsolete remnants of an
 * old install, and it may be appropriate to replace a given symlink with
 * the directory that it points to.
 *
 * 	/bin
 * 	/lib64
 * 	/sbin
 *
```

这是正常现象，毕竟 `/bin`、`/lib`、`/lib64` 和 `/sbin` 在 `/usr` 被合并后的确不再是目录，而是符号链接了。

如果您想移除这些提示的话，可以在 `/etc/portage/make.conf` 中添加如下一行：

```sh
UNINSTALL_IGNORE="/bin /lib /lib64 /sbin"
```
