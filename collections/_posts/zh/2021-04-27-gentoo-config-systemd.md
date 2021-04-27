---
title: "Gentoo 配置指南：systemd"
lang: zh
tags:
  - Gentoo
  - GNU/Linux
categories:
  - 教程
toc: true
---

身为 Gentoo 官方安装文档，当前版本的 Gentoo 手册将重点放在了基于 OpenRC 的系统的配置，而不是 systemd。毕竟 OpenRC 是主要由 Gentoo 维护的项目，如果连自家的发行版都不把自己维护的 init 系统作为首选推荐的话，那就好比百度员工都在用谷歌。对于想安装 systemd 的用户，手册虽然也有少量的信息和指导，但主要都是让用户另行参考一篇[专门讨论 systemd 的 Wiki 文章][gentoo-wiki-systemd]。我觉得该文章的信息虽然很全面，但同时也很零散：系统安装过程中需要执行的指令散落在文章各处，导致安装过程中很容易遗漏关键的步骤。因此，我决定单独写一篇关于在 Gentoo 上配置 systemd 的文章，汇总安装 systemd 的全部步骤。

[gentoo-wiki-systemd]: https://wiki.gentoo.org/wiki/Systemd/zh-cn

## 如何理解本篇文章的内容

无论选什么 init 系统，Gentoo 的大致安装步骤都是一样的；只有一些细节的地方会根据 init 系统的不同而产生变化。因此，想要安装 systemd 的用户仍然可以遵循手册的步骤和指示来安装系统，但是在做到本篇文章中特别提到的、有注释或注解的步骤时，应仔细阅读本文中的相关信息。

## 配置 Linux 内核

如果想使用 systemd，还想在配置内核时使用自己的内核配置的话，请确保[此处][systemd-kernel-options]列出的所有必选内核选项都处于启用状态。

systemd 要求 `/usr` 在启动时必须处于已被挂载的状态，因此可能需要配置 initramfs 来挂载 `/usr`。欲了解详情，请参阅[此处][systemd-initramfs]的信息。不过，如果选择使用[发行版内核][dist-kernel]，就可以不管 initramfs 了，因为所有发行版内核的软件包默认都使用 initramfs。

[systemd-kernel-options]: https://wiki.gentoo.org/wiki/Systemd/zh-cn#.E5.86.85.E6.A0.B8
[systemd-initramfs]: https://wiki.gentoo.org/wiki/Systemd/zh-cn#.E5.9C.A8.E5.90.AF.E5.8A.A8.E6.97.B6.E7.A1.AE.E4.BF.9D.E6.8C.82.E8.BD.BD.E4.BA.86.2Fusr.E8.B7.AF.E5.BE.84
[dist-kernel]: https://wiki.gentoo.org/wiki/Project:Distribution_Kernel

## 配置系统

### 主机名、域名信息

手册中的这部分内容都只适用于 OpenRC，因此请忽略它们。使用 systemd 时，倘若系统不处于运行状态，那么修改主机名的方式就是编辑 `/etc/hostname` 文件，然后在该文件中填入主机名（除了主机名外，请勿向文件添加任何其它内容）。请注意：在 chroot 环境中，`hostnamectl` 命令无法使用。

### 配置网络

systemd 有一个组件叫作 `systemd-networkd`，已经提供了管理网络连接的功能，因此用户可以选择直接使用 `systemd-networkd`，不需要再安装任何其它软件包了。如果选择使用 `systemd-networkd` 的话，请忽略手册中对应章节的全部内容，然后参考[此处][systemd-networkd]的信息来配置 `systemd-networkd`。

[systemd-networkd]: https://wiki.gentoo.org/wiki/Systemd/zh-cn#systemd-networkd.E7.B3.BB.E7.BB.9F.E5.AE.88.E6.8A.A4.E8.BF.9B.E7.A8.8B.E7.AE.A1.E7.90.86.E7.BD.91.E7.BB.9C.E9.85.8D.E7.BD.AE

### 在启动时自动启用网络连接

倘若之前选择使用 `systemd-networkd` 的话，手册中的这部分内容同样可以忽略。如果之前没有运行过下面的指令的话，运行一次，就可以在开机时自动启用网络连接了：

