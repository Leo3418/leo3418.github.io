---
title: "配置自己的 Gentoo 二进制包服务器"
tags:
  - Gentoo
categories:
  - 教程
toc: true
---

在诸多 GNU/Linux 发行版中，Gentoo 的一大特色是用户可以相对容易地从源码编译整个系统所有的软件包。在之前很长一段时间当中，从源码编译软件包是 Gentoo 用户的唯一选择，因为和其它发行版为用户分发已编译好可以直接运行的二进制可执行文件不同，Gentoo 分发给用户的只是用来编译二进制文件的脚本（也就是 ebuild）。从源码编译整个系统要花费很长时间，这也是 Gentoo 用户以前必须要面对的问题。不过，在 2023 年年底，一切都变了：[Gentoo 官方的二进制包服务器上线了][gentoo-news-binary]。该二进制包服务器为许多 Gentoo 软件仓库中的软件包都提供了预编译的二进制包，允许用户直接下载安装、跳过本地编译流程，从而节省时间。

官方的二进制包服务器想必已经能满足绝大用户的需求，但有些用户可能还有其它特别的需求，需要通过自建的二进制包服务器才能更好地解决。本文就将介绍一些自建二进制包服务器可满足的需求、以及自建二进制包服务器的一种方法。

[gentoo-news-binary]: https://www.gentoo.org/news/2023/12/29/Gentoo-binary.html

## 术语

为简化表述并消除歧义，以下为本文所使用的术语以及相应的定义：

二进制包
: 默认指一种文件，可由用户通过 Portage（Gentoo 的软件包管理器）安装到一台 Gentoo 系统上。二进制包的文件扩展名通常为 `.gpkg.tar` 或 `.tbz2`，具体取决于该二进制包的格式（GPKG 还是 XPAK）。

软件包
: 有别于“二进制包”，“软件包”并非指单个文件。在本文中，本词在技术角度上等同于 [`emerge` 手册页面][man-emerge]中所提到的“Portage package directory”（Portage 软件包目录）。例如，`app-shells/bash`、`dev-lang/python`、`sys-devel/gcc` 都可称为软件包。

客户机
: 将被配置从自建二进制包服务器下载二进制包的 Gentoo 系统。

容器
: 通过虚拟化技术在另一操作系统上运行的一份系统安装，如 Docker 容器、`systemd-nspawn` 容器。虽然 chroot 环境并不叫作“容器”，但本文也将其视为一种容器。

宿主系统
: 运行容器的操作系统。

[man-emerge]: https://dev.gentoo.org/~zmedico/portage/doc/man/emerge.1.html

## 自建二进制包服务器的理由

选择配置自己的二进制包服务器，而不是使用 Gentoo 官方的服务器，主要是为了在使用二进制包节省时间的同时还能自定义软件包设置。Gentoo 虽然提供了很多其它发行版上没有的自定义软件包的方式（如下文所列），但如果要使用 Gentoo 官方的二进制包服务器上的二进制包，基本就无法再按这些方式自定义软件包了。

- 自定义编译器选项（即 `CFLAGS`、`CXXFLAGS` 等环境变量）。诸如 `-march=x86-64-v4` 的编译器选项可以优化软件包在最新款处理器型号上的性能表现。像 [CachyOS] 这样的发行版，就是通过他们的软件包对最新的 x86-64 功能等级（feature levels）的优化，比如 x86-64-v4 专属优化，来标榜其高性能的特点。已有[评测][cachyos-benchmark]表明，x86-64-v4 专属优化确实能带来系统性能的提升。截至本文编写时，Gentoo 官方的二进制包服务器[提供为 x86-64-v3 优化的二进制包][gentoo-news-x86-64-v3]，但并无为 x86-64-v4 优化的包，因此使用最新款的 x86-64-v4 处理器型号的用户（如 Zen 4 或更新微架构处理器的用户）就无法使用官方二进制包发挥出处理器的全部性能潜力。

- USE 标志。USE 标志主要允许用户打开软件包的一些选项以启用更多功能，或是关闭一些选项以追求轻量化。例如，使用带有 TPM 的电脑的用户可以启用 `tpm` USE 标志以允许软件使用 TPM 设备；从来都用不到 Samba 网络协议的用户可以关闭 `samba` USE 标志以降低软件包的大小和编译时长。目前，单个二进制包文件只支持一种 USE 标志组合，因此当某个软件包的 USE 标志设置变化时，就需要有另一个支持该新 USE 标志组合的二进制包，否则就需要从源码重新编译该软件包。虽然 Gentoo 官方的二进制包服务器有时会为同一个软件包提供多个不同的二进制包文件，以覆盖不同的 USE 标志组合，但不同的 USE 标志组合的数量经常特别多，Gentoo 官方服务器无法全部涵盖。因此，如果有软件包的 USE 标志设置不被 Gentoo 官方服务器上的任何二进制包支持，Portage 就需要在客户机上本地编译该软件包。

- 用户补丁。在 Portage 开始编译某个软件包前，Gentoo 允许用户应用补丁以修改该软件包的源码，并使用应用了修改的源码来编译。通过用户补丁，用户可以[在软件包新版本发布前就修复现有版本中的 bug][portage-user-patches-fix-bugs]，甚至在某些情况下还可以[为软件包添加新功能][portage-user-patches-grub-argon2]。Gentoo 官方的二进制包服务器都是在不带任何用户补丁的情况下编译二进制包，并且也不提供允许用户上传用户补丁然后应用它们来编译二进制包的功能。因此，使用 Gentoo 官方的二进制包就意味着放弃用户补丁。

