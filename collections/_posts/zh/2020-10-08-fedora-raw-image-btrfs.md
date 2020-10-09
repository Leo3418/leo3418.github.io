---
title: "在通过映像安装的 Fedora 系统上使用 Btrfs"
lang: zh
tags:
  - Fedora
  - GNU/Linux
categories:
  - 教程
asciinema-player: true
toc: true
---
{% include img-path.liquid %}
自 Fedora 33 起，Fedora 将[开始][fedora-btrfs]使用 [Btrfs][wikipedia] 作为桌面版本的默认文件系统。在我关注的几个 Fedora 用户社区（以国外的为主）中，这一更改还是受到了一些欢迎的，毕竟 Btrfs 和传统的 ext4 相比有一些额外、实用的功能。其它非桌面版本（例如服务器版）默认仍然使用 ext4，不过用户在使用 Anaconda 安装 Fedora 时仍然可以手动选择使用 Btrfs。但是，如果使用的是非桌面版本的 raw 映像，比如 `aarch64` 最小安装（Minimal）映像，因为是直接将映像写到安装目标磁盘上的，而不是用 Anaconda 安装器，所以就没有机会选择使用除 ext4 以外的文件系统。而在这篇帖子中，我将展示一种用映像安装时也可以使用 Btrfs 的方法，其原理是在应用映像后手动转换文件系统。

[fedora-btrfs]: https://fedoramagazine.org/btrfs-coming-to-fedora-33/
[wikipedia]: https://en.wikipedia.org/wiki/Btrfs

## 选用 Btrfs 的理由

我在上一自然段中放置了一个 Fedora 杂志上关于 Fedora 33 会将 Btrfs 作为默认选项的文章的链接，该文章中已经列出了 Btrfs 的一些好处：

- 利用校验和，对数据进行查错；如果发现数据损坏，Btrfs 绝不会将该数据返回给读取它的应用程序，有助于尽早发现数据错误。试想您硬盘上有文件出现错误，损坏了，还被自动同步文件的程序（比如网盘客户端）给同步了，您对此却毫不知情；等到有一天真的需要用到这个文件了，发现打不开，同步的备份也早已被覆写成损坏的文件了，数据就此丢失。而使用 Btrfs 的话，在同步程序尝试同步它的时候就会发现问题，可以避免数据损坏的问题被隐蔽。

- 使用写入时复制（Copy-on-Write, CoW）机制，有助于节省空间，并从一定程度上提升数据安全性。

- Btrfs 支持数据压缩，同样可以帮助节省磁盘空间（Fedora 33 目前还未启用压缩功能）。

不过，这些优势都是在文件系统内部体现的，日常使用时可能不会立刻感受到它们。Btrfs 还有一些好处是用户可以直接感受到的。在 Btrfs 文件系统上安装 Fedora 并使用了一段时间后，我个人觉得它有以下几个明显的优势：

- 只要配置得当，就不用再担心因为早期分区规划不善，导致后期出现一个分区快满了而另一个分区还有很多空余时，需要调整分区的问题了。

  假设您的 `/home` 分区空间不足，但是 `/` 分区还有空闲空间，所以需要缩小 `/`，给 `/home` 腾空间。如果使用的是传统分区法，直接在硬盘上创建的分区的话，调整分区大小会比较困难。LVM 原生提供[调整分区大小][lvm-resize]的功能，但仍然需要使用好几个命令来完成。

  而如果使用 Btrfs，您可以在一个 Btrfs 分区上为不同的挂载点创建多个*子卷*。`/home` 和 `/` 会被放在同一个 Btrfs 分区的两个子卷中，但是实际使用时，它们看起来和两个分区无异。Btrfs 最好的地方在于，两个管理起来好似两个分区的子卷，可以共享该 Btrfs 分区的全部容量，因此 `/home` 和 `/` “分区”之间的分隔消失了，也就不再需要调整分区大小了。

- Btrfs 允许您保存每个子卷的快照，并支持将快照发送到别处，因此可用作全盘备份或系统备份的工具。快照还支持增量保存，因此可以进行增量备份，节省空间。

[lvm-resize]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/assembly_modifying-logical-volume-size-configuring-and-managing-logical-volumes
[inc-bak]: https://fedoramagazine.org/btrfs-snapshots-backup-incremental/

## 免责声明

我会尽量确保此帖中的步骤的准确性，但无法提供完全的保证。**在您开始操作前，请备份所有重要数据，并确保您了解在出问题后恢复数据的方法。**我将不会对任何数据丢失和硬件损坏负责，哪怕这些损失是您准确无误地执行此教程的步骤造成的。

