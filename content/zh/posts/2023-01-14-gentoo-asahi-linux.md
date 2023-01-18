---
title: "在搭载苹果 ARM 芯片的 Mac 和 Asahi Linux 之上安装 Gentoo"
tags:
  - Gentoo
  - GNU/Linux
categories:
  - 博客
toc: true
header:
  actions:
    - label: "查看截图"
      url: /img/posts/2023-01-14-gentoo-asahi-linux/mate-de.png
  overlay_image: /img/posts/2023-01-14-gentoo-asahi-linux/mate-de.png
  og_image: /img/posts/2023-01-14-gentoo-asahi-linux/mate-de.png
  caption: "Gentoo 在 Mac mini 2020 上运行 MATE 桌面环境"
  overlay_filter: 0.5
  show_overlay_excerpt: false
lastmod: 2023-01-14
---

我还记得在苹果刚发布基于自家 ARM 芯片的 Mac 的时候，有人猜测一场变革将就此在桌面计算领域展开。当时在 Reddit 上就有一名 GNU/Linux 用户声称，各大 GNU/Linux 发行版应重视起潜在的 x86-64 转到 ARM64 的趋势、未雨绸缪、采取行动，以免跟不上时代的潮流。但持此类观点的用户可能不知道的是，得益于高级语言的可移植性，构成 GNU/Linux 的常见软件包其实已经兼容 ARM64 很长时间了。而苹果发布的这些基于自家的高性能 ARM 芯片的 Mac，不但不一定会对 GNU/Linux 造成威胁，反而可能给后者提供了一个更宽阔的舞台供其发挥。在 [Asahi Linux][asahi-linux] 项目开发者的努力下，我们可以在搭载苹果芯片的 Mac 上运行 GNU/Linux，充分压榨苹果芯片的性能。

我最近为我的父亲购入了一台配有苹果 M1 芯片的 Mac mini 2020，好让他换掉他手头已经跟不上时代的 2014 款机型。（我知道苹果可能在 2023 年更新 Mac mini 产品线的消息，但 2020 款对他来说够用。并且，我购入的是官翻机，节省约￥800。）在下次有机会把机器当面交给他前，我可以先行把玩一下，于是我决定在 Mac mini 上装个 Gentoo。因为 Gentoo 上的大部分软件包都需要自行编译，所以这也是对 M1 的 CPU 性能的一项考验。对我个人而言，因为日常使用 Gentoo 并且维护 Gentoo 软件包，所以我也很好奇 M1 在软件编译方面的性能和我手头其它的 x86-64 机器相比如何。

[asahi-linux]: https://asahilinux.org/

## 从 Gentoo 最小安装 CD 映像启动的一次尝试

在如今的 PC 上安装系统的一般流程是：首先使用系统安装映像 ISO 制作可启动 U 盘，然后从 U 盘启动安装环境，再在该环境中完成安装流程。Gentoo 的安装流程也是相同的。

为了能支持这样的系统安装流程，Asahi Linux 安装器提供了一个仅安装最基础的 UEFI 环境的“[UEFI environment only][asahi-alpha-uefi-env]”选项。我最开始选了这个选项，想尝试从 Gentoo ARM64 架构的最小安装 CD 映像启动，但是失败了。截至本文撰写时，Gentoo 安装 CD 上的内核版本还是 5.15（当时 Gentoo 标为稳定的最新版本），但是 Asahi Linux 提交给上游内核的许多关键硬件的驱动都是直到 [5.19 左右][asahi-feature-support]才并入的：
- Mac mini 的 USB-A 接口直到 5.16 才支持，而 USB-C 接口的支持直到本文撰写时仍尚未提交给上游，也就是说就算我能成功启动安装映像，也用不了键盘，更别提安装 Gentoo 了。
- 内置 NVMe 硬盘直到 5.19 才支持，所以即使我能使用键盘，也没法在安装环境里访问内置硬盘。

我简短地考虑过替换安装 CD 上的内核，但考虑到可能比较耗时，而且不想在刚开始准备装 Gentoo 的时候卡在“支线任务”上太久，就还是乖乖遵循 [Asahi Linux 项目文档中一个页面上给出的 Gentoo 安装步骤][asahi-docs-gentoo]了。其实我在开始着手操作前就知道该页面的存在了，但我还是想先尝试一下一般的安装流程。

