---
title: "精简 Linux 内核配置"
tags:
  - GNU/Linux
  - Gentoo
categories:
  - 教程
toc: true
---

大部分青睐于自己编译内核的 Linux 用户想必都不会拒绝缩短内核编译耗时且减少内核及模块占用的硬盘空间的机会。常见的做法是精简内核配置，即在编译内核时关闭用户不需要的配置选项：无论是用不到的软件功能，还是用户未拥有的硬件的驱动，都可以在内核配置中关闭。例如，用不到 WireGuard 的用户就可以关闭对应的选项；没有 AMD 独立显卡或者带集成显卡的 AMD CPU 的用户就可以关闭 `amdgpu` 驱动的选项。

自己编译内核的用户，想必绝大多数是 Gentoo 用户，毕竟 Gentoo 的一大特色是用户可以轻松地本机编译软件包。因此，Gentoo 用户经常提到的问题之一就是精简内核配置。本文的目的即是就此问题为此类用户提供教程。

话虽如此，笔者认为其它 GNU/Linux 发行版的用户也可以参考此教程，不过笔者并未在其它发行版上验证过此教程的内容。并且，其它发行版的用户也许根本就不需要这样一篇教程，尤其是对于没自己编译过软件包的用户而言。

## 效果

精简内核配置一般可将内核编译耗时和模块的硬盘空间占用各自缩减至少一半；具体的缩减规模取决于精简的程度。笔者在 Linux 6.18.2 上成功将编译耗时从大约 13 分钟缩减到 6 分钟以内，并将模块的大小从 832 MiB 减少到 164 MiB:

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

## 要求

除非另行声明，否则以下步骤皆应在**将运行精简后的内核的机器**上进行。

## 安装编译内核的工具

Gentoo 用户可直接跳过此步，因为 Gentoo 默认会安装所有编译内核的工具。

在大部分 Gentoo 以外的发行版上编译内核前，都需要先安装编译内核的工具。具体的步骤，可参考以下资源：