如果配置自己的二进制包服务器，配置者就可以自定义软件包、且编译带有自定义设置的二进制包；此时，自定义软件包的能力和方式，与从源码编译安装软件包时是一样的，毕竟生成二进制包之前需要先从源码正常编译软件包本身。

自建二进制包服务器在另一种情况下也特别有用，即要安装的软件包在 Gentoo 官方的二进制包服务器上没有相应的二进制包。截至本文编写时，Gentoo 官方服务器上有 GNOME、KDE、其它若干应用程序、以及它们的依赖的二进制包，但是官方服务器并不会给 Gentoo 软件仓库的每个软件包都编译二进制包。如果想安装的软件包在 Gentoo 官方服务器上没有二进制包，却又想使用二进制包安装该软件包，就必须自建二进制包服务器。

[CachyOS]: https://cachyos.org/
[cachyos-benchmark]: https://www.phoronix.com/review/cachyos-x86-64-v3-v4
[gentoo-news-x86-64-v3]: https://www.gentoo.org/news/2024/02/04/x86-64-v3.html
[portage-user-patches-fix-bugs]: {{< relref "2021-03-01-portage-user-patches" >}}
[portage-user-patches-grub-argon2]: {{< relref path="collections/gentoo-config-luks2-grub-systemd/patch-grub" lang="en" >}}

## 效果

按照本文所述的方法配置好二进制包服务器后，服务器的系统管理员可通过 Portage 配置文件（如 `/etc/portage/make.conf`、`/etc/portage/package.use`、`/etc/portage/patches`）来完整地自定义软件包，然后服务器就会带着这些自定义设置编译二进制包。

系统管理员还可以指定要专门为哪些软件包编译二进制包、以及选择不为哪些软件包编译二进制包；具体的操作方式也是通过修改 Portage 配置文件。

本文所述的方法还能让二进制包服务器自动为新的 ebuild 编译新的二进制包，从而实现二进制包的全自动更新，消除了服务器正常运行时手动操作的必要。

本文所述方法也有无法实现的效果，比如让服务器按客户机需求编译新的二进制包。例如，如果服务器没有 `foo/bar` 软件包的二进制包，而客户机此时运行诸如 `emerge --ask foo/bar` 的命令，那么在客户机上，Portage 会在本地编译 `foo/bar`；这样的命令无法达到让服务器当场给 `foo/bar` 新编译一个二进制包的效果。毕竟 Portage 本身没有让客户机给二进制包服务器发送编译二进制包请求的功能。这种情况下，如果想给 `foo/bar` 编译二进制包的话，系统管理员需要完成如下操作（为每个软件包做一次即可）：

1. 在二进制包服务器上，系统管理员指定 `foo/bar` 为需要为其编译二进制包的软件包。
2. 系统管理员触发一次 `foo/bar` 二进制包的编译过程，一般通过在二进制包服务器的容器中运行 `emerge --ask foo/bar` 即可。编译完成后，客户机再运行 `emerge --ask foo/bar` 时，客户机上的 Portage 就能开始为其使用二进制包了。

### 选择为整个系统还是仅为个别软件包编译二进制包

本文所述的方法支持只为个别软件包（例如 1--100 个软件包）——而非整个系统的软件包（通常为 500--1000 个，取决于系统是否包括桌面环境等因素）——编译二进制包，无论出于何种原因。（按本文的方法，仍然可以为整个系统的软件包编译二进制包。）

选择只为个别软件包编译二进制包的一种可能的原因，是均衡时间的节省和硬件专属的性能优化，尤其是在有很多台处理器微架构截然不同的客户机的情况下。例如，我有一台戴尔 XPS 15 9570，搭载的处理器是英特尔酷睿 i7-8750H，微架构为 Kaby Lake（`-march=skylake`），功能等级是 x86-64-v3；我还有一台 Framework Laptop 13，处理器是 AMD 锐龙 7 7840U，微架构为 Zen 4，功能等级是 x86-64-v4。对于编译时间相对较长的大软件包，例如 `sys-devel/gcc`、`llvm-core/llvm`，我希望使用二进制包以节省时间；与此同时，在 Zen 4 处理器上，对于至少绝大多数软件包（如果不能是所有），我也希望能启用 Zen 4 和 x86-64-v4 的专属优化。如果想让一份二进制包同时支持这两款处理器，我就必须使用 `-march=skylake` 编译器选项，但这也意味着编译出来的二进制包没有 Zen 4 专属优化。于是，我选择了只为之前提到的几个大包（而非整个系统所有的软件包）编译二进制包。这样一来，在 Zen 4 处理器上，没有二进制包的软件包（即大多数软件包）就会在本地以 `-march=native` 选项编译，以启用处理器专属优化，达到更高的性能；至于有二进制包的大包，虽然没有 Zen 4 的专属优化，但毕竟属于少数。我个人认为，这样的折中方案可以接受。

## 方法概述

本文所述的方法所采取的技术栈如下：