[asahi-alpha-uefi-env]: https://asahilinux.org/2022/03/asahi-linux-alpha-release/#uefi-environment-only-m1n1--u-boot--esp
[asahi-feature-support]: https://github.com/AsahiLinux/docs/wiki/Feature-Support
[asahi-docs-gentoo]: https://github.com/AsahiLinux/docs/wiki/Installing-Gentoo-with-LiveCD

## 在 Asahi Linux Minimal 上连接 Wi-Fi

因为把 Mac mini 和外设搬到我的路由器旁边并不方便，无法使用有线网络，所以我在安装过程中只能使用 Wi-Fi 联网。一开始，我遵照文档中的步骤启动了 Asahi Linux Minimal 后，没找到连接 Wi-Fi 的方法。文档说 Asahi Linux Minimal 上有 NetworkManager，但是 `nmcli` 命令并未被安装。`wpa_supplicant` 也找不到。当时我想着这个“Minimal”的意思可能是极度精简，乃至于 Wi-Fi 相关的软件包都给省了，只能使用有线网。

直到我为了能从桌面环境连接 Wi-Fi 而重新安装了组件更多的 Asahi Linux Desktop 后，我才发现 Minimal 上其实是有 Wi-Fi 软件包的，它叫做 iwd——我之前从来都没听说过。虽然文档中确实提到了 iwd，但是只看名字的话，我也不知道它是干什么用的，注意力也就全放在了 NetworkManager 上。

为了能在 Asahi Linux Minimal 上连接 Wi-Fi，我进行了以下操作：

1. 如果需要 DHCP，那就需要为 Wi-Fi 网卡启用 DHCP：
   1. 创建 `/etc/iwd` 目录：
      ```console
      # mkdir /etc/iwd
      ```
   2. 创建 `/etc/iwd/main.conf` 文件，然后填入以下内容：
      ```ini
      [General]
      EnableNetworkConfiguration=true
      ```

2. 启动 iwd 服务：

   ```console
   # systemctl start iwd.service
   ```

3. 使用 `iwctl` 命令连接 Wi-Fi 网络。请[参阅 Arch Linux 维基][arch-wiki-iwctl]了解详细步骤。

[arch-wiki-iwctl]: https://wiki.archlinuxcn.org/wiki/Iwd#iwctl

## 修改 `genstrap.sh` 脚本

{{<div class="notice--success">}}
**给“太长不看”者的总结**：为了能够启动 Gentoo 安装环境并在该环境中连接 Wi-Fi，我对 `asahi-gentoosupport` 仓库中的 `genstrap.sh` 作了两项必要的修改。如果想应用我的修改的话，请在 `asahi-gentoosupport` 仓库的根目录运行如下命令：

```console
$ curl {{<static-path res genstrap.sh.diff abs>}} | patch -p1
```
{{</div>}}

文档中给出的后续步骤是运行 `asahi-gentoosupport` 仓库里的 [`genstrap.sh`][genstrap.sh] 脚本。这个脚本负责在内置硬盘上构建一个 Gentoo 最小安装环境的映像，然后安装一个可以启动该映像的 GRUB 选项。这个选项很机智地使用 Asahi Linux Minimal 的内核和 initramfs 来启动映像，以允许 Gentoo 安装环境正常运行。

为了能真正地成功构建并使用 Gentoo 安装环境映像，我对该脚本进行了两项改动。第一项是扩大构建映像时创建的内存盘的容量。脚本分配的容量是不够用的——可能是因为自从上次脚本更新之后，系统文件的大小增加了：

```
Creating live image...

cp: error writing '/mnt/temp/var/db/pkg/dev-python/jaraco-functools-3.5.2/environment.bz2': No space left on device
```

参阅了[相关的问题报告][brd-space-issue]后，我将内存盘的容量增加到了 1 GiB，解决了这个问题：

```diff
--- a/genstrap.sh
+++ b/genstrap.sh
@@ -42,7 +42,7 @@
 echo "Creating temporary mount..."
 echo
 mkdir /mnt/temp
-modprobe brd rd_nr=1 rd_size=923600
+modprobe brd rd_nr=1 rd_size=1048576

 if [[ $? -ne 0 ]]; then
     echo "ERROR: could not create ram block device. Installing asahi-dev"
```