- [Linux 内核文档（英文内容）](https://docs.kernel.org/admin-guide/quickly-build-trimmed-linux.html#install-build-requirements)
- 一些发行版就编译内核有相关文档，例如：
  - [Arch Linux](https://wiki.archlinuxcn.org/wiki/%E5%86%85%E6%A0%B8#%E7%BC%96%E8%AF%91)
  - [Debian（英文内容）](https://kernel-team.pages.debian.net/kernel-handbook/)
  - [Fedora（英文内容）](https://docs.fedoraproject.org/zh_CN/quick-docs/kernel-build-custom/)

## 安装、启动通用内核

**通用内核**指的是兼容各种硬件与软件、可运行于许多不同配置的电脑的内核。

对于几乎所有 GNU/Linux 发行版而言，发行版的默认内核就是通用内核，因此用户可以直接选用。

Gentoo 用户可以使用 `sys-kernel/gentoo-kernel-bin`；这是 Gentoo 预编译的发行版内核，可作为通用内核使用：
```console
# emerge --ask --noreplace --oneshot sys-kernel/gentoo-kernel-bin
```

配置了安全启动（Secure Boot）的用户，还应向安全启动配置导入 Gentoo 发行版内核的签名密钥，以允许电脑引导发行版内核。签名密钥的位置是 `/usr/src/linux-[release]-gentoo-dist/certs/signing_key.x509`。使用 `sys-boot/shim` 实现安全启动的用户可使用以下命令导入密钥，将 `[version]` 替换为实际的内核版本：
```console
# mokutil --import /usr/src/linux-[version]-gentoo-dist/certs/signing_key.x509
```

安装好后，重启进入通用内核，以执行后续的操作。

## 插入、启用设备，越多越好

接入越多越好的设备的目的，是尽量让内核加载所有用户需要用到的模块。正常情况下，用户接入设备后，系统会自动加载该设备所需的内核模块。由于在后续步骤中生成精简内核配置时，会自动启用已加载的模块、并自动禁用未加载的模块，因此现在加载需要用到的模块，就可以保证后面生成内核配置时，能自动启用这些用户需要的模块。这样一来，用户得到的内核配置就能既与用户的所有设备兼容，又精简掉不需要的选项。

笔者会插入及启用下列类型的设备：

- USB 设备：外设、外接硬盘、转接头等
- 无线连接芯片，例如 Wi-Fi、蓝牙，并连接 Wi-Fi 网络和蓝牙设备等
- 外接显示器
- SD 卡（如果电脑自带 SD 卡槽）
- 对于笔记本设备，如果有摄像头或麦克风的隐私开关：确保开关处于未激活状态，允许系统访问并使用摄像头和麦克风

接入一台设备后，等到系统辨认并加载完该设备后，一般就可以断开设备的连接了，无需让设备一直保持连接状态。这是因为，在断开设备时，系统通常是不会自动卸载与该设备相关的内核模块的。

## 下载、解压内核源码

此步骤要达到的目的，是能够在一份本地内核源码树中运行 `make` 命令，以调用内核构建系统。内核源码的版本应与用户想使用的内核版本一致。

下载内核源码的渠道有很多：

- 从 [kernel.org](https://kernel.org/) 下载 tar 压缩包（tarball）。

- 将包含内核源码的 Git 仓库克隆到本地。在克隆仓库时，强烈建议用户在 `git clone` 命令中使用 `--depth 1` 选项，以避免不必要地下载内核庞大的 Git 提交历史。

  例如，下列命令从 [Linux 内核的官方 Git 仓库][git.kernel.org-stable] 克隆 Linux 6.18.2 的源码：
  ```console
  $ git clone --branch v6.18.2 --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
  ```

- Gentoo 用户可使用 Portage 获取内核源码：选择并安装合适的 `sys-kernel/*-sources` 软件包即可。以此法安装的源码会被置于 `/usr/src` 目录下。
  - 安装了[发行版内核][gentoo-wiki-dist-kernel]（`sys-kernel/*-kernel` 以及 `sys-kernel/gentoo-kernel-bin`）的用户应注意，不要使用发行版内核在 `/usr/src` 下安装的内核源码，而是应该使用以其它方式获取的源码。这是因为发行版内核安装的源码并不完整，不支持运行内核构建系统。

[git.kernel.org-stable]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/
[gentoo-wiki-dist-kernel]: https://wiki.gentoo.org/wiki/Distribution_Kernel#Current_packages

下载并解压完内核源码后，进入内核源码目录，以执行后续的操作。

## 生成精简内核配置

此步骤最关键的部分，是使用内核构建系统的 `localmodconfig` Make 目标来精简内核配置。`localmodconfig` 会遍历当前运行的内核所附带的模块，然后自动禁用其中未加载的模块。

1. 提取当前运行的内核的配置，作为精简配置的起点（“种子”配置）。

   部分发行版的内核会将自身的配置映射至 `/proc/config.gz` 文件中。这种情况下，可使用如下命令创建种子配置：
   ```console
   $ zcat /proc/config.gz > config-seed
   ```

   如果没有 `/proc/config.gz` 文件，部分发行版会将内核配置安装至 `/boot/config-[内核版本]`，因此也可以检查该路径：
   ```console
   $ cp "/boot/config-$(uname -r)" config-seed
   ```

2. 用种子配置初始化 `.config` 文件。内核构建系统将 `.config` 文件用作内核配置。
   ```console
   $ cp config-seed .config
   ```

3. 生成精简内核配置。
   ```console
   $ yes '' | make localmodconfig
   ```
   `yes ''` 的作用是将 `.config` 中未设定的配置选项都设为默认值。`make localmodconfig` 会检查 `.config` 中启用的内核模块，然后禁用当前未加载的模块。

4. 将 `make localmodconfig` 刚关闭的配置选项汇总至新的**配置片段**文件中。配置片段可以让后续的步骤更容易。以下命令将创建名为 `localmod-all.config` 的配置片段：
   ```console
   $ scripts/diffconfig -m config-seed .config > localmod-all.config
   ```

   配置片段的内容如下所示：
   ```
   # CONFIG_6LOWPAN is not set
   # CONFIG_8139CP is not set
   # CONFIG_8139TOO is not set
   ...
   ```

## 重新启用关键配置选项

刚刚的步骤关闭了未加载的模块的配置选项。然而，**并非所有未加载的模块都不重要**。例如，提供 exFAT 文件系统支持的 `exfat` 模块，在用户还未挂载任何 exFAT 卷时可能就处于未加载的状态；这种情况下，`make localmodconfig` 就会关闭 `exfat` 模块的选项。但是，当用户之后需要使用 exFAT 卷时，如果精简的内核没有 `exfat` 模块，该卷就无法挂载。因此，为了避免系统缺少关键功能，应重新启用日后可能需要的配置选项。

为方便后续步骤，建议将刚才创建的配置片段复制一份，然后编辑复制出来的新文件来重新启用关键配置选项，就不会影响原来的配置片段。可使用以下命令复制刚才的配置片段：
```console
$ cp localmod-all.config localmod-select.config
```

复制出来的新文件的名称为 `localmod-select.config`。打开该文件，检视其关闭的内核选项，然后删除应重新启用的选项所对应的 `# [选项名称] is not set` 字符串。

具体应该重新启用哪些选项，取决于用户的实际需求，但是笔者建议所有用户至少重新启用匹配以下正则表达式的选项：

- 文件系统：`CONFIG_.*_FS`
- 加密算法，对数据安全尤为关键：`CONFIG_CRYPTO_.*`
- 人体学输入设备（HID）支持，以支持常见的外设：`CONFIG_HID_.*`
- USB 支持：
  - `CONFIG_USB_.*`
  - `CONFIG_SND_USB_.*`
  - `CONFIG_TYPEC_.*_ALTMODE` -- 如果设备有支持*替代模式*的 USB-C 接口，如支持视频输出、雷电（Thunderbolt）的 USB-C 接口
  - `CONFIG_USB4_NET` -- 如果设备有支持 USB4 或雷电的接口
- SD/MMC 卡：
  - `CONFIG_MMC`
  - `CONFIG_MMC_BLOCK`
- 蓝牙：`CONFIG_BT_HIDP`
- 摄像头：
  - `CONFIG_I2C_MUX`
  - `CONFIG_MEDIA_SUPPORT`
- 网络：
  - `CONFIG_NET_SCH_.*`
  - `CONFIG_TCP_CONG_.*`
  - `CONFIG_TUN`
- 防火墙：
  - `CONFIG_IP_SET`
  - `CONFIG_IP_NF_TARGET_.*`
  - `CONFIG_NETFILTER_.*`
  - `CONFIG_NF_.*`
  - `CONFIG_NFT_.*`
  - `CONFIG_IP6_NF_TARGET_.*` -- 如果需要 IPv6 支持

如果需要搜索被关闭的选项，可运行下列命令，将 `[模式]` 替换为要搜索的正则表达式。`grep` 命令的 `-n` 选项让 `grep` 输出每条结果在文件中的行数，方便在配置片段中快速找到每一行的位置：
```console
$ grep -n '[模式] is not set' localmod-select.config
```

例如：
```console
$ grep -n 'CONFIG_.*_FS is not set' localmod-select.config
```

如果不确定是否应该重新启用某选项，可参考以下资源来决定：

- 在如下网站上搜索该选项的名称，了解该选项的作用：
  - [kernelconfig.io](https://www.kernelconfig.io/index.html)；不过，笔者注意到，该网站有时显示不出来一些配置选项的信息
  - [Linux 内核驱动数据库](https://cateee.net/lkddb/web-lkddb/)；信息很全，但搜索功能略逊一筹
  - 任意搜索引擎

- 检查是否有软件包依赖该选项。如果有，建议启用该选项，尤其是如果依赖该选项的软件包还是用户需要使用的。通过在 Gentoo ebuild 仓库中搜索 ebuild 内容，可以轻松查找依赖某一配置选项的软件包：

  1. Gentoo 用户可以直接切换到系统上的 Gentoo ebuild 仓库路径：
     ```console
     $ cd /var/db/repos/gentoo
     ```

     其它发行版的用户可以用 Git 克隆该仓库：
     ```console
     $ git clone --depth 1 https://anongit.gentoo.org/git/repo/gentoo.git
     $ cd gentoo
     ```
  2. 使用下列命令，查找是否有软件包依赖该选项。如果该命令输出了任何内容，说明有软件包依赖该选项；否则，没有已知的软件包依赖该选项。
     ```console
     $ grep -nrsw [去掉 'CONFIG_' 前缀的选项名称]
     ```

     例如，若要搜索是否有软件包依赖 `CONFIG_BT_HIDP` 选项：
     ```console
     $ grep -nrsw BT_HIDP
     ```

## 构建、安装精简内核

重新启用了关键配置选项后，就可以开始编译精简内核了。

1. 运行下列命令，生成新的精简配置。新的配置会禁用未加载的模块，但重新打开刚刚用户选择重新启用的选项：
   ```console
   $ scripts/kconfig/merge_config.sh -m -r config-seed localmod-select.config
   ```

2. 为避免稍后安装精简内核时，当前运行的内核的文件被精简内核的文件覆盖，用户应将精简配置的 `CONFIG_LOCALVERSION` 选项设定为不同的值：
   ```console
   $ echo 'CONFIG_LOCALVERSION="-localmod"' >> .config
   ```

   这样一来，精简内核的文件将会和当前运行的内核的文件有不同的文件名。如果不设定该选项的值，并且精简内核出现故障无法启动，系统就将无法使用，因为可以正常工作的内核已经被精简内核覆盖。**用户应确保系统上无论何时都有至少一个正常工作的内核。**

3. 编译内核与模块：
   ```console
   $ make -j "$(nproc)"
   ```

   如果编译结束时提示有错误，再运行一次上述命令，以减少输出的信息量，方便查找详细的错误信息。一般而言，用户可能遇到类似于如下例子的错误信息，提到与 `certs/signing_key.x509` 相关的错误：

   ```
   make[3]: *** No rule to make target '/var/tmp/portage/sys-kernel/gentoo-kernel-6.18.2/temp/kernel_key.pem', needed by 'certs/signing_key.x509'.  Stop.
   make[2]: *** [scripts/Makefile.build:556: certs] Error 2
   make[2]: *** Waiting for unfinished jobs....
   make[1]: *** [Makefile:2010: .] Error 2
   make: *** [Makefile:248: __sub-make] Error 2
   ```

   造成该错误的原因是内核配置启用了模块签名，但内核构建系统找不到配置中指定的模块签名密钥。若要解决该错误，只需将模块签名密钥文件名重设为默认值，以让内核构建系统生成新的密钥：
   ```console
   $ echo 'CONFIG_MODULE_SIG_KEY="certs/signing_key.pem"' >> .config
   $ make -j "$(nproc)"
   ```

4. 安装模块：
   ```console
   # make INSTALL_MOD_STRIP="--strip-unneeded" modules_install
   ```

   `INSTALL_MOD_STRIP="--strip-unneeded"` 用于剪裁模块的二进制文件，以节省硬盘空间。

5. 安装内核：
   ```console
   # make install
   ```

6. 如果启用了安全启动，用户应对刚安装的精简内核进行签名，以确保系统固件允许启动该内核。精简内核的版本字符串以 `-localmod` 字样结尾，可用于区分。

7. 重启进入精简内核，确保其能正常启动。精简内核的版本字符串以 `-localmod` 字样结尾，可用于区分。如果内核无法启动，则重启进入能正常工作的内核，然后对精简内核进行必要的调整以解决问题。

## 测试精简内核

确认精简内核能启动后，应验证系统功能是否正常。用户可测试一些日常电脑使用流程，例如：

- 启动、测试依赖特定内核配置选项的程序，例如：
  - 网络相关工具：防火墙、VPN 程序……
  - 虚拟化程序：容器引擎、模拟器、虚拟机……

- 接入并测试设备，例如：
  - 扬声器、麦克风、耳机
  - USB 设备
  - Wi-Fi、蓝牙、各类无线设备
  - 外接显示器，尤其是对于支持 USB-C 视频输出的笔记本
  - SD 卡
  - 笔记本摄像头

如果发现了任何问题，`dmesg` 输出的信息往往对排查问题有帮助。

如果关闭某一内核配置选项导致任何功能出现了异常，则应在 `localmod-select.config` 文件中删除该选项对应的行，以重新启用该选项，然后重新从头执行上一小节中的步骤，以重新编译精简内核。

如果所有需要的内核功能都正常工作，那么内核配置精简就此大功告成了！

## 维护

成功精简内核配置后，可再执行几项收尾操作，以方便日后更新内核时沿用精简后的配置。

### 为重新启用的模块创建配置片段

用户完善 `localmod-select.config` 中的配置后，可将重新启用的配置选项提取到新的配置片段文件中：
```console
$ scripts/diffconfig -m localmod-select.config localmod-all.config | sed 's/^# \(CONFIG_.*\) is not set$/\1=m/' > re-enabled-modules.config
```

新的配置片段名为 `re-enabled-modules.config`。日后想为新内核版本创建精简配置时，只需执行以下步骤：

1. 参照[“生成精简内核配置”]({{% relref
   "#生成精简内核配置" %}})小节的指示，重新用 `make localmodconfig` 生成新配置，然后重新创建 `localmod-all.config` 文件。

2. 运行以下命令：
   ```console
   $ scripts/kconfig/merge_config.sh -m -r config-seed localmod-all.config re-enabled-modules.config
   ```

   使用此命令，就无需再手动检查 `localmod-all.config` 中的内容、重新启用关键选项了，除非用户想精简新版内核中新增的配置选项。

### 为摄像头生成配置片段

用户可选择专为摄像头需要的配置选项生成配置片段，这样日后生成新的精简内核配置时，使用该配置片段，就不需要再担心忘记关闭隐私开关了。

1. 使用隐私开关禁用摄像头，让系统无法访问摄像头。

2. 重启进入通用内核。

3. 为禁用摄像头的情形生成内核配置：
   ```console
   $ cp config-seed .config
   $ yes '' | make localmodconfig
   $ cp .config config-webcam-off
   ```

4. 使用隐私开关启用摄像头，允许系统访问摄像头。

5. 再为启用摄像头的情形生成内核配置：
   ```console
   $ cp config-seed .config
   $ yes '' | make localmodconfig
   $ cp .config config-webcam-on
   ```

6. 生成配置片段：
   ```console
   $ scripts/diffconfig -m config-webcam-off config-webcam-on > webcam.config
   ```

日后再生成精简配置时，使用如下命令，就可以让精简配置支持摄像头了（该命令假设用户已根据上一小节的指引，为重新启用的模块创建了 `re-enabled-modules.config` 配置片段）。至于应用配置片段的顺序，摄像头的片段应该在重新启用模块的片段前，因为摄像头的片段可能会禁用一些应该重新启用的模块。
```console
$ scripts/kconfig/merge_config.sh -m -r config-seed localmod-all.config webcam.config re-enabled-modules.config
```

### 精简 Gentoo 发行版内核

使用 `sys-kernel/gentoo-kernel` 或 `sys-kernel/vanilla-kernel` 的 Gentoo 用户可让发行版内核软件包自动在默认配置之上应用之前创建的配置片段，以构建精简的内核。将配置片段复制到 `/etc/kernel/config.d` 目录中：
```console
# cp localmod-all.config /etc/kernel/config.d/10-localmod-all.config
# cp re-enabled-modules.config /etc/kernel/config.d/20-re-enabled-modules.config
```

如果之前还为摄像头生成了配置片段：
```console
# cp webcam.config /etc/kernel/config.d/15-webcam.config
```

以上命令会向 `/etc/kernel/config.d` 中的新文件的文件名添加数字前缀，目的是控制配置片段被应用的顺序。发行版内核软件包会按文件名的“字典顺序”（lexical order）应用配置片段[^gentoo-wiki-dist-kernel-config.d]。

[^gentoo-wiki-dist-kernel-config.d]: <https://wiki.gentoo.org/wiki/Distribution_Kernel#Using_.2Fetc.2Fkernel.2Fconfig.d>
