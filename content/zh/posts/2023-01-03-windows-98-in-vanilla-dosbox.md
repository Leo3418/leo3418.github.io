---
title: "在原版 DOSBox 中运行 Windows 98"
tags:
  - Windows
categories:
  - 教程
toc: true
---

作为一个 DOS 模拟器，DOSBox 理论上应该是支持运行像 Windows 3.1、95 和 98 这些基于 DOS 的 Windows 版本的。确实，在 DOSBox 官网的[兼容性列表][dosbox-comp-list]中，Windows 3.1 和 95 都被列为“支持”（supported）；但是 Windows 98 的兼容性仅被评为“[可运行][dosbox-comp-list-windows-98]”（runnable），比中间的“可游玩”（playable）还低一档。可能正因为如此，很多想运行 Windows 98 的人索性就选用了支持 Windows 98 的 DOSBox 分支项目，比如 [DOSBox-X][dosbox-x-windows-98]。

不过，我并没有放弃在原版 DOSBox 里运行 Windows 98 的尝试。如果能在 Windows 98 里运行纸牌和三维弹球等程序就可以算作“可游玩”，那么根据我的发现，只需要一点点额外的操作，就可以让 Windows 98 在原版 DOSBox 中至少达到“可游玩”的级别。因此，我决定写下这篇教程，给想在原版 DOSBox 里试一下 Windows 98 的人一个参考。

![在原版 DOSBox 中的 Windows 98 下运行纸牌]({{< static-path type=img l10n=y
file=solitaire.png >}})

![在原版 DOSBox 中的 Windows 98 下运行三维弹球]({{< static-path type=img l10n=y
file=pinball.png >}})

[dosbox-comp-list]: https://www.dosbox.com/comp_list.php?letter=W
[dosbox-comp-list-windows-98]: https://www.dosbox.com/comp_list.php?showID=3485&letter=W
[dosbox-x-windows-98]: https://dosbox-x.com/wiki/Guide%3AInstalling-Windows-98

## 要求

如果想参照此教程操作，请先确保拥有下列软件：

- Windows 平台上的 DOSBox 版本 0.74-3
  - 此教程中的安装 Windows 98 的操作步骤只在 Windows 平台的 DOSBox 上验证成功过。在像 GNU/Linux 和苹果 ARM 架构的 macOS 等其它平台上，在 DOSBox 里安装完 Windows 98 后，新装好的系统可能无法启动到桌面。不过，在 GNU/Linux 上的 DOSBox 中还是有可能*运行* Windows 98 的，只要安装流程是在 Windows 上的 DOSBox 中完成的即可。请参阅本文后面的“[非 Windows 平台][on-non-windows-platforms]”部分了解更多信息。
- 一个完整版本（而非升级版本）的 Windows 98 安装光盘 ISO 映像
  - 升级版本的 ISO *也许*可以使用，但不在本教程的讨论范围内
  - 原版（“第一版”）和第二版都可以使用
  - 零售版本和 OEM 版本都可以使用
- MS-DOS 或 Windows 9x 启动盘软盘映像
  - 本教程将使用 Windows 98 第二版启动盘进行示范；该启动盘的映像可[从 WinWorld 下载][winworldpc-boot-disk-98-se]

[winworldpc-boot-disk-98-se]: https://winworldpc.com/product/microsoft-windows-boot-disk/98-se
[on-non-windows-platforms]: {{< relref "#非-windows-平台" >}}

## 为 Windows 98 修改 DOSBox 配置

[DOSBox 的配置文件][dosbox-wiki-dosbox.conf]中必须包含下列配置选项：

```ini
[cpu]
core=dynamic
cputype=pentium_slow
cycles=max

[dosbox]
machine=svga_s3
```

- `core=dynamic` 和 `cputype=pentium_slow` 是最关键的选项，只有这样设置才能避免 Windows 98 在原版 DOSBox 中运行时出现严重错误。如果不这么设置，那么 Windows 98 在 DOSBox 中安装好后可能无法进入桌面。
  - 值得一提的是，只要 DOSBox 的动态核心处于可用状态，那么将 `core` 设定为默认的 `auto` 也是可以的。