修改完后，该脚本就可以成功构建映像了，得到的映像也可以启动。但是，我无法在从该映像启动的 Gentoo 安装环境当中连接 Wi-Fi。系统中根本无法找到 Wi-Fi 网卡，并且 `dmesg` 中输出了如下信息：

```plain {hl_lines=13}
$ dmesg | grep brcmfmac
[    1.887035] usbcore: registered new interface driver brcmfmac
[    1.887260] brcmfmac 0000:01:00.0: Adding to iommu group 2
[    1.887456] brcmfmac 0000:01:00.0: enabling device (0000 -> 0002)
[    1.992216] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4378b1-pcie for chip BCM4378/3
[    1.993260] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m-6.11-X0.bin failed with error -2
[    1.993486] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m-6.11.bin failed with error -2
[    1.993679] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m.bin failed with error -2
[    1.993866] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP.bin failed with error -2
[    1.994056] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-X0.bin failed with error -2
[    1.994249] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb.bin failed with error -2
[    1.994444] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.bin failed with error -2
[    1.994610] brcmfmac 0000:01:00.0: brcmf_pcie_setup: Dongle setup failed
```

而在 Asahi Linux Minimal 下，Wi-Fi 是可以正常连接的。在对比了两个环境下 `dmesg` 输出的信息后，我判断这个问题是缺失固件导致的：

```plain {hl_lines="10-12"}
[    1.426797] usbcore: registered new interface driver brcmfmac
[    1.428942] brcmfmac 0000:01:00.0: Adding to iommu group 2
[    1.429249] brcmfmac 0000:01:00.0: enabling device (0000 -> 0002)
[    1.537313] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4378b1-pcie for chip BCM4378/3
[    1.538025] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m-6.11-X0.bin failed with error -2
[    1.538074] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m-6.11.bin failed with error -2
[    1.538119] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m.bin failed with error -2
[    1.538164] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP.bin failed with error -2
[    1.538208] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-X0.bin failed with error -2
[    2.072563] brcmfmac: brcmf_c_process_txcap_blob: TxCap blob found, loading
[    2.073063] brcmfmac: brcmf_c_process_cal_blob: Calibration blob provided by platform, loading
[    2.081177] brcmfmac: brcmf_c_preinit_dcmds: Firmware: BCM4378/3 wl0: Feb  8 2022 01:44:45 version 18.60.21.0.7.8.126 FWID 01-1cdae627
```

因为 `genstrap.sh` 里面[有复制博通固件到映像的操作][genstrap.sh-cp-firmware]，而 Mac 上的 Wi-Fi 网卡正是博通的，所以出现缺失固件的情况还是比较奇怪的。但是，该脚本复制的固件并不全：Asahi Linux Minimal 和 Desktop 还会加载额外的 Wi-Fi 网卡固件到 `/lib/firmware/vendor` 下，而这些额外的固件并不会被该脚本复制。这才导致 Gentoo 安装环境下找不到 Wi-Fi 网卡。

为了解决这个问题，我首先尝试了将 `/lib/firmware/vendor` 下的固件手动复制到 Gentoo 安装环境中，然后重新加载 `brcmfmac` 内核模块。这样操作完后，虽然 Wi-Fi 网卡出现了，但是系统仍然无法连接到 Wi-Fi 网络，并且 `dmesg` 中出现了以下错误信息：

```
[  361.439282] ieee80211 phy0: brcmf_msgbuf_query_dcmd: Timeout on response for query command
[  361.439292] ieee80211 phy0: brcmf_cfg80211_get_channel: chanspec failed (-5)
[  363.487297] ieee80211 phy0: brcmf_msgbuf_query_dcmd: Timeout on response for query command
[  363.487302] ieee80211 phy0: brcmf_cfg80211_get_tx_power: error (-5)
[  384.031294] ieee80211 phy0: brcmf_msgbuf_query_dcmd: Timeout on response for query command
[  384.031305] ieee80211 phy0: brcmf_vif_set_mgmt_ie: vndr ie set error : -5
[  387.039303] ieee80211 phy0: brcmf_msgbuf_query_dcmd: Timeout on response for query command
[  387.039312] ieee80211 phy0: brcmf_run_escan: error (-5)
[  387.039317] ieee80211 phy0: brcmf_cfg80211_scan: scan error (-5)
```