## 概述

接下来的步骤假设您已经将 Fedora 的 raw 映像写入到了一个磁盘上，并且您可以在该盘上安装的 Fedora 未运行的时候操作上面的分区和文件。例如，您可以在同一台电脑上启动另一个安装在别处的系统；如果您把 Fedora 装到了可移动存储上的话，也可以直接把它插到另一台电脑上进行工作。

整个流程的大体步骤如下：

1. 将根文件系统从 ext4 转换至 Btrfs
2. 修改系统文件，以识别新的文件系统
3. 修复根文件系统上的 SELinux 标签

## 将文件系统转换为 Btrfs

首先需要做的是找到根文件系统分区（下称“root 分区”）在操作系统下对应的设备。您可以运行 `lsblk -p` 来查询此信息。

```console
$ lsblk -p
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
/dev/sda      8:0    0 232.9G  0 disk
├─/dev/sda1   8:1    0   100M  0 part /boot/efi
├─/dev/sda2   8:2    0   512M  0 part /boot
├─/dev/sda3   8:3    0  71.2G  0 part /home
└─/dev/sda4   8:4    0 161.1G  0 part
/dev/sdb      8:16   0 238.5G  0 disk
├─/dev/sdb1   8:17   0   100M  0 part
├─/dev/sdb2   8:18   0    16M  0 part
├─/dev/sdb3   8:19   0 237.9G  0 part
└─/dev/sdb4   8:20   0 512.3M  0 part
/dev/sdc      8:32   1  29.8G  0 disk
├─/dev/sdc1   8:33   1   600M  0 part /run/media/leo/BD95-A5EF
├─/dev/sdc2   8:34   1     1G  0 part /run/media/leo/f25c31eb-a67b-46bb-a8b6-280
└─/dev/sdc3   8:35   1  28.2G  0 part /run/media/leo/b9c84f8b-74cc-4615-b8bb-59e
/dev/zram0  252:0    0     4G  0 disk [SWAP]
```

在 `lsblk` 的输出中找到容量与您写入 Fedora 的磁盘大小相近的设备。在上面的例子中，这个盘是 `/dev/sdc`。root 分区是最后一个、也是容量最大的分区，也就是 `/dev/sdc3`。

得到了设备名称后，您就可以通过 `btrfs-convert` 命令将该分区转换为 Btrfs 了。在调用该命令时，将设备名称作为参数提供给 `btrfs-convert` 程序。如果您运行 `lsblk` 显示的 root 分区的设备名不是 `/dev/sdc3`，请务必相应地修改下面的命令。除此以外，由于 `btrfs-convert` 需要超级用户权限，您可能需要在命令前加上 `sudo`。

```console
# btrfs-convert /dev/sdc3
```

假如运行此命令时遇到了分区已挂载的错误提示，只需将分区卸载，然后重新运行 `btrfs-convert` 即可：

```console
# umount /dev/sdc3
```

{% include asciinema-player.html name="btrfs-convert.cast" poster="npt:18.5" %}

## 修改操作系统文件

Root 分区的文件系统已被成功转为 Btrfs 了。但是，因为文件系统转换操作会导致分区的 UUID 被更改，任何使用 UUID 查找 root 分区的系统设置文件都需要进行相应的修改。

### 找出新的分区 UUID

在向系统文件中填写新的 UUID 前，首先肯定要知道新的 UUID 是什么。运行 `lsblk -o +UUID` 以查看分区 UUID：

```console
$ lsblk -o +UUID
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT UUID
sda      8:0    0 232.9G  0 disk
├─sda1   8:1    0   100M  0 part /boot/efi  B7BD-87CF
├─sda2   8:2    0   512M  0 part /boot      8fa7443f-cf79-4a8d-b7b8-fe1d1886c761
├─sda3   8:3    0  71.2G  0 part /home      a8bb548a-6e3d-4639-b38b-5e0eac68df4c
└─sda4   8:4    0 161.1G  0 part            E01A56741A564824
sdb      8:16   0 238.5G  0 disk
├─sdb1   8:17   0   100M  0 part            6CBE-049D
├─sdb2   8:18   0    16M  0 part
├─sdb3   8:19   0 237.9G  0 part            8A36C90E36C8FBE7
└─sdb4   8:20   0 512.3M  0 part            6CA8C978A8C940F6
sdc      8:32   1  29.8G  0 disk
├─sdc1   8:33   1   600M  0 part /run/media BD95-A5EF
├─sdc2   8:34   1     1G  0 part /run/media f25c31eb-a67b-46bb-a8b6-28003354b44a
└─sdc3   8:35   1  28.2G  0 part /run/media ef9e12b6-16e4-44a7-902e-74e721199b67
zram0  252:0    0     4G  0 disk [SWAP]
```