- 从 stage 3 文件创建的容器，例如 `systemd-nspawn` 容器、Docker 容器、或 chroot 环境。所有二进制包都将通过在此容器中运行 Portage 来编译。

  - 运行该容器的宿主系统无须是 Gentoo；宿主系统理论上可以是任何 Linux 发行版，不过我尚未测试过 Gentoo 以外的发行版。

- 分发二进制包的途径，例如 HTTP、SSH、NFS。

- 自动化为新 ebuild 编译新二进制包的方式，例如 cron 定时脚本、systemd 定时器。

在下文中，我将着重描述我个人使用的方案：
- `systemd-nspawn` 容器
- nginx
- systemd 定时器

您完全可以选择不同的组件来组成您的技术栈。如果您选用其它组件，您配置二进制包服务器的具体操作步骤将与本文中描述的步骤有出入，但本文应该依然能作为有用的参考资料。

我个人采取的方案还有一特殊之处，即我运行容器的宿主系统已经是 Gentoo 了，因此容器和宿主系统之间可以共享一些文件。例如，容器可以使用宿主系统的 Gentoo 软件仓库数据库（`/var/db/repos/gentoo`）和软件包源文件（`/var/cache/distfiles`）；同时，宿主系统也可以直接访问位于本机硬盘的、容器编译出来的二进制包，无须通过 HTTP、SSH 等网络协议再绕路。

虽然 Gentoo 宿主系统本身也可以编译二进制包，无须借助容器，但我依然选择了在容器内编译二进制包。这样做的目的是将二进制包的编译环境与宿主系统隔离开来。我的宿主系统是我家里的个人服务器，上面还运行了二进制包服务器以外的服务；我不想让二进制包服务器为了编译新二进制包而进行的自动系统更新影响到其它服务的正常运行。

## 创建容器

本小节主要讨论 `systemd-nspawn` 容器。准备使用其它类型容器的读者可参考以下资源：

- Docker 容器：如果使用 Docker，则可以用 [`gentoo/stage3`][docker-hub-gentoo-stage3] Docker 映像来创建 Docker 容器。即便使用 Docker，也可以参考下文对 `systemd-nspawn` 容器的描述，为 Docker 容器配置同样的绑定挂载（bind mounts）。
- Chroot 环境：可参阅 Gentoo Wiki 二进制包指南中的[相关部分][gentoo-wiki-binpkg-guide-chroot]。

以下操作步骤将为二进制包服务器配置 `systemd-nspawn` 容器：

1. 创建容器配置文件。假设容器的名字应该叫 `binhost`，那么配置文件的路径就是 `/etc/systemd/nspawn/binhost.nspawn`。该配置文件需要授予容器访问互联网的能力（以下载软件包源码）、且配置绑定挂载，以允许容器和宿主系统之间共享文件。例如：

   ```ini
   # /etc/systemd/nspawn/binhost.nspawn
   [Exec]
   Capability=CAP_NET_ADMIN
   ResolvConf=bind-stub

   [Files]
   Bind=/var/cache/binpkgs
   # 以下 `Bind=` 选项仅在宿主系统是 Gentoo 时有用处
   Bind=/var/cache/distfiles
   Bind=/var/db/repos
   ```

   - `Capability=CAP_NET_ADMIN` 赋予容器访问网络的权限，以允许其下载软件包源码。
   - `ResolvConf=bind-stub` 是为了容器内部的域名解析，同样也是能下载软件包源码的必要条件之一。
   - `Bind=/var/cache/binpkgs` 将容器的 Portage 二进制包目录共享到宿主系统上同样的路径下。有了这条选项，就可以配置宿主系统上的 HTTP 服务器、NFS 等工具直接共享宿主系统 `/var/cache/binpkgs` 路径下的内容，以允许客户机下载二进制包。如果宿主系统运行 Gentoo，这样做还可以在稍后让宿主系统直接在本地从默认路径读取容器编译出来的二进制包。

   如果宿主系统是 Gentoo，还可以为容器再配置两个额外的绑定挂载，以消除重复文件、减少下载流量：
   - `Bind=/var/cache/distfiles` 在容器和宿主系统之间共享软件包源码文件。
   - `Bind=/var/db/repos` 共享软件仓库中的 ebuild 文件等。

2. 创建容器目录。假设容器的名字叫 `binhost`，那么其目录就是 `/var/lib/machines/binhost`。
   ```console
   # mkdir --parents /var/lib/machines/binhost
   ```

3. 为客户机当中最常见的配置[下载合适的 stage 3 文件][gentoo-downloads]。例如，如果大部分客户机都是 x86-64 架构、使用 systemd 作为 init 系统、并运行桌面环境的笔记本或台式机，而只有一台客户机是 x86-64 架构、也使用 systemd、但没有桌面环境的服务器，那么最合适的 stage 3 文件是 amd64 “desktop profile | systemd” stage 3（`stage3-amd64-desktop-systemd`）。

4. 将 stage 3 文件导入容器目录：
   ```console
   # tar -C /var/lib/machines/binhost -xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
   ```

5. 现在就可以启动该 `systemd-nspawn` 容器了。假设其名字叫 `binhost`，那么启动该容器的命令如下：
   ```console
   # systemd-nspawn --machine=binhost
   ```