于是，我尝试通过使用 `grep` 搜索 Asahi Linux Minimal 的系统文件来寻找线索，例如 `grep -r /lib/firmware/vendor`，看是不是还需要执行额外的步骤才能正确加载 Wi-Fi 网卡。看到返回的[搜索结果][asahi-scripts-vendorfw]中有一些来自于 dracut 和 mkinitcpio 的钩子和脚本后，我猜测这些固件在系统首次加载 Wi-Fi 网卡的时候必须存在，因此才有在 initramfs 阶段准备固件文件的操作。后来，我在 Asahi Linux 的文档中也找到了[类似的说法][asahi-vendorfw]：

> Firmware must be located and loaded before udev starts up.  This is because udev can arbitrarily cause modules to load and devices to probe (even if not triggered directly, the kernel can e.g. discover PCI devices while the initramfs is already running), and this creates race conditions where firmware might not be available when it is needed.
>
> （译：固件的搜索和加载必须在 udev 启动之前完成。这是因为 udev 可能随机触发模块加载和设备侦测（即使不直接触发，内核仍可能会在已经启动到 initramfs 阶段后进行像探测 PCI 设备的操作），造成需要一个固件、但该固件还未能加载的竞争条件。）

据此，我对 `genstrap.sh` 进行了如下修改，终于可以在 Gentoo 安装环境下通过 `net-setup wlp1s0f0` 命令（`wlp1s0f0` 是 Wi-Fi 网卡的名字）连接 Wi-Fi 网络，解决了问题。

```diff
--- a/genstrap.sh
+++ b/genstrap.sh
@@ -74,6 +74,7 @@ cp -r /lib/modules/$(uname -r) lib/modules/
 depmod -a --basedir=. $(uname -r)

 cp -r /lib/firmware/brcm/. lib/firmware/brcm/.
+cp -r /lib/firmware/vendor lib/firmware/
 # The squashfs doesn't log in automatically for some reason?
 echo "agetty_options=\"--autologin root\"" >> etc/conf.d/agetty
 sed -i 's/\<agetty\>/& --autologin root/g' etc/inittab
@@ -102,7 +103,6 @@ dracut --force \
     --add-drivers "nvme-apple" \
     --add-drivers "squashfs" \
     --add-drivers "apple-dart" \
-    --add-drivers "brcmfmac" \
     --add "dmsquash-live" \
     --filesystems "squashfs ext4" \
     --include overlay / \
```

[genstrap.sh]: https://github.com/chadmed/asahi-gentoosupport/blob/main/genstrap.sh
[brd-space-issue]: https://github.com/chadmed/asahi-gentoosupport/issues/6
[genstrap.sh-cp-firmware]: https://github.com/chadmed/asahi-gentoosupport/blob/ba26bf73615a1eb813d7967afbb9581e9da5a295/genstrap.sh#L76
[asahi-scripts-vendorfw]: https://github.com/AsahiLinux/asahi-scripts/search?q=%2Flib%2Ffirmware%2Fvendor
[asahi-vendorfw]: https://github.com/AsahiLinux/docs/wiki/Open-OS-Ecosystem-on-Apple-Silicon-Macs#linux-specific

## 性能

Gentoo 的安装过程中需要首次构建许多软件包，是一个很好的了解苹果 M1 在代码编译方面的性能以及在高负载下的发热情况的机会。

### 软件包构建耗时

我将一些软件包在 Mac mini 上和在我平时维护测试 Gentoo 软件包用的两台 x86-64 笔记本上的构建时间进行了对比。以下是参与对比的机器的配置小结：

| 型号 | Mac mini (2020) | HP Envy x360 13-ay0000 | Dell XPS 15 9570 |
| :---- | :-------------: | :--------------------: | :--------------: |
| CPU | Apple M1 | AMD Ryzen 7 4700U | Intel Core i7-8750H |
| CPU 功耗墙 | < 39 W[^m1-pwr] | 28 W[^ryzen-pwr] | 56 W[^core-pwr] |
| CPU 核心（线程数） | 4 (4) &times; Firestorm + 4 (4) &times; Icestorm | 8 (8) &times; Renoir (Zen 2) | 6 (12) &times; Coffee Lake |
| CPU 制程 | 5 nm | 7 nm | 14 nm |
| 发布年份 | 2020 | 2020 | 2018 |