- `cycles` 并非必须要设为 `max`，但是这样设置可以明显提升 Windows 98 在 DOSBox 中的性能，尤其是在操作系统启动阶段。`max` 会让 DOSBox 模拟的 CPU 始终以最快速度运行。而默认的 `auto` 选项，一开始只会以更为缓慢的每毫秒 3000 周期的速度进行模拟，直到 Windows 98 启动之后才会自动上调至最快速度，就会导致 Windows 98 在此选项下启动时间变长很多。

- `machine=svga_s3`（也是默认设置）在 Windows 9x 下能够提供很好的图形体验与性能。Windows 可以为其自动安装显卡驱动，支持 800 × 600 屏幕分辨率下的 32 位真彩色。其它的选项也许也能使用，但不在本教程的讨论范围内。

[dosbox-wiki-dosbox.conf]: https://www.dosbox.com/wiki/Dosbox.conf

## 准备硬盘映像

如果想在 DOSBox 下运行 Windows 98，就必须使用可启动的硬盘映像。Windows 98 的启动流程依赖于其基于 MS-DOS 7.1 的引导程序，而引导程序必须安装到硬盘的 MBR 里面。在 DOSBox 中，能提供 MBR 功能的只有可启动硬盘映像。

此教程假设硬盘映像上只会有一个主分区。创建并使用额外的分区也许是可行的，但不在此教程的讨论范围内。

### 文件系统：FAT16 与 FAT32

除非使用外部工具，否则硬盘映像上的分区*最开始*必须使用 FAT16 格式化。等 Windows 98 安装完成后，可以再将分区转换成 FAT32。

在安装 Windows 98 前，必须将安装文件从 Windows 98 安装光盘上的 `Win98` 文件夹复制到硬盘映像中。这是因为在原版 DOSBox 中，没有已知办法可以在有 CD-ROM 支持的情况下启动 Windows 98 安装程序，所以在安装过程中就没法从安装光盘 ISO 读取安装文件，因此安装文件必须提前复制到硬盘映像上。

**只有**在硬盘映像上的文件系统是 FAT16 时，才能使用 DOSBox 将安装文件复制到硬盘映像。DOSBox 0.74-3 版本在向 FAT32 分区写入文件时会出现问题。

如果使用其它工具将安装文件复制到硬盘映像，并且该工具支持 FAT32 的话，那么最开始就可以在硬盘映像上使用 FAT32。不过，其它工具的使用不在此教程的讨论范围内。

### 映像的大小

为确保有充足空间安装 Windows 98 并存放安装文件，建议硬盘映像的容量至少有 0.5 GiB。

同时，硬盘映像的大小不应该超过 2 GiB。DOSBox 0.74-3 版本在从大于 2 GiB 的硬盘映像启动时会遇到问题。尽管超过此上限的映像看起来能挂载成功，但一旦在 DOSBox 中启动一个操作系统，挂载的虚拟硬盘就会消失。

### 获取映像

原版 DOSBox 并没有创建硬盘映像的功能，因此用户要么直接下载其他人创建的现成的映像来用，要么就需要使用其它工具来自己创建映像。

vogons.org 上有一位叫 DosFreak 的用户[上传过][pre-created-hdd-imgs]一个已经创建好的 2 GiB 大小、有个单一 FAT16 分区的硬盘映像，可直接[下载][pre-created-2gib-fat16-img]使用。该映像的[规格][wikipedia-chs]如下：
- 柱面数量：1023
- 磁头数量：64
- 扇区数量：63

想自行创建映像的用户可使用诸如 [DOSBox-X][dosbox-x-create-hdd-img] 的工具来完成此任务。例如，在 DOSBox-X 中运行以下命令将在宿主机上的 `D:\hdd.img` 路径下创建一个 2 GiB 的 FAT16 映像：

```
imgmake D:\hdd.img -t hd_2gig -fat 16
```

使用此类工具创建映像时，请记下工具报告的新映像的柱面-磁头-扇区（CHS）规格参数（如下图所示）。后面的步骤会用到硬盘映像的规格参数。

![DOSBox-X 报告的新映像的 CHS 参数]({{< static-path img
dosbox-x-imgmake.png >}})

[pre-created-hdd-imgs]: https://www.vogons.org/viewtopic.php?t=17324#post-123503-attachments-title
[pre-created-2gib-fat16-img]: https://www.vogons.org/download/file.php?id=9430
[dosbox-x-create-hdd-img]: https://dosbox-x.com/wiki/Guide%3AManaging-image-files-in-DOSBox%E2%80%90X#_creating_harddisk_images
[wikipedia-chs]: https://zh.wikipedia.org/wiki/%E6%9F%B1%E9%9D%A2-%E7%A3%81%E5%A4%B4-%E6%89%87%E5%8C%BA

