---
title: "Gentoo 上手体验"
lang: zh
tags:
  - Gentoo
  - GNU/Linux
categories:
  - 博客
toc: true
asciinema-player: true
last_modified_at: 2020-12-27
---
{% include res-path.liquid %}
自我上一篇文章发布到现在，已经过去六周时间了。各种新文章的主题和想法在我脑中迸发，把它们写下来并发布的意愿在我心中萦绕，只可惜太忙，而且忙的还是个竹篮打水一场空，只能在百忙之中匆匆把想法记录在草稿里，等有空的时候再写成正式的文章。现在终于忙完了一批活，难得短暂的清静，在可能只有写一篇文章的闲暇时间的情况下，我决定先把之前首次体验 [Gentoo][gentoo] 的经历记录下来。Gentoo 是一个*源码级* GNU/Linux 发行版，最有代表性的特点就是让用户自己编译系统的几乎所有组件，乃至于 Linux 内核也可以自己编译。

[gentoo]: https://gentoo.org/

## 背景

我之前一直用的是 Fedora，已经用了两年，用起来也挺满意。直到不久前，我的室友把他电脑上的系统换成了 Arch Linux，激发了我对其它一些以前听说过却从没仔细了解过的发行版的好奇心。当时，他给我展现了 Arch Linux 的一部分安装过程，包括使用命令来给硬盘分区、以及安装最基础的软件包，让系统实现自托管，可以自己启动。以前装 Debian 和 Fedora 的时候，我通过观察安装程序的自定义选项和输出信息，大概了解了安装 GNU/Linux 的大体步骤。但是看到类似于 Arch Linux 这样的安装方式，每个安装过程中的任务都要自己输入命令执行，整个安装过程都由自己控制时，我感觉这样装系统十分有趣。

我在网上找了找相关的资料，找着找着就找到 Gentoo 去了。Gentoo 和 Arch Linux 有些地方非常相似：都是滚动发行版，都没有官方的 GUI 安装程序，都需要用户自己输入一些命令来安装，也都允许用户随心所欲地自定义一些基础系统组件。尽管如此，相比于 Arch Linux，Gentoo 还是有一些独特之处吸引着我。首先，我之前就曾[给树莓派编译过软件并制成 RPM][vcgencmd]，所以自己编译所有软件虽有挑战性，但应该在我能力范围内。再者，我看网上对 Gentoo 的软件包管理器 Portage 的评价不错。最吸引我的一个功能是 Portage 会维护一个纯文本的 `world` 文件，记录用户安装的所有软件包；将 `world` 文件复制到其它运行 Gentoo 的电脑上，就可以还原原机器上安装的软件和环境。

因为之前有一作业要求用一个工具，而那个工具要装一堆乱七八糟的依赖，我不想把它装在我日常使用的主系统上污染我的环境，所以就决定弄一个虚拟机。由于对 Gentoo 感兴趣，我自然选择了 Gentoo 作为安装在虚拟机里的系统。

我没准备在虚拟机里的系统里装桌面环境，只要有个最基础的命令行和我需要的软件就够了。那个工具也只是个命令行工具，并且我之前经常在终端里干活，所以并不需要图形化界面。在 Gentoo 里装桌面环境反而会适得其反，因为作为一个源码级发行版，安装桌面环境就意味着编译整个桌面环境，必然会显著增加安装时间。加之这是我第一次手动安装一个 GNU/Linux 系统，还是从简单点的配置入手比较好。

[vcgencmd]: /2020/07/27/compile-vcgencmd-on-fedora.html

## 安装

我基本都是参考 [Gentoo 手册][handbook]中的步骤安装的系统，但是因为想要弄一些自定义配置，所以也参考了一些手册以外的 Gentoo Wiki 的内容：