[^m1-pwr]: 我并没有找到 Mac mini 上 M1 的功耗限制的准确数值。根据[苹果官方的产品支持文档][mac-mini-pwr-consumption]，顶配版机器的整机最大功耗是 39 W；由此可以确定的是 CPU 的最大功耗肯定小于 39 W。
[^ryzen-pwr]: 该机型厂商设定的功耗墙与此不同；我使用 [RyzenAdj][sys-power/RyzenAdj] 修改了功耗限制。
[^core-pwr]: 虽然该机型厂商设定的功耗墙与此相同，但我使用 [intel-undervolt][sys-power/intel-undervolt] 对 CPU 进行了降压，因此其同功耗下的性能会有所提升。

我在每台机器上都收集了下列数据：

- [“标准构建时长单位”（*Standard Build Unit*, SBU）][lfs-sbu]。这是《Linux From Scratch》（LFS）中的一个概念；该书使用此单位估算每个软件包的构建耗时。我的测量方法是：根据[此处][lfs-binutils-pass1]的指示，在 tmpfs 上单线程编译 GNU binutils 2.39。

- 由 [`qlop`][gentoo-wiki-qlop] 报告的 `sys-devel/binutils-2.39-r4` 在 Portage 下的构建耗时，从而和 SBU 对比。与 SBU 相比，这项数据主要的差异在于多线程构建：默认情况下，Portage 会尽量使用全部 CPU 线程构建软件包。

- 由 `qlop` 报告的其它一些软件包在 Portage 下的构建耗时。我挑选了一些在所有参与对比的机器上都于近期构建过、且都使用同等配置构建的软件包。符合下列任一情形的软件包不会参与比较：
  - 该软件包近期并未在某一台机器上构建过，例如 `sys-devel/gcc`，因为我在 Mac mini 上用的还是 stage3 压缩包提供的编译器。
  - 该软件包在不同机器上的 USE 标志设定不同，例如 `media-libs/mesa`，在不同的机器上开启了不同的 `VIDEO_CARDS` USE 标志。
  - 该软件包在不同机器上有其它方面的差异，例如 Linux 内核，内核源代码（有的使用 Asahi Linux 修改的内核代码，也有的使用上游内核代码）和配置都有变化。

以下为构建耗时数据：

| CPU | M1 @ Mac mini (2020) | Ryzen 7 4700U @ 28 W | Core i7-8750H @ 56 W |
| :-- | -------------------: | -------------------: | -------------------: |
| LFS SBU              |  2'09" |  2'37" |  2'49" |
| `sys-devel/binutils` |    51" |  1'00" |  1'02" |
| `sys-apps/systemd`   |  1'20" |  1'53" |  1'41" |
| `sys-devel/llvm`     | 18'11" | 24'35" | 24'08" |
| `sys-devel/clang`    | 18'56" | 25'15" | 24'35" |

在每组数据中，M1 相较于我的两台 x86-64 笔记本可节省 15% 到 30% 的时间，同时还能保持很好的能耗比，在我看来很不错。

[mac-mini-pwr-consumption]: https://support.apple.com/zh-cn/HT201897
[sys-power/RyzenAdj]: https://packages.gentoo.org/packages/sys-power/RyzenAdj
[sys-power/intel-undervolt]: https://packages.gentoo.org/packages/sys-power/intel-undervolt
[lfs-sbu]: https://www.linuxfromscratch.org/lfs/view/stable/chapter04/aboutsbus.html
[lfs-binutils-pass1]: https://www.linuxfromscratch.org/lfs/view/stable/chapter05/binutils-pass1.html
[gentoo-wiki-qlop]: https://wiki.gentoo.org/wiki/Q_applets/zh-cn#Extracting_information_from_emerge_logs_.28qlop.29

### 发热和噪音

即使在持续的高负载下，Mac mini 的发热控制也十分优异。在连续几十分钟构建诸如 LLVM 和 Clang 的大包时，机身也只会微微变暖。无论系统是在高负载还是闲置状态下，风扇都会一直转动，但高负载下的风扇转速并不会上升，仅仅是吹出的风变得微热。在冬天的时候指望着用这台 Mac mini 在编译 Gentoo 软件包时产生的热量取暖是不现实的。

因为风扇转速并不会提升，所以即使在高负载状态下，机器也是极为安静的。Mac mini 头一次让我见识到了什么情况下 Portage 能一直“不发出噪音”地长时间运行，搞得我还有点不适应。在我的两台笔记本上，但凡系统进入高负载状态，没过多久，风扇就会开始狂转，发出噪音；而在 Mac mini 上，我压根就没法通过听声音来判断系统负载。