[docker-hub-gentoo-stage3]: https://hub.docker.com/r/gentoo/stage3
[gentoo-wiki-binpkg-guide-chroot]: https://wiki.gentoo.org/wiki/Binary_package_guide/zh-cn#Chrooting
[gentoo-downloads]: https://www.gentoo.org/downloads/

## 在容器中配置 Portage

本小节中列出的操作步骤适用于所有类型的容器（`systemd-nspawn` 容器、Docker 容器、chroot 环境）。

1. 启动容器，并访问其命令行。本小节中后续列出的所有步骤都将在容器中完成，而非在宿主系统本身之上。

2. 在容器的 `/etc/portage/make.conf` 中，指定需要的编译器选项。需要注意的是，所有编译器选项都必须和所有客户机*以及二进制包服务器本身*兼容，特别是涉及到硬件兼容性的 C/C++ 编译器选项（以 `-m` 开头，尤其是 `-march`）。二进制包服务器本身也必须考虑的原因是，在二进制包服务器上运行容器编译二进制包时，需要调用构建工具（如编译器、解释器、构建系统），而这些构建工具也将以同样的编译器选项编译，因此如果有某个编译器选项与二进制包服务器本身不兼容，就可能导致构建工具在服务器上无法运行，也就无法编译二进制包了。若要了解更多详情，请参考 Gentoo Wiki 二进制包指南中的[相关部分][gentoo-wiki-binpkg-guide-flags]。

3. 如欲自定义 `CPU_FLAGS_*` USE 标志，那么应在容器中将 `CPU_FLAGS_*` USE 标志设为所有客户机支持的标志以及二进制包服务器本身支持的标志的*交集*。此处的“交集”就是[其集合论中的含义][wikipedia-intersection-set-theory]：交集中的标志必须在每台电脑支持的标志的集合中都存在。

   例如，假设在考虑范畴中的设备如下：
   - 一台支持 `CPU_FLAGS_X86` 标志 `aes avx f16c fma3` 的客户机
   - 另一台支持 `avx f16c mmx` 标志的客户机
   - 二进制包服务器本身，支持 `aes avx f16c avx2` 标志

   那么交集为 `avx f16c`。

   若要找出每台设备支持的 `CPU_FLAGS_*` 标志，可在各设备上安装 `app-portage/cpuid2cpuflags` 工具：
   ```console
   # emerge --ask app-portage/cpuid2cpuflags
   ```

   然后，运行如下命令即可得到该设备支持的标志：
   ```console
   $ cpuid2cpuflags
   ```

4. 如欲自定义 `VIDEO_CARDS` USE 标志，那么应在容器中将 `VIDEO_CARDS` USE 标志设为各客户机应使用的 `VIDEO_CARDS` 标志的*并集*。如果二进制包服务器上的宿主系统不是 Gentoo 或没有桌面环境的话，可以忽略服务器自身的 `VIDEO_CARDS` 标志。此处的“并集”也是[其集合论中的含义][wikipedia-union-set-theory]：将所有电脑的标志都合起来，即可得到并集。

   例如，假设在考虑范畴中的设备如下：
   - 一台需要 `VIDEO_CARDS` 标志 `amdgpu radeonsi` 的客户机
   - 另一台需要 `radeon radeonsi` 标志的客户机

   那么并集为 `amdgpu radeon radeonsi`。

5. 如果大部分客户机使用的*配置文件*（profile，通过 `eselect profile` 命令选择）都一样，那么建议在容器中也选择该配置文件。例如，我自己的二进制包服务器的客户机都是运行 GNOME 和 systemd 的笔记本和台式机，因此我会在容器内选择 `default/linux/amd64/23.0/desktop/gnome/systemd` 配置文件。Gentoo 手册中对[选择配置文件][gentoo-handbook-profile]有更多的说明。