- 除了 EFI 系统分区外（我的虚拟机可以使用 UEFI），我把整个硬盘剩下的空间划成了一个 Btrfs 分区。手册给出的建议是给启动分区（`/boot`）、交换空间（swap）和根目录文件系统（root，也就是 `/`）各分一个区，但是我给启动分区、用户目录（`/home`）和根目录各创建了一个 Btrfs 子卷，就不需要划分多个分区了。至于交换空间，我准备效仿 Fedora 33 的改动，使用 [zram][zram]。

  从系统恢复的角度来说，Btrfs 很适合用在滚动发行的系统上，因为可以创建[文件系统快照][btrfs-snapshots]。在系统因为更新出问题时，回滚到上个没出问题的快照，可以轻松还原系统。虽然 LVM 也支持快照功能，但是我觉得 [Btrfs 卷比 LVM 卷组更容易管理][btrfs-vs-lvm]。

- 手册建议使用包括 Gentoo 自己的下游修改和补丁的内核源码（[`sys-kernel/gentoo-sources`][gentoo-sources]），但是我更想编译无修改的原版内核（[`sys-kernel/vanilla-sources`][vanilla-sources]）。[Linux 内核团队称][dist-kernel]，如果运行命令 `uname -r` 显示的内核版本结尾包括发行版自己加的标签，他们将无法对其提供支持，那我们就装一把编译出来之后运行 `uname -r` 就显示内核版本号的内核，体验一下直接编译纯净上游内核源码的感觉……

- Gentoo 默认安装的是 LTS 内核（5.4），但我想使用最新的稳定内核（5.9）。想装最新的稳定内核的话，需要在 `/etc/portage/package.accept_keywords` 里定义一条规则，允许使用 Gentoo 还未标为稳定的内核版本。于此同时，作为搭配，Linux 内核头文件包 `sys-kernel/linux-headers` 的版本也应该是最新版本。由于我选择了 Btrfs，配套的文件系统工具 `btrfs-progs` 最好也选用最新版本，[这样就可以使用内核提供的最新 Btrfs 功能][btrfs-progs]。

  ```
  # /etc/portage/package.accept_keywords

  # 使用最新的上游稳定版内核
  sys-kernel/vanilla-sources

  # 使用最新版本的内核头文件
  sys-kernel/linux-headers

  # 使用最新的 btrfs-progs
  sys-fs/btrfs-progs
  ```

- 尽管 Gentoo 的默认 init 系统是 OpenRC，跟着默认的配置走对于第一次安装 Gentoo 可能也会容易一些，我还是决定使用 systemd，因为 systemd 支持[用户级别的服务][systemd-user-srv]，而我没找到 OpenRC 中类似的功能。

  Gentoo 手册里简单介绍了一些 systemd 的注意事项和特殊步骤，但是仍然有些手册里没强调的操作容易被忘记，比如启用最基础的 systemd 系统服务：

  ```console
  (chroot) # systemctl preset-all
  ```

  我在装好系统重启前就忘了运行这行命令了，然后重启之后因为 `systemd-networkd.service` 没启用，导致无法联网。

[handbook]: https://wiki.gentoo.org/wiki/Handbook:Main_Page/zh-cn
[zram]: https://wiki.gentoo.org/wiki/Zram
[btrfs-snapshots]: https://fedoramagazine.org/btrfs-snapshots-backup-incremental/
[btrfs-vs-lvm]: /2020/10/08/fedora-raw-image-btrfs.html#选用-btrfs-的理由
[gentoo-sources]: https://packages.gentoo.org/packages/sys-kernel/gentoo-sources
[vanilla-sources]: https://packages.gentoo.org/packages/sys-kernel/vanilla-sources
[dist-kernel]: https://www.kernel.org/category/releases.html#distribution-kernels
[btrfs-progs]: https://btrfs.wiki.kernel.org/index.php/FAQ#Do_I_have_to_keep_my_btrfs-progs_at_the_same_version_as_my_kernel.3F
[systemd-user-srv]: https://wiki.archlinux.org/index.php/Systemd_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/User_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)

### 调试内核参数

我发现安装过程中最耗时的一步是编译内核，当然这也有可能只是因为虚拟机的性能损耗导致内核编译速度比正常的要慢。缩短内核编译时间最有效的办法就是禁用掉没有用的内核配置选项，比如所有您的电脑上没有的硬件的驱动。