## Asahi Linux “发行版内核” ebuild

一直以来，我在我使用的 Gentoo 系统上都使用[发行版内核][gentoo-wiki-dist-kernel]，从而自动化内核的编译和更新流程。在 Mac mini 上，因为有些硬件功能依赖于 Asahi Linux 修改的内核代码，但 Gentoo 没有基于 Asahi Linux 源码的发行版内核，所以我一开始[使用 Git][gentoo-kernel-git] 下载 Asahi Linux 内核源码然后手动编译，有点想念发行版内核的便利。但是很快，我就自己做了一个 `sys-kernel/asahi-kernel` 软件包，可以继续在 Mac mini 上享受发行版内核的用户体验。

一个发行版内核软件包需要提供一份默认的内核配置，当然也需要提供内核源码。就 Asahi Linux 内核而言，在内核配置方面，可以直接采用 Asahi Linux Desktop 和 Minimal 上的 `linux-asahi` 软件包使用的[配置][linux-asahi-config]。而至于内核源码，自然就是 Asahi Linux 修改后的源码了。这样一来，就可以编写一个“发行版内核” ebuild 了：只需要将内核配置和源码的链接添加到 `SRC_URI` 中，覆写 `src_prepare` 以完成内核配置的注入，就可以继承 `kernel-build.eclass`，让该 eclass 完成剩下的内核编译与安装工作。正如下面的例子所示，虽然并不是一个完整的能用的 ebuild（如果不信的话，欢迎亲自试验！），但是实现了这样的大致思路：

```bash
# Copyright 2020-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit kernel-build

DESCRIPTION="Asahi Linux kernel for Apple silicon-based Macs built from sources"
HOMEPAGE="https://asahilinux.org/"

PKGBUILD_CONFIG_COMMIT="da67cf02622899775c233f52e441fc8127f51d99"
SRC_URI="
	https://github.com/AsahiLinux/linux/archive/refs/tags/asahi-${PV}.tar.gz
	https://raw.githubusercontent.com/AsahiLinux/PKGBUILDs/${PKGBUILD_CONFIG_COMMIT}/linux-asahi/config
		-> linux-asahi.config.${PKGBUILD_CONFIG_COMMIT}
"
S="${WORKDIR}/linux-asahi-${PV}"

LICENSE="GPL-2"
KEYWORDS="~arm64"

src_prepare() {
	default
	cp "${DISTDIR}/linux-asahi.config.${PKGBUILD_CONFIG_COMMIT}" .config || die
}
```

我称之为“发行版内核”的时候都加了引号，因为这并非真正由 Gentoo 发行版方面提供的内核。这个描述只是用于说明该 ebuild 和 Gentoo 官方的发行版内核一样，可以自动化内核配置、构建和安装的完整流程。

若需要完整并且可用的“发行版内核” ebuild，可移步我的个人 ebuild 仓库：

- [`sys-kernel/asahi-kernel`][sys-kernel/asahi-kernel]，对应 Asahi Linux Desktop 和 Minimal 上的 `linux-asahi` 软件包。
- [`sys-kernel/asahi-edge-kernel`][sys-kernel/asahi-edge-kernel]，对应 `linux-asahi-edge` 软件包。`linux-asahi-edge` 和 `linux-asahi` 相比，都是使用相同的源码构建的，但是前者的内核配置启用了额外的[实验性选项][linux-asahi-edge-config]。

[gentoo-wiki-dist-kernel]: https://wiki.gentoo.org/wiki/Project:Distribution_Kernel
[gentoo-kernel-git]: {{<relref 2022-03-04-gentoo-kernel-git>}}
[linux-asahi-config]: https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config
[sys-kernel/asahi-kernel]: https://github.com/Leo3418/leo3418-ebuild-repo/blob/2e063a35efb385b3f2831db875d4ee959615554a/sys-kernel/asahi-kernel/asahi-kernel-6.1_p3-r1.ebuild
[sys-kernel/asahi-edge-kernel]: https://github.com/Leo3418/leo3418-ebuild-repo/blob/2e063a35efb385b3f2831db875d4ee959615554a/sys-kernel/asahi-edge-kernel/asahi-edge-kernel-6.1_p3-r1.ebuild
[linux-asahi-edge-config]: https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config.edge