```console
# systemctl enable systemd-networkd.service
```

### 配置引导和启动

截至目前，手册中此章节的信息全部仅适用于 OpenRC，因此请忽略它们。

## 安装系统工具

### Cron 守护进程

尽管 systemd 支持定时器单元，可以取代 cron 守护进程，但是 Gentoo 上的一些软件包仍然会在安装了 systemd 并且启用了 `systemd` USE 标志的情况下，向 `/etc/cron.{daily,hourly}` 等 cron 守护进程使用的目录中安装它们每天或每小时都需要运行的脚本。

比如说，在我自己的使用 systemd 的系统上，`/etc/cron.daily` 中就有一些脚本：

```console
leo@nvme-fussy ~ $ ls /etc/cron.daily/
logrotate  man-db  mlocate  suse.de-snapper
```

虽然这些软件包在安装 cron 脚本的同时也会提供对应的 systemd 定时器单元，但是那些定时器单元默认都处于未启用状态，需要手动启用，也很容易忘记启用它们。

因此，想要确保所有需要运行的计划任务都能被自动运行的最简单方法，就是安装一个 cron 守护进程，即使在使用 systemd 时也不例外。Cron 守护进程会定时运行 `/etc/cron.*` 目录下的全部脚本，所以只要软件包把自己需要定时运行的 cron 脚本放到合适的 `/etc/cron.*` 目录下（绝大多数 Gentoo 软件包都遵循这一标准），脚本就会被 cron 守护进程自动运行，无需任何额外的用户操作。用户无需再在安装完新软件包后手动寻找并启用该软件包提供的 systemd 定时器单元了。

目前，手册中着重介绍的 cron 守护进程是 `sys-process/cronie`。Cronie 在 systemd 上应该也是能正常地运行和使用的；但是，如果使用 systemd，就可以选择能将 `/etc/cron.*` 目录下的 cron 脚本和 systemd 深度整合的 `sys-process/systemd-cron`。`systemd-cron` 并不是像 Cronie 这种的单独的 cron 守护进程；它主要是由一些可以按计划执行 `/etc/cron.*` 下的脚本的 systemd 定时器单元所构成的。

如果想在 systemd 上安装 cron 守护进程，并且想选择 `sys-process/systemd-cron` 的话，请参考[此处][systemd-cron]的信息。

[systemd-cron]: https://wiki.gentoo.org/wiki/Systemd/zh-cn#.E6.9B.BF.E6.8D.A2_cron

### 远程访问

手册中只提到了在 OpenRC 上让 `sshd` 开机自启的命令。systemd 上的等效命令是：

```console
# systemctl enable sshd.service
```

### 安装 DHCP 客户端

`systemd-networkd` 自带 DHCP 客户端，因此无需另行安装。

## 重启进装好的系统前应执行的操作

当系统快安装好时，请在退出 chroot 环境前运行如下命令：

```console
# systemd-machine-id-setup
# systemctl preset-all --preset-mode=enable-only
```

第一条命令会创建机器 ID，这个 ID 会被 systemd 日志和 `systemd-networkd` 用到；第二条命令会激活一些默认应处于启用状态的 systemd 单元，其中许多单元都是基础系统功能所必需的。

## 对 Gentoo Wiki 上的 systemd 条目内容的补充

以上应该就是在 Gentoo 上正确配置 systemd 的所有必需步骤了。Gentoo Wiki 上的 [systemd 条目][gentoo-wiki-systemd]中还包括许多与配置 systemd 相关的有用的信息，推荐所有 systemd 用户参考。不过，对于该条目中的内容，有一些信息值得补充。

### `/etc/mtab`

systemd 条目中提到，`/etc/mtab` 应该是指向 `/proc/self/mounts` 的符号链接，但是在 stage3 压缩包中，该符号链接可能已经被创建好了。下面的命令可以用来检查符号链接是否已经被正确配置：

```console
$ ls -l /etc/mtab
```

如果能看到类似下面的命令输出，那么该符号链接就已经创建好了，不需要再手动创建了：

```
lrwxrwxrwx 1 root root 19 Nov 18 23:41 /etc/mtab -> ../proc/self/mounts
```