## 复制 Windows 98 安装文件

正如[上文提到][fs-fat16-vs-fat32]，Windows 98 的安装文件必须复制到硬盘映像上。为避免不必要地要求使用额外的工具，下面的流程将只依赖原版 DOSBox 来完成文件的复制，因此也假设硬盘映像上的文件系统是 FAT16。如果要使用其它工具复制安装文件的话，请忽略以下流程，然后根据该工具的使用方法进行相应的操作。

启动 DOSBox，然后在模拟 DOS 中运行下列命令：

1. 挂载硬盘映像和 Windows 98 安装光盘 ISO。请将 `D:\hdd.img` 和 `D:\win98.iso` 分别改为硬盘映像和 ISO 的实际路径。

   ```
   imgmount C D:\hdd.img
   imgmount D D:\win98.iso -t iso
   ```

2. 在硬盘映像上创建一个目录，用于存放 Windows 98 安装文件，然后进入该目录。以下命令使用 `Win98` 作为该目录的名称进行示范。

   ```
   C:
   mkdir Win98
   cd Win98
   ```

3. 开始将安装文件从 ISO 上的 `Win98` 文件夹中复制出来。需要注意的是，在复制文件时，DOSBox 会卡住、无响应一段时间——这是正常现象。等待复制完成即可。

   ```
   copy D:\Win98
   ```

4. 卸载刚才挂载的两个映像。

   ```
   imgmount -u C
   imgmount -u D
   ```

[fs-fat16-vs-fat32]: {{< relref "#文件系统fat16-与-fat32" >}}

## 安装 Windows 98

当硬盘映像和 Windows 98 安装文件都已就绪后，就可以开始安装流程了。

1. 在 DOSBox 中，将硬盘映像挂载为可启动硬盘。挂载命令的格式如下：

   ```
   {{% imgmount-2.inline %}}imgmount 2 <映像路径> -fs none -size <扇区大小>,<扇区数量>,<磁头数量>,<柱面数量>{{%/ imgmount-2.inline %}}
   ```

   扇区大小一般都是 512 字节。扇区数量、磁头数量和柱面数量则是由硬盘映像的 CHS 规格决定。例如，如果使用的硬盘映像是上文给出的已经创建好的映像，那么挂载映像的 DOSBox 命令如下：

   ```
   imgmount 2 2GB.img -fs none -size 512,63,64,1023
   ```

2. 从 MS-DOS 或 Windows 9x 启动盘映像引导。请将 `D:\bootdisk.img` 改为启动盘映像的实际路径。

   ```
   boot D:\bootdisk.img
   ```

   这一步是必需的，因为 Windows 98 安装程序依赖于启动盘提供的环境。如果直接从 DOSBox 下启动安装程序的话，就会出现 SU-0013 错误。

   ![从 DOSBox 直接启动安装程序时出现的错误信息]({{<
   static-path type=img l10n=y file=setup-on-emulated-dos.png >}})

3. 如果启动盘提供了在启动时加载 CD-ROM 驱动的选项（“Start computer with CD-ROM support”），请**不要**选择它。相反，请选择**不加载** CD-ROM 驱动的选项（“Start computer **without** CD-ROM support”）。

   ![选择不带 CD-ROM 支持，从 Windows 98 启动盘启动]({{< static-path
   img bootdisk-without-cdrom.png >}})

   如果选择加载 CD-ROM 驱动的选项，加载驱动时将出现错误，导致 DOSBox 中的系统停止运行。

   ![带 CD-ROMError when booting with CD-ROM support]({{< static-path img
   bootdisk-with-cdrom-error.png >}})

4. 进入存放 Windows 98 安装文件的目录。

   ```
   C:
   cd Win98
   ```