## 硬件支持与用户体验

截至 Asahi Linux 内核 6.2-rc2-1 版本的时候，Mac mini 上大部分我需要用到的硬件功能都是可正常使用的，包括 Wi-Fi、蓝牙以及 USB。有一个我比较需要但是缺失的功能，那就是 DP Alt 模式，导致我的 USB-C 扩展坞上的 HDMI 接口无法输出视频信号。我平时都是把外设连接到扩展坞上，包括显示器，这样就能方便地在设备间来回切换。比如说，如果扩展坞本来接在我的笔记本上，然后我想使用正在运行 macOS 的 Mac mini，我就可以直接把扩展坞整个拔下来、插到 Mac mini 上，就可以一次将所有外设都连过去。但是在目前的 Asahi Linux 内核下，直到其支持 DP Alt 模式前，我都暂时只能将 HDMI 线从扩展坞上拔下来、直连到 Mac mini 自身的 HDMI 接口上。

我还遇到了另外两个和 HDMI 相关的小问题，不过不确定是不是通过安装额外的软件包就能解决。

- HDMI 没有音频输出。不过，因为我只弄了最基础的 ALSA 配置，所以不确定是不是没有装 PipeWire 或 PulseAudio 导致的。我对音频输出不是特别在乎，因为 Mac mini 内置的扬声器是可正常工作的，并且我也不准备在 Mac mini 上正经地听音乐或看视频等。

- 我在 Mac mini 上的 Gentoo 下安装的 MATE 桌面环境无法让我的显示器进入省电模式；系统因一段时间内无操作而让显示器睡眠时，它仍然会显示黑屏，而非让显示器完全熄屏。我暂时还没有试过其它桌面环境，不确定这是不是 MATE 的问题；但是因为我平时把 Mac mini 接上显示器的时候一般都会活跃使用它，所以对此也没过多在意。

总而言之，在硬件支持方面，我对 Asahi Linux 内核给我的用户体验相当满意。使用 Firefox 网上冲浪、编写及测试 ebuild（自然包括 Asahi Linux 内核的 ebuild）、以及维护本网站这些任务都可正常完成。实际上，这篇文章我就是全部在 Mac mini 上的 Gentoo 中完成的！

不过，这样的体验可能只能在 Mac mini 2020 上获得；如果我是在一台 MacBook 上弄 Gentoo 的话，体验可能就不同了。和 MacBook 相比，Mac mini 或许凭借着以下几个原因提供更好的硬件支持方面的用户体验：

- Mac mini 在显示器、键盘和鼠标等输入/输出设备方面的问题理论上会更少，毕竟用户需要连接自己的外设。而对于 MacBook，Asahi Linux 开发者还需要额外支持内置硬件的功能才能保证满意的用户体验，例如可调节的屏幕亮度和能正常使用的触控板。

- Mac mini 上没有电池供电，所以电源管理问题带来的影响没有在 MacBook 上多。对于笔记本而言，如果有诸如 CPU 在待机时无法进入低功耗模式、或者无法睡眠之类的问题，那么就容易出现续航拉跨、放在包里后发热等情况，牺牲其作为笔记本的便携能力。

- Asahi Linux 开发者在支持 Mac mini 2020 方面投入的时间和经历应该是最多的。毕竟这款机型是苹果最先推出的搭载 ARM 芯片的 Mac 机型之一，并且 Asahi Linux 项目也将其选定为[首要支持机型][asahi-device-support]。

[asahi-device-support]: https://asahilinux.org/about/#what-devices-will-be-supported

## 个人观点

在我看来，如果需要一台 ARM64 开发机，并且可以接受这种形态的小主机，那么运行 Asahi Linux 内核的 Mac mini 2020 是个不错的选择。有些开发者可能想测试软件包在 ARM64 平台上的可移植性和兼容性，比如软件包上游作者和 GNU/Linux 发行版维护人员，所以需要 ARM64 架构的机器。他们平时一般使用工具链、文本编辑器和其它各种开发工具，而这些软件在 Asahi Linux 内核之上运行的 GNU/Linux 系统中都可以使用。开发人员既可以选择安装桌面环境将其当作工作站使用，也可以不连外设、只连网，将其用作一个无头构建服务器或开发环境。