但是不得不承认，Linux 内核提供的配置选项太多了，而且许多选项仅凭看名字是看不出它的实际作用的，导致配置内核成为了一项复杂的工作。我看到 Linux 支持的繁多的硬件种类和数量后叹为观止，感觉 Linux 真是个伟大的软件工程，但是要想把它配置好，尤其是把每一个用不上的硬件支持选项都禁用，实在是过于费时费力。并且，因为不了解一些选项的作用，所以也不敢胡乱禁用。

最后，我决定只禁用那些编译起来很费时、并且我可以肯定不需要的选项，例如：

- GPU 支持（给英特尔集显的 `i915`、`radeon`、`amdgpu`、以及给英伟达显卡的 `nouveau`）。这几个模块都需要相当长的时间编译。因为我用的虚拟机不会直接使用电脑的显卡，而是走虚拟化软件提供的虚拟显卡，而虚拟显卡是由别的模块支持的，所以这几个模块都可以禁用。但如果是在实体机上配置内核的话，就得根据机器上装的显卡，启用相应的模块了。

- [InfiniBand][infiniband]。我都没听说过这是什么东西，这次在内核配置里是第一次碰到它，所以我估计这个东西我根本没有，就可以直接禁用。但是，这样的想法不适合用来判断是否该禁用其它类型的内核配置选项。比如，默认的内核配置会启用一些系统调用的支持，但我肯定不会仅仅因为没听说过一个系统调用就禁用它，因为有的软件可能需要这些特殊的系统调用。

根据实际的硬件配置，可能还有一些硬件相关的选项可以安全禁用。比如，如果在一台没有 Wi-Fi、蓝牙和 NFC 之类的无线设备上配置内核，就可以把相应的硬件支持都关掉。如果是没有 NVMe 的老电脑，NVMe 也可以禁用。

不过，我在网上找到了一个[各主流 CPU 型号上的内核编译时间的汇总][kernel-build-time]，如果里面的信息准确的话，那在目前常见的 CPU，甚至是英特尔前几年挤牙膏挤出的低压双核笔记本 CPU 上，编译内核所需的时间也不过是十分钟左右。我还没在我电脑上虚拟机以外的环境编译过内核，还想像不出十分钟编译完内核是什么体验，但如果真是这样的话，钻研并关闭无用的内核配置选项花的时间可能不及由此省下的编译时间。这种情况下，可以考虑直接用一个兼容主流硬件的内核配置，比如 [`genkernel`][genkernel] 生成的配置。

[infiniband]: https://zh.wikipedia.org/zh-cn/InfiniBand
[kernel-build-time]: https://openbenchmarking.org/test/pts/build-linux-kernel
[genkernel]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel/zh-cn#.E5.A4.87.E9.80.89.EF.BC.9A.E4.BD.BF.E7.94.A8genkernel

## 使用 `ebuild`

在 Portage 中，一个 [`ebuild`][ebuild] 文件定义了一个软件包。`ebuild` 之于 Gentoo，等同于 `PKGBUILD` 之于 Arch Linux、RPM SPEC 之于 Fedora，CentOS，RHEL 等。我还没有尝试过像当时[给 Fedora 做树莓派的 `userland` 软件包的 RPM][userland] 那样自己写 `ebuild` 文件，但是就我使用 Gentoo 官方提供的 `ebuild` 的经历而言，我感觉 Portage 基于 `ebuild` 的设计思路是很不错的。

之前提到，我选用了 Btrfs 并且想基于 Btrfs 快照做一套系统恢复方案，故准备使用 [Snapper][snapper-gentoo] 自动捕获快照。当时 Snapper 上游的最新版本是 0.8.14，但是 Gentoo 软件仓库里的最新版本才到 0.8.9。

我在维护 `userland` 和其它一些桌面 GUI 应用的 RPM SPEC 时，如果遇到上游软件更新，一般只需要在 RPM SPEC 里改一下版本号，就可以顺利创建新版软件的 RPM 包了，因此决定在 Snapper 的 `ebuild` 上也尝试一下。令我惊奇的是，在 Gentoo 上同步上游软件的更改，唯一需要做的就是把 `ebuild` 改个名，因为 Portage 软件包的版本是直接在 `ebuild` 的文件名中定义的。我仅仅需要把 `snapper-0.8.9-r1.ebuild` 改名成 `snapper-0.8.14.ebuild` 就可以安装 Snapper 0.8.14 了！