5. 如果要安装的是 Windows 98 第二版、并且安装文件是用 DOSBox 复制到硬盘映像上的话，那么建议在运行安装程序前，先手动运行一遍 ScanDisk，以自动修复 DOSBox 在复制文件时造成的文件系统错误：

   ```
   scandisk /autofix
   ```

   当 ScanDisk 提示创建撤销磁盘（Create Undo Disk）时，选择“Skip Undo”以跳过。由于此时硬盘映像上应该只有 Windows 98 安装文件，因此没有重要文件需要保存，也就没有必要创建撤销磁盘。

   ![在 ScanDisk 提示时跳过撤销磁盘]({{< static-path img scandisk-skip-undo.png
   >}})

   ScanDisk 运行完成时，会报告其检测到的和修复的问题：

   ![ScanDisk 报告其修复的问题]({{< static-path img scandisk-success.png
   >}})

   虽然 Windows 98 安装程序也能运行 ScanDisk，但是这种情况下运行的 ScanDisk **每**检测到一个问题都会询问是否修复，并且也不提供一个“修复全部问题”的选项，也就意味着要手动选六十多次“修复”。使用 `/autofix` 选项手动提前运行一次 ScanDisk 就可以避免这种情况。

   ![ScanDisk 每检测到一个问题，都要询问是否修复]({{< static-path
   img setup-scandisk-problem.png >}})

6. 启动 Windows 98 安装程序，并完成第一阶段的安装。

   ```
   setup
   ```

   ![Windows 98 安装程序在 DOSBox 中启动]({{< static-path type=img l10n=y
   file=setup-welcome.png >}})

   这部分的安装在 DOSBox 中和在实体机或虚拟机上基本无异。有几点值得留意：

   1. 如果硬盘映像上的文件系统是 FAT16，那么在进行到“Windows 组件”步骤时，推荐添加*系统工具*下的*驱动器转换器 (FAT32)* 组件，以在 Windows 98 安装完成后将文件系统转换为 FAT32。

      1. 出现提示时，选择“显示组件列表，以便进行选择”。

         ![选择调整 Windows 98 组件]({{< static-path type=img l10n=y
         file=setup-components-custom.png >}})

      2. 在左侧选择“系统工具”，然后单击右侧的“详细资料”按钮。

         ![选择“系统工具”]({{< static-path type=img l10n=y
         file=setup-components-sys-tools.png >}})

      3. 确保“驱动器转换器 (FAT32)”选项的复选框处于选定状态，然后单击“确定”。

         ![选定“驱动器转换器 (FAT32)”]({{< static-path type=img l10n=y
         file=setup-components-drv-converter.png >}})

   2. 在进行到“启动盘”步骤时，选择略过制作启动盘。

      ![略过制作启动盘]({{< static-path type=img l10n=y
      file=setup-startup-disk-cancel.png >}})

      即使选择创建启动盘，此时在 DOSBox 中也无法创建，因为会出现“磁盘格式化错误”：

      ![无法创建启动盘]({{< static-path type=img l10n=y
      file=setup-startup-disk-error.png >}})

7. 第一阶段的安装完成后，安装程序会进行重启，DOSBox 也会相应地退出。重新启动 DOSBox，然后再次将磁盘映像挂载为可启动硬盘：

   ```
   {{% imgmount-2.inline /%}}
   ```

   然后，从硬盘映像启动，继续安装：

   ```
   {{% boot-c.inline %}}boot -l C{{%/ boot-c.inline %}}
   ```

   ![Windows 98 首次启动]({{< static-path type=img l10n=y
   file=setup-firstboot.png >}})

   这部分的安装流程同样很简明；唯一的特殊点就是，如果正在安装 Windows 98 第二版，那么在本阶段结束前，会出现 Rundll32 “执行了非法操作”的报错。该错误可直接忽略。

   ![安装过程中出现的 Rundll32 “执行了非法操作”的报错]({{< static-path
   type=img l10n=y file=setup-rundll32-error.png >}})

   当安装程序再次重启计算机时，DOSBox 可能会停在“Windows 正在关机”屏幕不动。这是正常现象：Windows 98 通过发送 [APM][wikipedia-apm] 事件进行重启，但原版 DOSBox 不支持 APM，无法处理该事件，导致此现象。等待约 5 秒钟，然后手动关闭 DOSBox 即可。

   [wikipedia-apm]: https://zh.wikipedia.org/wiki/%E9%AB%98%E7%BA%A7%E7%94%B5%E6%BA%90%E7%AE%A1%E7%90%86

   ![DOSBox 停在 Windows 98 关机界面]({{< static-path type=img
   l10n=y file=setup-stuck-at-shutdown.png >}})