6. 在容器内的 Portage 配置文件中，选择要为哪些软件包编译二进制包。如上文所述，要编译二进制包的软件包的范围可以是整个系统的所有软件包，也可以仅限选定的软件包。现在就是选择该范围的时候；具体的方法是选择是为所有软件包还是个别软件包启用 `FEATURES="buildpkg"`。

   - 如果想为整个系统的软件包编译二进制包，那么应在容器内的 `/etc/portage/make.conf` 中设置如下选项：

     ```bash
     FEATURES="buildpkg"
     ```

     即使这样设置，仍然可以选择不为个别软件包编译二进制包；具体的方法在下面。

   - 如果希望仅为个别软件包启用或禁用二进制包的编译：

     1. 在容器内创建 `/etc/portage/env` 目录：
        ```console
        # mkdir --parents /etc/portage/env
        ```

     2. 在上述目录中，创建两个文件，以备稍后使用：一个文件用于为单个软件包启用二进制包编译，另一个用于为单个软件包禁用二进制包编译。两个文件的文件名可以任选，只要它们的文件名互相不同、且不与该目录下的其它已有文件重名即可。例如，两个文件可以分别叫 `buildpkg-yes.conf` 和 `buildpkg-no.conf`：
        ```console
        # echo 'FEATURES="buildpkg"' > /etc/portage/env/buildpkg-yes.conf
        # echo 'FEATURES="-buildpkg"' > /etc/portage/env/buildpkg-no.conf
        ```

     3. 在容器内创建 `/etc/portage/package.env` 目录。（虽然 Portage 允许 `/etc/portage/package.env` 作为文件存在，但其它一些软件包，例如 `sys-devel/crossdev`，需要其作为目录存在[^portage-package-env-dir-requirement]。）
        ```console
        # mkdir --parents /etc/portage/package.env
        ```

     4. 在容器内 `/etc/portage/package.env` 目录下的一个文件中（如 `/etc/portage/package.env/buildpkg`）为个别软件包单独启用或禁用二进制包的编译。如果要为软件包启用二进制包编译，则列出该软件包的名称，然后在后面指定 `buildpkg-yes.conf`；反之，如果要禁用，则在软件包名称后面指定 `buildpkg-no.conf`。

        通过使用模式表达式，还可以对所有名称符合一定条件的软件包批量启用或禁用二进制包的编译。

        例如：

        ```bash
        # /etc/portage/package.env/buildpkg

        # 为下列软件包编译二进制包
        app-office/libreoffice buildpkg-yes.conf
        llvm-core/llvm buildpkg-yes.conf
        sys-devel/gcc buildpkg-yes.conf
        sys-kernel/vanilla-kernel buildpkg-yes.conf

        # 不为名称符合以下样式的软件包编译二进制包
        */*-bin buildpkg-no.conf
        acct-*/* buildpkg-no.conf
        app-alternatives/* buildpkg-no.conf
        virtual/* buildpkg-no.conf
        ```

        即使已经在 `/etc/portage/make.conf` 中全局启用了 `FEATURES="buildpkg"`，仍然可以通过本方法，为个别软件包禁用二进制包编译。
        {.notice--success}

7. 在容器中，确保需要编译二进制包的软件包在 @world 集合中。仅启用 `FEATURES="buildpkg"` 是不够的：它的作用是“如果安装了这个软件包，那么同时为其生成二进制包”；但假如这句话中的“如果”先决条件未满足的话，后面“那么”的结果也不会发生。例如，无论是全局启用了 `FEATURES="buildpkg"` 还是只为 `app-office/libreoffice` 启用了该选项，只要 `app-office/libreoffice` 不在 @world 中，Portage 在正常情况下就不会安装它，也就从来不会为其生成二进制包。

   最常见的将软件包添加至 @world 的方法是让 Portage 将该软件包记录在 world 文件中（`/var/lib/portage/world`）。例如，以下命令即可将 `app-office/libreoffice` 加至 world 文件：
   ```console
   # emerge --ask --noreplace app-office/libreoffice
   ```

   另一种更为推荐的方法是定义一个新的[自定义软件包集合][gentoo-wiki-etc-portage-sets]，将需要编译二进制包的软件包加进该集合中，然后安装该集合，即可让该集合里的所有软件包都被包含在 @world 中：

   1. 在容器中创建 `/etc/portage/sets` 目录：
      ```console
      # mkdir --parents /etc/portage/sets
      ```

   2. 在上述目录中创建一个新文件，以便定义软件包集合；该文件的名称将成为新软件集合的名称。例如，`/etc/portage/sets/buildpkg` 定义的集合为 @buildpkg。

   3. 在该文件中列出软件包，例如：
      ```bash
      # /etc/portage/sets/buildpkg
      app-office/libreoffice
      sys-kernel/vanilla-kernel
      ```
8. 触发二进制包的编译流程；具体的做法是在容器内重新安装 @world，并应用刚刚自定义的编译器选项和 USE 标志。如果在上一步中定义了新的自定义软件包集合的话，还应确保该集合也将被安装。例如，如果自定义软件包集合叫作 @buildpkg：
   ```console
   # emerge --ask --emptytree @world @buildpkg
   ```

   如果未使用自定义软件包集合，则只需重新安装 @world：
   ```console
   # emerge --ask --emptytree @world
   ```

[gentoo-wiki-binpkg-guide-flags]: https://wiki.gentoo.org/wiki/Binary_package_guide/zh-cn#Handling_.2AFLAGS_in_detail
[wikipedia-intersection-set-theory]: https://zh.wikipedia.org/zh-cn/%E4%BA%A4%E9%9B%86
[wikipedia-union-set-theory]: https://zh.wikipedia.org/zh-cn/%E5%B9%B6%E9%9B%86
[gentoo-handbook-profile]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base/zh-cn#.E9.80.89.E6.8B.A9.E6.AD.A3.E7.A1.AE.E7.9A.84.E9.85.8D.E7.BD.AE.E6.96.87.E4.BB.B6
[gentoo-wiki-etc-portage-sets]: https://wiki.gentoo.org/wiki//etc/portage/sets

[^portage-package-env-dir-requirement]: https://wiki.gentoo.org/wiki//etc/portage/package.env#.2Fetc.2Fportage.2Fpackage.env_must_be_a_directory_for_some_packages_to_work

## 分发二进制包

编译好的二进制包可以通过多种网络协议分发给客户机，包括但不限于 FTP、HTTP/HTTPS、NFS、SSH。Gentoo Wiki 二进制包指南[对其中几种方式进行了介绍][gentoo-wiki-binpkg-guide-dist]。

本小节将介绍一种二进制包指南未提及的方式：nginx HTTP 服务器。

1. 在宿主系统上（而非容器中），安装 nginx。