{% include asciinema-player.html name="custom-ebuild.cast" poster="npt:31" %}

如果我要在 Fedora 上像安装官方包一样安装我自己做的 RPM 的话，我会用我做的 SPEC 文件把 RPM 构建出来，将其复制到专门存放我自制的 RPM 的的自定义软件仓库中，然后就可以像安装普通软件那样安装了。但是 SPEC 文件必须单独保存，因为构建出的 RPM 里是没有 SPEC 的。如果我到后面想修改 SPEC 文件的话，我就得找到当初保存 SPEC 的地方，然后进行修改，重新构建 RPM，最后再次将其复制到自定义软件仓库里。

但如果是用 Gentoo 的话，整个过程就十分流畅：我写好 `ebuild` 后，不需要什么构建，直接将 `ebuild` 自身放到我的自定义软件仓库就行了。日后进行更改时，我可以在仓库里直接修改 `ebuild`，不用到别处寻找。与软件包相关的所有文件都可以统一存在软件仓库里，不用四处存放。

为了对比在 Fedora 和 Gentoo 上维护自定义软件包的流程，我做了一个表格。可以发现，作为一个源码级发行版的软件包管理器，Portage 对自定义软件包更加友好。得益于此，在 Gentoo 上维护自定义软件包是不需要任何额外的构建步骤的。

| 任务 | Fedora 上的步骤 | Gentoo 上的步骤 |
| :--- | :-------: | :-------: |
| 定义软件包元数据以及构建流程 | 编写 RPM SPEC | 编写 `ebuild` |
| 构建软件包 | `rpmbuild -bb SPEC` | **不需要**<br>（在使用 `emerge` 安装软件包时自动执行） |
| 将软件包加至自定义软件仓库 | 将构建出的 RPM 复制到仓库中 | 将 `ebuild` 复制到仓库中 |
| 安装软件包 | `dnf install PKG` | `emerge --ask PKG` |
| 增加软件包版本号 | 在 RPM SPEC 中修改软件版本 | 重命名 `ebuild` 文件 |
| 构建新版软件包 | `rpmbuild -bb SPEC` | **不需要**<br>（在使用 `emerge` 升级软件包时自动执行） |
| 更新自定义软件仓库中的软件包 | 将新的 RPM 复制到仓库中 | **已经完成**<br>（在重命名 `ebuild` 时已完成） |
| 安装新版软件包 | `dnf upgrade PKG` | `emerge --ask --update PKG` |

如果需要更多有关创建自定义 `ebuild` 仓库的信息，可以参阅[这篇 Gentoo Wiki 文章][custom-ebuild-repo]（英文）。其中的[“simple version bump”部分][ebuild-ver-bump] 描述的就是我如何在 Gentoo 最新的 Snapper 版本还是 0.8.9 时构建并安装 0.8.14。您还可以考虑[提高您的自定义仓库的优先级][ebuild-repo-priority]，这样 Portage 就会优先选择您自定义的软件包了。

```
# /etc/portage/repos.conf/local.conf

[local]
location = /var/db/repos/local
priority = -999  # Gentoo 官方仓库的优先级是 -1000
```

[ebuild]: https://wiki.gentoo.org/wiki/Ebuild
[userland]: /2020/07/27/compile-vcgencmd-on-fedora.html#使用-dnf-安装-vcgencmd
[snapper-gentoo]: https://packages.gentoo.org/packages/app-backup/snapper
[custom-ebuild-repo]: https://wiki.gentoo.org/wiki/Custom_ebuild_repository
[ebuild-ver-bump]: https://wiki.gentoo.org/wiki/Custom_ebuild_repository#Simple_version_bump_of_an_ebuild_in_the_local_repository
[ebuild-repo-priority]: https://wiki.gentoo.org/wiki/Ebuild_repository/zh-cn#.E4.BC.98.E5.85.88.E7.BA.A7

