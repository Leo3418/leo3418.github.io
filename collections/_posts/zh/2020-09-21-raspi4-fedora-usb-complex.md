---
title: "Fedora 在树莓派 4 上的 USB 问题的复杂解决方法"
lang: zh
tags:
  - 树莓派
  - Fedora
categories:
  - 教程
toc: true
last_modified_at: 2020-10-07
---

在[上一篇帖子](/2020/09/20/raspi4-fedora-usb-simple.html)中，我介绍了一种十分简单的解决在树莓派 4B 4GB/8GB 内存型号上运行 Fedora 时无法使用 USB 接口的方法。这种方法通过牺牲可用内存的方式来换取 USB 接口的正常功能。而在现在这篇帖子中，我将再介绍一种方法，虽然需要更多的操作，但是不会导致 3 GiB 内存的限制。

上篇帖子中提到，2GB 内存的型号因为没有 USB 相关的问题，无需进行额外操作。USB 接口不能使用的问题的具体症状也在该帖中[有所描述](/2020/09/20/raspi4-fedora-usb-simple.html#症状)。

## 概括

如果只用一句话总结这个方法的话，那就是让 Fedora 使用 openSUSE（另一个 GNU/Linux 发行版）的引导程序和固件。这其中涉及的步骤包括：
- 从 openSUSE 中提取文件
- 将文件复制到安装了 Fedora 的 SD 卡上
- 修改 openSUSE 的引导配置文件，以允许启动 Fedora

由于我将会提到比较多的细节，帖子的篇幅和内容可能会让您感觉这种方法很费劲，但实际上只有这几个大体步骤而已，并没有那么可怕。

## 从 openSUSE 中提取文件

### 下载 openSUSE 映像

要用 openSUSE 的文件之前肯定要先下载 openSUSE。因为只需要几个引导文件和固件，所以建议只下载最基础的 *openSUSE Leap JeOS* 映像即可。*Leap* 是 openSUSE 的稳定发行通道，而 JeOS 是不带桌面环境的最小安装，可以减少下载流量和磁盘占用。

截至此帖撰写时，树莓派 4 的最新的 openSUSE Leap JeOS 映像版本是 [Leap 15.2](http://download.opensuse.org/ports/aarch64/distribution/leap/15.2/appliances/openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64.raw.xz)。您也可以从 [openSUSE Wiki](https://en.opensuse.org/HCL:Raspberry_Pi4) 上下载最新版本。

### 提取映像

下载下来的文件以 `.xz` 结尾，意味着它是一个压缩的映像，所以在进行进一步操作前，需要先将其解压。

如果您的系统中安装了 `xz` 命令的话，可以使用下面的命令解压 openSUSE 的映像：

```console
$ xz -dv openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw.xz
```

{: .notice--info}
如有需要，请根据您下载的映像版本以及下载路径等因素，相应地修改此帖中提及的命令中的文件名。

这里用到的 `-d` 选项的意思是使用解压模式。`-v` 选项是用来让 `xz` 显示解压进度用的，可有可无。

等到选项执行完成后，解压出来的映像会直接替代原来的 `.xz` 文件，存储在同一位置，`.xz` 后缀也会被从文件名中删除。

### 挂载映像

映像解压完后，就可以将其挂载了，然后就可以将映像里的文件复制出来。openSUSE 的映像里有好几个分区；其中，第一个分区，也就是引导分区，包含您将要复制的引导文件和固件，所以只需挂载第一个分区即可。

您可以任选用来挂载映像的工具，只要能够达成可以从映像中往外复制文件的最终目标就行。下面是在 GNU/Linux 环境中使用 `mount` 命令挂载映像的方法。

1. 找出映像中引导分区的偏移量。可以使用 `fdisk` 命令来间接得出偏移量。

   ```console
   $ fdisk -l openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw
   Disk openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw: 2.2 GiB, 2353004544 bytes, 4595712 sectors
   Units: sectors of 1 * 512 = 512 bytes
   Sector size (logical/physical): 512 bytes / 512 bytes
   I/O size (minimum/optimal): 512 bytes / 512 bytes
   Disklabel type: dos
   Disk identifier: 0x52b80fee

   Device                                                                     Boot   Start     End Sectors  Size Id Type
   openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw1         2048  133119  131072   64M  c W95
   openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw2       133120 1157119 1024000  500M 82 Linu
   openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw3      1157120 4595678 3438559  1.7G 83 Linu
   ```

   上面是 `fdisk` 的输出结果。其中，`Sector size`，也就是扇区大小，是 512 字节；第一个分区的 `Start` 下的值是 2048，意味着该分区的起始扇区的编号是 2048。扇区号是从 0 开始编的，也就是说如果一个扇区编号为 2048，那么它前面也刚好有 2048 个扇区。因此，映像开头和第一个分区的起始点之间有 512 * 2048 = 1048576 个字节，故得出该分区的偏移量为 1048576。

2. 创建一个目录。例如 `/mnt/tmp`，用作映像分区的挂载点。由于一般情况下 `/mnt` 是需要较高的权限才能写入的，因此如果您要在它下面创建挂载点的话，需要使用*超级用户权限*执行下面的命令（通常在命令前加 `sudo` 即可）。

   ```console
   # mkdir /mnt/tmp
   ```

3. 挂载映像，在挂载时指定之前算出的偏移量。这里需要注意的是，`mount` 命令一般都需要超级用户权限。

   ```console
   # mount -o loop,offset=1048576 openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw /mnt/tmp/
   ```

此时就可以在挂载点下访问引导分区的文件了，也可以将它们复制出来，挂载分区的最终目标也就达成了。

```console
$ cd /mnt/tmp
$ ls
bcm2708-rpi-b.dtb       bcm2710-rpi-3-b-plus.dtb  LICENCE.broadcom
bcm2708-rpi-b-plus.dtb  bcm2710-rpi-cm3.dtb       overlays
bcm2708-rpi-cm.dtb      bcm2711-rpi-4-b.dtb       start4.elf
bcm2708-rpi-zero.dtb    bootcode.bin              start.elf
bcm2708-rpi-zero-w.dtb  config.txt                startup.nsh
bcm2709-rpi-2-b.dtb     EFI                       u-boot.bin
bcm2710-rpi-2-b.dtb     fixup4.dat                ubootconfig.txt
bcm2710-rpi-3-b.dtb     fixup.dat
```

## 将文件复制到 Fedora SD 卡上

复制文件就很简单了，这里对文件复制的流程也没有特殊要求，只需将 openSUSE 引导分区中的所有文件和目录都复制到您安装了 Fedora 的 SD 卡上的引导分区即可。如果想使用命令来复制的话，在 SD 卡上的引导分区中运行下列命令：

```console
$ cp -rv /mnt/tmp/* .
```

此命令中的 `-r` 选项指定 `cp` 将子目录也一同复制过来；和之前一样，`-v` 选项是用来查看进度的可选选项。

截至 Fedora 32 和 Linux 5.8，openSUSE 的引导分区中有一个文件在 Fedora 上是用不了的，那就是 *U-Boot 映像* `u-boot.bin`。如果用了 openSUSE 的 U-Boot 映像的话，Fedora 是无法启动的。作为替代，您可以使用 Fedora 的 `rpi4-u-boot.bin`：先删除 openSUSE 的 `u-boot.bin`，然后将 `rpi4-u-boot.bin` 重命名为 `u-boot.bin` 即可。

如果想使用命令行的话，删除和重命名这两个操作可以只用一个命令来同时完成：

```console
$ mv {rpi4-,}u-boot.bin
```

## 修改引导配置文件

如果不修改引导配置的话，从 openSUSE 移植到 Fedora 的配置文件会尝试从无效的路径读取文件，导致系统不能启动，因此您需要修改引导配置文件，填入 Fedora 引导文件的路径。

在您的 SD 卡的引导分区下的 `EFI/BOOT/grub.cfg` 文件中，删除所有已有内容，然后粘贴下列文本。

```
set prefix=($root)/EFI/fedora
normal
```

保存文件，安全弹出 SD 卡，插入到树莓派中，然后开机。系统启动后，USB 接口就应该可以使用了。

## 清理

倘若配置没有问题的话，就可以清理您刚才临时创建的文件了。如果您之前是通过 `mount` 挂载的 openSUSE 映像，可以使用下面的命令来卸载，然后移除挂载点：

```console
# umount /mnt/tmp
# rmdir /mnt/tmp
```

## 已知问题

### Fedora 32

在 8GB 内存型号上运行 Fedora 32 时，无论您是否已经应用了上述解决方案，系统都只能使用 4 GiB 的内存。此问题是由 Fedora 32 老版本的 U-Boot 映像导致的。Fedora 33 更新了 U-Boot 映像，此问题也随之而解。

### Fedora 33

如果在启动树莓派时没有接显示器的话，Fedora 33 自带的 U-Boot 映像在启动时会卡住，必须连上显示器才能继续启动。解决方法很简单，就是在 SD 卡的启动分区内创建一个名为 `extraconfig.txt` 的文件，然后在文件中填入下面的内容：

```
hdmi_force_hotplug=1
```

可以在 SD 卡的启动分区下运行下面的命令来创建此文件：

```console
$ echo 'hdmi_force_hotplug=1' > extraconfig.txt
```

## 参考资料

这帖子基本只是将[这篇网页](http://rglinuxtech.com/?p=2768)上介绍的解决 USB 接口问题的方法详细地解释了一遍。这个方法背后的大体思路是在该网页中讲解的，但是并没有介绍具体的步骤，于是我填补了这一空白。很惭愧，就做了一点微小的工作。