8. 重启 DOSBox，再次挂载硬盘映像然后启动：

   ```
   {{% imgmount-2.inline /%}}
   {{% boot-c.inline /%}}
   ```

   如果安装的是 Windows 98 第二版，那么 Rundll32 “执行了非法操作”的报错可能会再次出现三次，同样都可以忽略。

   ![安装完成后出现的 Rundll32 “执行了非法操作”的报错]({{< static-path
   type=img l10n=y file=oobe-rundll32-error.png >}})

   当“欢迎进入 Windows 98”窗口出现时，安装过程就完成了。

   ![“欢迎进入 Windows 98”窗口]({{< static-path type=img l10n=y
   file=oobe-welcome.png >}})

## 启动 Windows 98

安装完成后，启动 Windows 98 的 DOSBox 命令和安装过程中使用的相应的命令是一样的：

```
{{% imgmount-2.inline /%}}
{{% boot-c.inline /%}}
```

如果不想每次都手动输入这些命令的话，可以将它们添加到 DOSBox 配置文件的 `[autoexec]` 部分。例如，将以下内容添加到配置文件，就不仅能让 DOSBox 每次启动后自动运行这些命令，还将 `imgmount` 参数提取成变量，便于日后理解和修改。

```ini
[autoexec]

set BOOT_IMAGE=D:\hdd.img
set SECTOR_SIZE=512
set SECTORS=63
set HEADS=64
set CYLINDERS=1023

imgmount 2 "%BOOT_IMAGE%" -fs none -size %SECTOR_SIZE%,%SECTORS%,%HEADS%,%CYLINDERS%
{{% boot-c.inline /%}}
```

## 可选步骤：将文件系统转换为 FAT32

Windows 98 安装好后，硬盘映像上的文件系统就可以转换为 FAT32 了，不会影响在原生 DOSBox 中启动安装在映像上的 Windows 98 的能力。因为 `imgmount` 命令中的 `-fs none` 参数会让 DOSBox 只给硬盘映像创建一个虚拟硬盘，而不尝试读取并挂载映像上面的文件系统，所以可以开始使用原生 DOSBox 不支持的文件系统了。

从功能角度来讲，继续使用 FAT16 并没有不足，所以转换操作是可选的。但是，转换至 FAT32 可增加可用的磁盘空间。对于一个存有一份新的 Windows 98 系统外加安装文件的分区，转换文件系统可增加约 60 MB 的可用空间。

![转换为 FAT32 前的磁盘使用情况]({{< static-path type=img l10n=y
file=du-fat16.png >}})

![转换为 FAT32 后的磁盘使用情况]({{< static-path type=img l10n=y
file=du-fat32.png >}})

如果要转换文件系统，在开始菜单中，打开*程序* > *附件* > *系统工具* > *驱动器转换器 (FAT32)*，然后根据驱动器转换器向导的提示进行操作。

![启动驱动器转换器]({{< static-path type=img l10n=y
file=drv-converter-launch.png >}})

## 非 Windows 平台

如果运行 DOSBox 的宿主平台不是 Windows，那么 Windows 98 在原版 DOSBox 中出现的问题一般比宿主平台是 Windows 时要多。对于使用非 Windows 平台的用户，建议要么改为选择在原版 DOSBox 中安装 Windows 95，要么换用对 Windows 98 支持更好的 DOSBox 分支版本。如果还是想在非 Windows 平台上尝试在原版 DOSBox 中运行 Windows 98，请仔细阅读此部分的内容。

### 必需的额外 DOSBox 配置

在像 GNU/Linux 和 macOS 的非 Windows 平台上，除了本文中[前述][dosbox-config-for-windows-98]的 DOSBox 配置外，**还**需要以下额外配置：

```ini
[serial]
serial1=disabled
serial2=disabled
```

`serial1` 和 `serial2` 默认被设为 `dummy`，在上述平台上会导致 Windows 98 在原版 DOSBox 中启动时卡在黑屏。

[dosbox-config-for-windows-98]: {{< relref "#为-windows-98-修改-dosbox-配置" >}}

### 先在 Windows 上安装，再拿到别处运行

想在非 Windows 平台（包括但不限于 GNU/Linux）上的 DOSBox 中运行 Windows 98 的用户，应先在 Windows 上的 DOSBox 中安装 Windows 98，并**确保系统已经启动到桌面过一次**，然后再将硬盘映像复制到非 Windows 环境，以在该环境下的 DOSBox 中运行 Windows 98。