## 建议

因为我还没有将 Gentoo 作为日常使用的系统，这次在虚拟机里也没装桌面环境和一些主流软件，只装了 Git、Vim 和 tmux，所以我很难负责任地给出适合用 Gentoo 的人群，但这次短暂的 Gentoo 初体验应该还是能让我感受出大概什么样的人比较适合使用 Gentoo。

Gentoo 对于以下几种用户群体而言是绝佳的选择：

- 需要自己构建小众软件包或者软件包最新版本，并且想用系统的软件包管理器管理它们的人群。比如，我之前寻找[树莓派 USB 接口问题][raspi-usb]的解决方案时，找到了一个网站 <http://rglinuxtech.com/>，那个网站的站长似乎就很喜欢自己编译 Linux 的 `rc` 内核。如果他想用系统的软件包管理器来管理 `rc` 内核的话，Gentoo 可能是不二之选。

  当然，您也完全可以选择自己管理自己构建的软件，但是这种方式的难点在于记录每个软件包都有哪些文件，倘若记录不准确就可能造成卸载软件时有文件残留。[GNU Stow][stow] 是一个解决方案，但每次修改已安装的软件后都需要手动调用该程序。利用 Portage 和自定义 `ebuild` 文件，就可以让整个软件自构建过程更顺畅：写一个 `ebuild`（基本就是写一个自动构建并安装软件的脚本），然后运行 `emerge`，剩下的就全部交给 Portage。

- 使用与 Gentoo 的哲学比较类似的发行版（如 Arch Linux），但希望通过优化编译器选项提升软件运行性能、或者是想摆脱 systemd，使用 OpenRC 代替的用户。如今，systemd 的身影已经出现在了绝大多数主流 GNU/Linux 发行版中，就连给予用户很大系统组件选择权的 Arch Linux 都宣称只官方支持 systemd。

- 有一定的 GNU/Linux 基础知识，想要继续深入研究、了解操作系统内部原理的人群。就拿我自己的经历来说，在配置 Linux 内核选项的过程中，我对内核提供的功能以及内核模块有了一定的了解。除了 Gentoo 外，可能没有其它主流发行版能够给予我研究这些东西的动机了。

下列用户群体在决定使用 Gentoo 前应三思而行：

- 准备给一台硬件资源匮乏的电脑装系统的用户。在性能比较羼弱的 CPU 上，比如我树莓派的 ARM 芯片和虚拟机的虚拟 CPU，内核编译动辄就是一个或几个小时。如果您的存储容量不是很富裕，构建过的软件包的源代码占据的若干 G 的空间就会十分显著。我这个 Gentoo 系统只有几个自己装的软件，没有装桌面环境，所有安装的软件包的源码占用 1223 MiB，而 Linux 5.9.8 的代码占据 1074 MiB。倘若我装了桌面环境的话，占据的空间还会更多。

  ```console
  $ du -s -B M /var/cache/distfiles /usr/src/linux-5.9.8
  1223M /var/cache/distfiles
  1074M /usr/src/linux-5.9.8
  ```

  Gentoo 将构建软件包的任务交给了用户，而其它的二进制机器码发行版就相当于为用户编译好了所有的程序。选用一个普通的发行版就相当于让其他人帮您完成编译这一苛求性能的操作，在您自己的电脑性能一般的情况下可能是个明智的选择。

- 刚开始接触 GNU/Linux 和/或软件构建和编译的人群。虽然配置和使用 Gentoo 的过程可以让您学到很多东西，但这也是建立在已经有了些 GNU/Linux 的基础知识、技能和理解的前提下。这种情况下，我建议先从一个容易安装和维护的 GNU/Linux 发行版入手，然后等到哪一天觉得安装 Arch Linux 不是什么大问题时，就可以考虑换到 Gentoo 了。

[raspi-usb]: /2020/09/21/raspi4-fedora-usb-complex.html
[stow]: https://www.gnu.org/software/stow/