虽然不能指望 Mac mini 上的苹果 M1 的 CPU 性能超越其它桌面端 CPU，但我认为在 ARM64 阵营中，它的表现已经很好了。M1 [比不过][phoronix-m1-vs-x86-64]最近几代的桌面端 AMD 锐龙 5 和英特尔酷睿 i5 等 x86-64 CPU，不过对于需要 ARM64 的开发者而言，这些 x86-64 CPU 自然在讨论范围以外。而在他们可以选择的 ARM64 CPU 范围内，和其它可用于 GNU/Linux 开发的设备（如树莓派）上的 CPU 相比，M1 的性能已经[比它们强][phoronix-m1-vs-pi]了。Linus Torvalds 本人也[认可了][lkml-linux-5.19] Asahi Linux 和搭载苹果 ARM 芯片的 Mac 给 ARM64 平台上的开发带来的价值：

> ... I did the [Linux 5.19] release (and am writing this) on an arm64 laptop.  It's something I've been waiting for for a _loong_ time, and it's finally reality, thanks to the Asahi team.  We've had arm64 hardware around running Linux for a long time, but none of it has really been usable as a development platform until now.
>
> （译：……这次我是在一台 arm64 笔记本上发布的［Linux 5.19］新版本、写的这封邮件。这件事我期待了很久——多亏了 Asahi 团队，终于让它成为了现实。我们身边一直以来都充斥着运行 Linux 的 arm64 硬件，但直到最近之前，这些硬件里都没有真正能拿来当开发平台用的。）

在价钱和性能之间，Mac mini 2020 也是我了解的 ARM64 电脑当中最均衡的选项：

- 树莓派更便宜，但性能也更弱。
- MacBook 价格更贵，对于已经有外设的人群来说性价比相对较低。并且，截至 6.2-rc2-1 版本，所有 MacBook 机型在运行 Asahi Linux 内核的时候都无法正常连接外接显示器，因为缺少 HDMI 视频输出和 DP Alt 模式的支持。
- Mac Studio 的芯片性能更强，而价格也相应地更贵。

对于其他不在乎 CPU 架构、且想整一台低功耗主机或小主机运行 GNU/Linux 的开发者和用户而言，我觉得 Mac mini 2020 也可以考虑。这类主机一般都使用移动版 x86-64 CPU，类似于我两台笔记本上的锐龙 7 4700U 和酷睿 i7-8750H。根据上文中我汇总的软件包构建耗时数据，Mac mini 上的 M1 和这些移动端 CPU 相比有着不容小觑的性能。

当然了，现阶段我还无法向所有人推荐搭载苹果 ARM 芯片的 Mac 和 Asahi Linux 的组合。截至本文撰写时，Asahi Linux 文档仍将该项目定义为“起步当中”和“处于早期 alpha 阶段”。诚然，有一些使用场景的支持仍然不是很好：

- Asahi Linux 项目仍然在测试或适配某些硬件功能。例如，截至 Asahi Linux 内核 6.2-rc2-1 版本，GPU 驱动仍然在测试阶段。在没有 GPU 驱动的情况下，根据我的测试，[Extreme Tux Racer][etr] 游戏在 1080p 分辨率下无法达到 60 FPS。而在我的笔记本上，这款游戏在集显上运行即可轻松达到数百 FPS。

- 目前，Asahi Linux 内核使用的内存分页大小是 16 KiB，会导致个别软件包出现兼容性问题。此类软件包可能只适配了所有 CPU 架构上最常见的 4 KiB 的分页大小。Asahi Linux 文档中对此有更详细的[解释][asahi-broken-sw]。

- 依赖专有软件的用户可能会遇到更多的不兼容问题。像 Google Chrome 和 Zoom 等软件根本不支持 ARM64 Linux；即使对于支持的软件，上述的 16 KiB 分页大小的问题也可能存在。

[phoronix-m1-vs-x86-64]: https://www.phoronix.com/review/apple-m1-linux-perf/5
[phoronix-m1-vs-pi]: https://www.phoronix.com/review/apple-m1-linux-perf/7
[lkml-linux-5.19]: https://lore.kernel.org/lkml/CAHk-=wgrz5BBk=rCz7W28Fj_o02s0Xi0OEQ3H1uQgOdFvHgx0w@mail.gmail.com/T/#u
[etr]: https://sourceforge.net/projects/extremetuxracer/
[asahi-broken-sw]: https://github.com/AsahiLinux/docs/wiki/Broken-Software