2. 编辑 nginx 的配置文件（一般位于 `/etc/nginx/nginx.conf`），选定一个 URI，用于向客户机提供二进制包。以下 nginx 配置是最简单的 HTTP 配置（使用 80 端口，并非 HTTPS），在二进制包服务器上的 `/gentoo-binpkgs/amd64` 地址处提供存储于服务器文件系统中 `/var/cache/binpkgs` 目录下的二进制包。

   ```
   http {
       server {
           listen 0.0.0.0;
           listen [::];

           location /gentoo-binpkgs/amd64 {
               alias /var/cache/binpkgs;
               autoindex on;
           }
       }
   }
   ```

   不过，更多用户应该还是更青睐于 HTTPS 服务器而非纯 HTTP 服务器。建立 HTTPS 服务器当然可行，不过前提条件是有个域名以及 TLS 证书；这些话题在本文的范畴以外。

   `autoindex on;` 的设定是可选的；在配置文件中指定该设定后，用户就还可以通过浏览器访问二进制包服务器、查看服务器上有哪些二进制包。

   ![从浏览器查看二进制包服务器上提供的二进制包]({{< static-path img binhost-web.png >}})

[gentoo-wiki-binpkg-guide-dist]: https://wiki.gentoo.org/wiki/Binary_package_guide/zh-cn#.E9.85.8D.E7.BD.AE.E4.BA.8C.E8.BF.9B.E5.88.B6.E5.8C.85.E4.B8.BB.E6.9C.BA

## 自动化二进制包更新的编译

二进制包服务器的系统管理员可以在服务器上配置 Gentoo 软件仓库的自动同步、容器中的 Gentoo 系统的自动更新、以及自动为新 ebuild 编译新二进制包的过程。本小节将讨论使用 systemd 定时器单元实现此种自动化的方法。用这种方法的话，宿主系统自然需要使用 systemd 作为 init 系统；如果宿主系统不使用 systemd 的话，可以使用 cron 定时脚本代替。

1. 在宿主系统上创建一个新的 systemd 服务，用于更新容器中的系统。例如，创建 `/etc/systemd/system/binhost-update.service` 文件，以建立 systemd 服务 `binhost-update.service`，并在该文件中填入以下内容：

   ```ini
   # /etc/systemd/system/binhost-update.service
   [Unit]
   Description=Update the system in the binhost container

   [Service]
   Type=oneshot
   ExecStart=systemd-nspawn --machine=binhost bash -c 'emerge --update --deep --newuse --keep-going --quiet-build --verbose @world && emerge --depclean'
   ```

   此处的 `ExecStart=` 后面的命令假设使用的容器是名称为 `binhost` 的 `systemd-nspawn` 容器。如果实际使用的容器并非如此，请将 `ExecStart=` 后面的命令改为合适的启动容器的命令。
   {.notice--info}

   关于此处 `ExecStart=` 后面的命令的说明如下：

   - 该命令会在容器中运行总共两个命令：一个更新容器中的系统，另一个则在系统更新后清理无用的软件包（`emerge --depclean`）。如果系统更新失败了，清理步骤不会运行，以允许系统管理员进入容器中调查原因、修复问题以重试。因此，两个命令以 `&&` 操作符连接起来，并通过 `bash -c` 作为一个整体传入容器。

   - 更新系统的命令使用 `emerge` 的 `--keep-going` 选项，这样即使单个软件包的编译失败，也不会导致一大堆其它软件包不能被自动更新。

   - 更新系统的命令使用 `emerge` 的 `--quiet-build --verbose` 选项，以在 systemd 的日志中留下便于系统管理员诊断自动更新问题的记录信息。`--quiet-build` 在成功编译软件包时隐藏详细的编译输出内容，只在编译出错时显示详细信息；`--verbose` 让 `emerge` 在开始编译所有软件包前显示的编译列表中提供更详细的信息输出。

     {{<div class="notice--success">}}
在宿主系统上运行以下命令，可以在 systemd 日志中查看自动更新的记录：

```console
$ journalctl --all --unit binhost-update.service
```
     {{</div>}}

2. 在宿主系统上再创建一个 systemd 服务，用于同步容器中的软件仓库。例如，创建 `/etc/systemd/system/binhost-emerge-sync.service` 文件，并填入以下内容：

   ```ini
   # /etc/systemd/system/binhost-emerge-sync.service
   [Unit]
   Description=Update ebuild repositories in the binhost container
   After=network-online.target
   Wants=binhost-update.service
   Before=binhost-update.service

   [Service]
   Type=oneshot
   ExecStart=systemd-nspawn --machine=binhost emerge --sync
   ```

   `Wants=` 和 `Before=` 选项将在每次此服务同步完软件仓库后，触发 `binhost-update.service` 所执行的系统更新。

3. 在宿主系统上创建一个 systemd 定时器单元，用于自动触发软件仓库的同步。默认情况下，如果同步软件仓库的服务叫 `binhost-emerge-sync.service`，那么其对应的定时器单元就应该叫 `binhost-emerge-sync.timer`。

   ```ini
   # /etc/systemd/system/binhost-emerge-sync.timer
   [Unit]
   Description=Periodically update ebuild repositories in the binhost container
   After=network-online.target

   [Timer]
   OnCalendar=Sat *-*-* 00:00:00
   Persistent=true

   [Install]
   WantedBy=timers.target
   ```

   系统管理员可以自行定制此文件中 `[Timer]` 部分的内容，以在不同的时间或根据不同的规则触发软件仓库的同步以及容器内系统的更新。如需更多信息，可参阅 [`systemd.timer(5)`][man-systemd.timer-options] 手册页面。