上面的示例中，root 分区 `sdc3` 对应的 UUID 是 `ef9e12b6-16e4-44a7-902e-74e721199b67`。您的磁盘上的分区 UUID 肯定会与此不同，因此在执行下面的步骤时，请切记将其改为您实际得到的 UUID。

### 更新系统文件中的 UUID

获取到 UUID 后，就可以将其填进系统文件了。修改系统文件时，请注意以下事项：

- 您需要超级用户权限来修改系统文件，即使是另一个不在运行中的系统的文件也是一样。

- 请确保您编辑的不是当前正在运行的系统的文件。如果您在终端工作的话，请勿使用诸如 `/etc/fstab` 的绝对路径。

- 由于之前转换文件系统时卸载了 root 分区，因此编辑其中的文件前，您应将其重新挂载。例如：

  ```console
  # mkdir /mnt/rootfs
  # mount /dev/sdc3 /mnt/rootfs
  ```

需要修改的文件和内容：

- Root 分区下的 `etc/fstab`<br>
  找到 `/` 的条目，进行以下修改：
  - 更新 UUID
  - 将文件系统类型从 `ext4` 改为 `btrfs`
  - 将此条目行尾的两个数改为 `0 0`

  ```diff
  - UUID=b9c84f8b-74cc-4615-b8bb-59eee5ec46b7 /               ext4    defaults        1 1
  + UUID=ef9e12b6-16e4-44a7-902e-74e721199b67 /               btrfs   defaults        0 0
    UUID=f25c31eb-a67b-46bb-a8b6-28003354b44a /boot           ext4    defaults        1 2
    UUID=BD95-A5EF                            /boot/efi       vfat    umask=0077,shortname=winnt 0 2
  ```

- 该磁盘上的 **`/boot` 分区**下 `loader/entries` 目录中的任何 `.conf` 文件：<br>
  修改 `options` 下 `root=UUID=` 后面的值

  ```diff
    title Fedora (5.8.13-300.fc33.aarch64) 33 (Thirty Three Prerelease)
    version 5.8.13-300.fc33.aarch64
    linux /vmlinuz-5.8.13-300.fc33.aarch64
    initrd /initramfs-5.8.13-300.fc33.aarch64.img
  - options root=UUID=b9c84f8b-74cc-4615-b8bb-59eee5ec46b7 ro
  + options root=UUID=ef9e12b6-16e4-44a7-902e-74e721199b67 ro
    grub_users $grub_users
    grub_arg --unrestricted
    grub_class kernel
  ```

  {: .notice--info}
  同样地，请确保在修改 `/boot` 分区内的文件前已将其挂载。如果 root 分区是 `/dev/sdc3` 的话，这个分区就是 `/dev/sdc2`。

  {: .notice--info}
  如果您之前更新过 Linux 内核，`loader/entries` 下会有多个 `.conf` 文件，每个文件对应一个内核版本。您可以只修改一个 `.conf` 文件，比如说最新版本内核对应的 `.conf` 文件；不过您需要注意不要启动其它版本的内核。

## 修复 SELinux 标签

更新完分区的 UUID 后，系统就可以找到转换后的 root 分区了。然而，由于 SELinux 的原因，此时操作系统仍然无法启动。

要解决 SELinux 的问题，请在 root 分区的根目录下创建一个 `.autorelabel` 文件：

```console
# touch .autorelabel
```

现在操作系统就可以从转换后的 Btrfs 分区启动了。首次启动时，您可能会看到一些 systemd 单元启动失败；对于文件系统转换后的初次启动来说，这是正常现象。随后，您应该可以看见一条 `Starting Relabel all filesystems` 信息，此时系统就在修复 SELinux 标签了。

![正在为 SELinux 修复标签的信息]({{ img_path }}/relabeling.jpg){: .half}

整个修复过程可能需要一段时间。在我的树莓派 4 上，修复一个 Fedora 的全新安装需要几分钟的时间。修复完成后，系统会自动重新启动，并且在启动时应该不会继续报错了。

大功告成，开始在从 raw 映像安装的 Fedora 上享受 Btrfs 的新特性吧！

## 参考资料

- [ArchWiki 上关于 ext3/4 转换为 Btrfs 的说明](https://wiki.archlinux.org/index.php/Btrfs_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#%E4%BB%8E_Ext3/4_%E8%BD%AC%E6%8D%A2)
- <https://wiki.centos.org/HowTos/SELinux#Relabel_Complete_Filesystem>