如果在非 Windows 平台上的原版 DOSBox 中安装了 Windows 98，那么系统在完成了安装程序，首次启动到桌面的时候，可能会完全卡住，无任何响应。只要系统已经启动到桌面一次了，Windows 98 就*可能*可以正常开机，不再出现卡住无响应的情况了。而根据我的测试，只有在 Windows 上的原版 DOSBox 中才能正常完成首次启动、加载出桌面。

### 有关特定平台的说明

#### Fedora

Fedora 官方已经不再维护 DOSBox 软件包，改为提供 [DOSBox Staging][dosbox-staging] 了，但我还是可以在 Fedora 37 上安装并运行官方为 Fedora 34 提供的[最后一次][fedora-vanilla-dosbox-last]原版 DOSBox 构建。只要系统已经启动到桌面过一次，就可在 Fedora 37 上，使用该 DOSBox 构建，正常运行该系统，没有明显的问题。

[dosbox-staging]: https://dosbox-staging.github.io/
[fedora-vanilla-dosbox-last]: https://koji.fedoraproject.org/koji/buildinfo?buildID=1676070

#### Gentoo

在使用 [`games-emulation/dosbox-0.74.3`][gentoo-dosbox-stable] 的情况下，即使系统已经启动到桌面过一次，Windows 98 还是会在开机运行几分钟后卡住无响应，基本无法使用。

因此，建议想在 DOS 模拟器中运行 Windows 98 的 Gentoo 用户改用其它 DOSBox 分支版本。我个人在 Gentoo 上使用的是 DOSBox-X，在其中运行 Windows 98 已经有一段时间了，稳定性很不错。目前 Gentoo 上还没有官方的 DOSBox-X 软件包，所以我为 DOSBox-X 自己编写并维护了 ebuild。DOSBox-X 的 ebuild `games-emulation/dosbox-x` 现在[位于 GURU][guru-dosbox-x]，欢迎感兴趣的 Gentoo 用户尝试。

[gentoo-dosbox-stable]: https://gitweb.gentoo.org/repo/gentoo.git/tree/games-emulation/dosbox/dosbox-0.74.3.ebuild
[guru-dosbox-x]: https://gitweb.gentoo.org/repo/proj/guru.git/tree/games-emulation/dosbox-x

#### 苹果 ARM 芯片上的 macOS

在 macOS 13.1 和 DOSBox 0.74-3-3 下，无论系统有没有启动到桌面过，Windows 98 都会弹出各种进程“执行了非法操作”的错误，包括 Explorer，有时甚至会蓝屏，导致完全无法使用。

## 已知问题

除了上述的已知在非 Windows 平台上的 DOSBox 中运行 Windows 98 时会出现的问题外，此部分还包括一些即使是在 Windows 上的 DOSBox 中也会出现的已知问题。

### DOSBox 在 Windows 98 关机后不退出

在 Windows 98 中从开始菜单关机后，DOSBox 的输出画面会显示“现在可以安全地关闭计算机了”，并且会一直停在该画面不动：

![Windows 98 关机后在 DOSBox 中显示的信息]({{< static-path
type=img l10n=y file=shutdown-complete.png >}})

此现象同样是因为 Windows 98 通过发送 APM 事件关机，而 DOSBox 不支持 APM，不会自动退出，就会显示此屏幕。

DOSBox 需要被手动关闭。只要出现上面的屏幕画面，就可以安全关闭 DOSBox。

### Microsoft Return of Arcade 游戏声音异常

Microsoft Return of Arcade 中的游戏的声音可能无法在 DOSBox 中的 Windows 98 下正常播放。建议的解决办法包括：

- 关闭这些游戏的声音。
- 在原版 DOSBox 中的 Windows 95 下安装并运行受影响的游戏，即可正常播放游戏声音。
- 在 DOSBox-X 中的 Windows 98 下安装并运行受影响的游戏，即可正常播放游戏声音。

## 参考资料

- [Windows 9x DOSBox 指南][refs-windows-9x-dosbox-guide]，来自 vogons.org 用户 DosFreak

[refs-windows-9x-dosbox-guide]: https://www.vogons.org/viewtopic.php?t=17324