4. 在宿主系统上启用刚创建的定时器单元。下列命令虽然只启动定时器单元本身，但定时器会触发自动同步软件仓库的服务，而自动同步软件仓库的服务还会在同步完成后触发自动更新容器内系统的服务，因此只需这一条命令就可以启动整套流程的定时运转。
   ```console
   # systemctl enable --now binhost-emerge-sync.timer
   ```

[man-systemd.timer-options]: https://man.archlinux.org/man/core/systemd/systemd.timer.5.en#OPTIONS

## 在客户机及 Gentoo 宿主系统上使用二进制包

在二进制包服务器上配置好二进制包的编译和分发后，就可以配置客户机从服务器上获取二进制包了。如果二进制包服务器的宿主系统本身是 Gentoo，还可以让宿主系统直接在本地读取并使用由容器编译好的二进制包。

配置客户机的具体步骤取决于分发二进制包的方法。分发二进制包的方法可归为两类：

- 客户机在 `/var/cache/binpkgs` 处**挂载**存有所有可用的二进制包的文件系统。在运行 `emerge` **之前**，在客户机的 `/var/cache/binpkgs` 目录下就已经可以读取所有可用的二进制包。NFS 共享、SSHFS 等都属于此类方法。
  - Gentoo 宿主系统在本地读取容器编译出的二进制包也应该视为此类方法。

- 客户机在 `emerge` 运行**期间**将二进制包**下载**到 `/var/cache/binpkgs`。运行 `emerge` 之前，客户机的 `/var/cache/binpkgs` 目录下可能没有稍后要安装的二进制包。HTTP、HTTPS、纯 SSH（即使用 `ssh://` URI，而非通过 SSHFS 等方式）都属于此类方法。

### 客户机挂载文件系统，或 Gentoo 宿主系统

注意：如果正在配置 Gentoo 宿主系统直接在本地读取并使用由容器编译好的二进制包，那么在执行以下步骤时，应将 Gentoo 宿主系统视为“客户机”。

1. 在每台客户机上，确保包含二进制包的文件系统在运行 `emerge` 前挂载。具体的操作步骤取决于分发二进制包时使用的网络协议（NFS、SSHFS 等），但通常都涉及到编辑客户机的 `/etc/fstab`。Gentoo Wiki 二进制包指南中[对 NFS 的相关说明][gentoo-wiki-binpkg-guide-nfs]可作为示例参考。

2. 如果客户机的用户希望每次运行 `emerge` 时都通过命令行选项指定是否要使用二进制包，而非始终使用二进制包，那么用户在想使用二进制包时，在 `emerge` 的命令行中指定 `--usepkg` 选项即可。

   如果用户希望始终使用任何可用的二进制包，那么应将以下选项加至客户机的 `/etc/portage/make.conf` 中：
   ```bash
   EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --usepkg"
   ```

   无论是何种情况，用户都可以通过指定 `emerge` 命令行选项 `--usepkg=n` 来让 `emerge` 暂时不使用二进制包。

[gentoo-wiki-binpkg-guide-nfs]: https://wiki.gentoo.org/wiki/Binary_package_guide/zh-cn#NFS_.E5.AF.BC.E5.87.BA

### 客户机下载二进制包

1. 在每台客户机上，确保 `/etc/portage/binrepos.conf` 目录存在：
   ```console
   # mkdir --parents /etc/portage/binrepos.conf
   ```

2. 在客户机的 `/etc/portage/binrepos.conf` 目录下，为二进制包服务器创建一个新的配置文件，如 `/etc/portage/binrepos.conf/custom-binhost.conf`。在该文件中指定二进制包服务器的 URI（应以 `http://`、`https://`、或 `ssh://` 等前缀开头）。
   ```ini
   # /etc/portage/binrepos.conf/custom-binhost.conf
   [custom-binhost]
   sync-uri = https://example.com/gentoo-binhost/amd64
   priority = 10
   ```

   如需更多信息和例子，可参考 Gentoo Wiki 二进制包指南中的[相关部分][gentoo-wiki-binpkg-guide-binrepos.conf]。

3. 如果客户机的用户希望每次运行 `emerge` 时都通过命令行选项指定是否要使用二进制包，而非始终使用二进制包，那么用户在想使用二进制包时，在 `emerge` 的命令行中指定 `--getbinpkg` 选项即可。

   如果用户希望始终使用任何可用的二进制包，那么可以采用以下两种方式的任意一种来配置客户机：

   - 将以下选项加至客户机的 `/etc/portage/make.conf` 中：
     ```bash
     FEATURES="getbinpkg"
     ```

     如果用户希望让 `emerge` 暂时不使用二进制包，应使用环境变量 `FEATURES="-getbinpkg"` 运行 `emerge`，例如：
     ```console
     # FEATURES="-getbinpkg" emerge --ask app-office/libreoffice
     ```

   - 将以下选项加至客户机的 `/etc/portage/make.conf` 中：
     ```bash
     EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --getbinpkg"
     ```

     如果用户希望让 `emerge` 暂时不使用二进制包，应指定 `emerge` 命令行选项 `--getbinpkg=n`。

[gentoo-wiki-binpkg-guide-binrepos.conf]: https://wiki.gentoo.org/wiki/Binary_package_guide#Pulling_packages_from_a_binary_package_host

## 延伸：搭建 rsync 镜像

由于二进制包服务器上至少会有一份给容器使用的 Gentoo 软件仓库数据库、且服务器已经在为客户机提供二进制包了，因此还可以让服务器为客户机提供 Gentoo 软件仓库的 rsync 镜像，这样客户机就可以连接同一台服务器实现获取二进制包和同步软件仓库的双重目的。

对管理好几台 Gentoo 系统的系统管理员而言，搭建自己的 rsync 镜像尤其有用。如果这些系统都在同一个局域网中，在局域网内搭建 rsync 镜像有如下好处：
- 在客户机上运行 `emerge --sync` 时，局域网内的 rsync 镜像比默认的 `rsync.gentoo.org` 服务器速度更快。
- “Gentoo 网络礼仪”称，每位用户从 `rsync.gentoo.org` 同步软件仓库的频率不应超过一天一次，若同步过于频繁可能会被屏蔽[^gentoo-rsync-mirrors]。如果系统管理员选择在同一天更新局域网内的所有客户机、且所有客户机都从 `rsync.gentoo.org` 服务器同步软件仓库，那在服务器看来，同一个局域网在一天之内同步的次数就可能过多，导致局域网被屏蔽。而通过在局域网内搭建 rsync 镜像，每次更新所有客户机时，整个局域网就只需要与 `rsync.gentoo.org` 同步一次。

使用 Git 仓库替代 rsync 同样能达成这些益处，不过这需要在每台客户机上都安装 `dev-vcs/git`。rsync 是每台 Gentoo 系统上默认都有的，但 Git 不是。因此，如果有客户机因为任何原因没安装 Git，那么本地 rsync 镜像就仍然是更合适的选择。

以下步骤将在二进制包服务器上搭建 rsync 镜像：

1. 在宿主系统上安装 rsync。

2. 假设宿主系统本身在 `/var/db/repos/gentoo` 位置下有一份 Gentoo 软件仓库数据库（可通过容器上的绑定挂载实现，或者可以是由于宿主系统已经是 Gentoo），那么在宿主系统的 `/etc/rsyncd.conf` 中添加以下内容：
   ```ini
   [gentoo-portage]
       path = /var/db/repos/gentoo
       comment = Gentoo ebuild repository
       exclude = /distfiles /packages /lost+found
   ```

   如果宿主系统已经运行 Gentoo，那么 `/etc/rsyncd.conf` 中应该已经包含以上内容，只不过被注释掉了。这种情况下，只需撤销注释即可。
   {.notice--success}

3. 在宿主系统上启动 rsync 守护进程。具体请参考 Gentoo Wiki 上[给出的步骤][gentoo-wiki-rsync-service]；即使宿主系统是其它发行版，同样可以参考，且无论 init 系统是 OpenRC 还是 systemd，都有相应的操作说明。

4. 在每台客户机上执行以下步骤：

   1. 确保 `/etc/portage/repos.conf` 目录存在：
      ```console
      # mkdir --parents /etc/portage/repos.conf
      ```

   2. 如果 `/etc/portage/repos.conf` 目录下还没有对应 Gentoo 软件仓库的配置文件，创建该配置文件：
      ```console
      # cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf
      ```

   3. 在 `/etc/portage/repos.conf` 目录下对应 Gentoo 软件仓库的配置文件中，找到下面一行选项：
      ```ini
      sync-uri = rsync://rsync.gentoo.org/gentoo-portage
      ```

      将 `sync-uri` 的域名部分改为二进制包服务器的域名或 IP 地址，例如：
      ```ini
      #sync-uri = rsync://rsync.gentoo.org/gentoo-portage
      sync-uri = rsync://example.com/gentoo-portage
      ```

[gentoo-wiki-rsync-service]: https://wiki.gentoo.org/wiki/Rsync#Service

[^gentoo-rsync-mirrors]: https://www.gentoo.org/support/rsync-mirrors/

## 更多资源

- Gentoo Wiki 上的[二进制包指南][gentoo-wiki-binpkg-guide]中还对一些本文中未提及的二进制包服务器的配置和维护任务进行了介绍。

- GitHub 上的 [hartwork/binary-gentoo][github-hartwork-binary-gentoo] 项目提供了另一种配置二进制包服务器的方法所需的工具。无论是否使用该项目中的工具，都可以参考它的 README 文件中对确保编译器选项和 `CPU_FLAGS_*` USE 标志的兼容性给出的[很好的操作流程描述][github-hartwork-binary-gentoo-readme-flags]。

[gentoo-wiki-binpkg-guide]: https://wiki.gentoo.org/wiki/Binary_package_guide
[github-hartwork-binary-gentoo]: https://github.com/hartwork/binary-gentoo
[github-hartwork-binary-gentoo-readme-flags]: https://github.com/hartwork/binary-gentoo?tab=readme-ov-file#determining-ideal-build-flags
