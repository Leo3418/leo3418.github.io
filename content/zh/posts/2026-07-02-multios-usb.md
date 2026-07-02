---
title: "用 MultiOS-USB 制作多引导可启动 U 盘"
tags:
  - Windows
  - GNU/Linux
categories:
  - 博客
toc: true
---

在为了安装操作系统而制作可启动 U 盘时，如果制作多引导 U 盘，就可以免除每次需要启动新 ISO 时都要擦除 U 盘上原有数据的烦恼。我在了解到多引导 U 盘的存在前，一直都是用传统的可启动 U 盘制作工具，比如 [Rufus]，而传统工具的缺点就是，如果想用 U 盘启动不同的 ISO，就需要重新运行工具，并覆写 U 盘上原有的数据。多引导 U 盘就解决了这一缺点。比如说，如果我只有一块 U 盘，已经在上面写入了 Windows 安装盘的 ISO，而我现在想启动某 GNU/Linux 发行版的 ISO，并且这块 U 盘支持多引导，那么我只需要把 GNU/Linux 发行版的 ISO *复制*到 U 盘上即可；等我使用 U 盘引导时，我可以选择是启动 Windows 的 ISO 还是 GNU/Linux 发行版的。我仍然能保留并且启动原来的 Windows ISO，无需将其覆盖。除此以外，我只需要简单地使用文件管理器或者 `cp` 命令就可以将新 ISO 装载到 U 盘上，不需要重新运行任何特别的工具或是复杂的命令。

一开始，我是用 [Ventoy] 来制作多引导 U 盘，使用起来也是一切正常。到后来，我和一些其他用户一样，对 Ventoy 的安全性开始有了[担忧][wikipedia-ventoy-blobs]。Ventoy 的内部实现看起来混乱复杂，难以对其进行审计，也就难以完全信任它。制作可启动 U 盘的工具，对使用制作出的 U 盘安装的系统的安全性有直接的影响，因为从技术角度而言，可启动 U 盘制作工具是可以在系统安装过程中篡改新系统的文件的，并且这种事情以前确实发生过。十多年前，我混迹的某论坛上的用户都建议网友远离某桃、某菜之类的工具，就是因为这些工具会恶意篡改用它们做出的 U 盘装的 Windows 系统，例如预装垃圾软件、修改浏览器主页等。虽然 Ventoy 目前还没有被曝出向装好的系统中强行植入广告的案例，但在内部实现混乱复杂的情况下，谁能保证它不会对系统进行任何其它隐蔽的修改呢？

最近，我读到了 [Arch Linux 维基上关于多引导 U 盘的词条][archwiki-multiboot-usb-drive]，了解到了一些替代工具，遂决定换用新工具取代 Ventoy。该词条仅仅列出三个 Ventoy 的替代选项，所以我的选择不多。好在其中的 [MultiOS-USB] 对我而言是十分理想的选择，满足我对多引导 U 盘制作工具的所有需求：

- 与 Windows 和主流 Linux 发行版的安装盘 ISO 的兼容性。我简单看了下另外两个替代选项的 GitHub 仓库，发现它们似乎都不支持 Windows ISO。

- 更清晰透明的内部实现；否则的话，我为什么不继续用 Ventoy 呢？截至撰文时，MultiOS-USB 项目仓库的布局非常简洁明了，只有 7 个顶层目录，而 Ventoy 有 34 个。MultiOS-USB 只捆绑 7 个软件包的预编译二进制可执行文件，并且清晰地交代了每个软件包的编译方法、源码来源、以及补丁，[比如 GRUB][multios-usb-grub-readme]。

于是，我拿出了我装系统用的 U 盘，在上面安装了 MultiOS-USB，然后折腾了一下，让它能实现我之前使用 Ventoy 时用到的所有功能。经过一番操作后，我成功达成了用 MultiOS-USB 完全取代 Ventoy 的目的。

[Rufus]: https://rufus.ie/zh/
[Ventoy]: https://www.ventoy.net/cn/
[wikipedia-ventoy-blobs]: https://en.wikipedia.org/wiki/Ventoy#Binary_blob_controversy
[archwiki-multiboot-usb-drive]: https://wiki.archlinux.org/title/Multiboot_USB_drive#Automated_tools
[MultiOS-USB]: https://github.com/Mexit/MultiOS-USB
[multios-usb-grub-readme]: https://github.com/Mexit/MultiOS-USB/blob/v0.11.1/binaries/grub-v2.14-1/ReadMe.txt

## Windows 10 LTSC

我遇到的第一个问题是 MultiOS-USB 是否支持 Windows 10 LTSC 的 ISO。我先是试着将 LTSC 的 ISO 复制到了 U 盘上的 `ISOs` 目录下，但 MultiOS-USB 的启动菜单里并没有显示该 ISO。[MultiOS-USB 的兼容性列表][multios-usb-supported-os]里列出了 Windows 10，但它指的应该是非 LTSC 的普通版本的 Windows 10，对应的是默认文件名类似于 `Win10_22H2_Chinese_Simplified_x64v1.iso` 的 ISO。

后来我发现，MultiOS-USB 是支持 LTSC ISO 的；只需将 LTSC ISO 重命名，让其符合 `Win1*_*_x64*.iso` 的样式即可。MultiOS-USB 是通过匹配文件名来检测 ISO 的，文件名匹配规则在[配置文件][multios-usb-windows-cfg]中定义，而上述的匹配样式就是 MultiOS-USB 针对 Windows ISO 的配置文件中所定义的样式。LTSC ISO 的默认文件名类似于 `en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso`，显然与该样式不符。

[multios-usb-supported-os]: https://github.com/Mexit/MultiOS-USB/blob/v0.11.1/docs/Supported_OS.md
[multios-usb-windows-cfg]: https://github.com/Mexit/MultiOS-USB/blob/v0.11.1/config/windows/windows_iso.cfg#L4

## DaRT 10

[微软诊断和恢复工具集 (DaRT) 10][dart10] 是附带了一些微软官方的系统恢复工具和实用工具的 Windows PE 环境；其中的工具包括登录密码移除器、注册表编辑器、已删除文件恢复工具、文件管理器、硬盘擦除工具等。微软并不是直接给用户一个可启动的 DaRT 10 ISO，而是给了用户一个应用程序，让他们用该程序自己制作可启动 ISO，并可以自选要在 ISO 中包含哪些工具。

一段时间前，我曾做过一个 DaRT 10 ISO，并把它放在了 U 盘上，以备不时之需。Ventoy 是可以启动该 ISO 的。现在，为了让 MultiOS-USB 能启动该 ISO，我像之前重命名 Windows 10 LTSC ISO 那样，也改了 DaRT 10 ISO 的文件名，遵循了同样的文件名样式。毕竟 DaRT 10 和相对近期的 Windows 版本的安装盘都是基于 Windows PE，所以我推断，如果 MultiOS-USB 能启动普通的 Windows 安装盘 ISO，那么它也能启动 DaRT 10。

然而，我一开始未能让 MultiOS-USB 成功启动 DaRT 10。我能让 MultiOS-USB 检测到它的 ISO 并引导它，能看到启动界面的 Windows 徽标和动画；但是，到了该显示图形界面的时候，系统却会黑屏几秒，然后就自己重启了。有相当一段时间，我都没搞清楚原因，因此以为是 MultiOS-USB 不兼容 DaRT 10。

忽然有一天，我偶然地意识到了为什么 DaRT 10 无法启动，于是进行了必要的调整，最终成功让 MultiOS-USB 兼容 DaRT 10。当时，我在看 MultiOS-USB 针对 Windows ISO 的配置文件，忽然注意到了其中一个叫 [`Winpeshl.ini`][multios-usb-winpeshl.ini] 的文件，不知道它有什么作用。我好奇地上网搜了一下，发现它就相当于 Windows PE 的启动脚本；Windows PE 启动时，会自动运行该文件中列出的程序。MultiOS-USB 的 `Winpeshl.ini` 文件中列出了两个程序：`mountiso.exe` —— MultiOS-USB 自己的程序，用于在 Windows PE 中挂载当前已引导的 ISO，以及 `x:\setup.exe` —— Windows 安装盘上的安装程序。`x:\setup.exe` 对于普通的 Windows 安装盘 ISO 而言是合理的，但 DaRT 10 的 ISO 中并没有 `setup.exe`，所以 MultiOS-USB 的 `Winpeshl.ini` 在 DaRT 10 上就会失效。为了找出能使 DaRT 10 正常工作的 `Winpeshl.ini` 内容，我在虚拟机里启动了 Dart 10 ISO，在其中打开了 `X:\Windows\System32\winpeshl.ini`（即该文件在 DaRT 10 中的完整路径），然后看到了如下内容：

```ini
[LaunchApps]
%windir%\system32\netstart.exe,-prompt
%SYSTEMDRIVE%\sources\recovery\recenv.exe
```

![在 DaRT 10 中打开的 `Winpeshl.ini`]({{< static-path img dart10-winpeshl.png >}})

这就意味着 DaRT 10 需要和普通 Windows ISO 不同的 `Winpeshl.ini` 文件，也就意味着 DaRT 10 需要单独的 MultiOS-USB 配置。以下是我创建单独配置的流程：

1. 在 U 盘上的 `MultiOS-USB` 目录下，将 `config/windows` 目录复制到 `config_priv` 目录当中。同时，可选择将复制后 `config_priv` 下的新目录重命名为 `DaRT10` 之类的名字。`config_priv` 是 MultiOS-USB 为自定义配置保留的目录；当用户更新 MultiOS-USB 的新版本时，`config_priv` 目录下的内容不会受到任何影响，但 `config` 目录下的配置文件会被覆写。

   例如，可用以下 Unix 命令复制文件：
   ```console
   $ cd MultiOS-USB
   $ cp -r config/windows config_priv/DaRT10
   ```

2. 在刚复制到 `config_priv` 下的新目录中（上文的示例中，该目录被命名为 `DaRT10`），打开 `windows_iso.cfg` 文件，进行如下修改：

   - 将文件顶部的 `iso_pattern` 变量的值修改为符合 DaRT 10 ISO 文件名的样式，例如：
     ```diff
     - iso_pattern="Win1*_*_x64*.iso"
     + iso_pattern="DaRT10*.iso"

       for isofile in ($dev,*)$iso_dir/$iso_pattern; do
       	  if [ -e "$isofile" ]; then
     ```

   - 在接近文件尾部的位置，找到含有 `Winpeshl.ini` 字样的一行，然后将该行中的 `config/windows` 部分替换为该新目录的路径（例如 `config_priv/DaRT10`）：
     ```diff
       	$wimboot_initrd newc:boot.wim:(loop)/sources/boot.wim \
	  			newc:mountIso.exe:/MultiOS-USB/tools/mountiso/mountiso64.exe \
	  			newc:grubenv:($dev,1)/grub/grubenv \
	 -			newc:Winpeshl.ini:/MultiOS-USB/config/windows/Winpeshl.ini
	 +			newc:Winpeshl.ini:/MultiOS-USB/config_priv/DaRT10/Winpeshl.ini
     ```

3. 继续修改同一目录下的 `Winpeshl.ini`，将 `x:\setup.exe` 替换为 DaRT 10 启动时运行的程序命令：
   ```diff
     [LaunchApps]
     mountiso.exe
   - x:\setup.exe
   + %windir%\system32\netstart.exe,-prompt
   + %SYSTEMDRIVE%\sources\recovery\recenv.exe
   ```

完成这些操作后，MultiOS-USB 就可以正常启动 DaRT 10 了。

[dart10]: https://learn.microsoft.com/zh-cn/microsoft-desktop-optimization-pack/dart-v10/
[multios-usb-winpeshl.ini]: https://github.com/Mexit/MultiOS-USB/blob/v0.11.1/config/windows/Winpeshl.ini

## 安全启动

MultiOS-USB 支持安全启动。在启用了安全启动的系统上，需要先[导入 MultiOS-USB 的证书][multios-usb-enroll-cert]，然后方可引导 MultiOS-USB。这一点和 Ventoy 相同。

MultiOS-USB 与 Ventoy 不同的是，使用 MultiOS-USB 启动 Linux 发行版的 ISO 前，需要先导入该发行版的证书才行，否则 GRUB （MultiOS-USB 依赖的引导程序）会提示[“bad shim loader signature”错误][grub-2.14-shim_lock]，并拒绝启动该 ISO。而 Ventoy 会无条件启动任何 ISO，甚至包括未由已导入的证书签名的 ISO，因此用户无需再额外导入证书。我认为这其中的原因是，Ventoy [在自己修改后的 GRUB 2.04][ventoy-grub-core]（即 Ventoy 依赖的引导程序）中删除了 `shim_lock` 模块，但[原版 GRUB 2.04][grub-2.04-shim_lock] 中是有这个模块的。由于没有这个模块，Ventoy 的 GRUB 也就没有强制检查安全启动签名的代码了。这样一来，Ventoy 使用起来相对更方便，不过代价是安全性：任何 ISO，包括使用机主不信任的、未导入的证书签名的、不可信的 ISO，都可以使用 Ventoy 启动。

截至 MultiOS-USB 0.11.1 版本，即截至撰文时的最新版本，MultiOS-USB 不支持在启用了安全启动的状态下引导 Windows 安装盘 ISO。这是因为 Windows ISO 使用的文件系统是 UDF，而 [GRUB 在安全启动环境下是不支持 UDF 的][grub-disable-fs-lockdown]。根据 MultiOS-USB 项目的开发活动判断，我相信 MultiOS-USB 以后会支持在安全启动被启用时引导 Windows ISO：在用于公布 MultiOS-USB 对 GRUB 源码的改动的代码仓库中有一个分支，里面已经可以找到[重新启用 GRUB 在安全启动环境下对 UDF 的支持的补丁][multios-usb-grub-enable-udf]。经由我的测试可以确认，该补丁可以达到允许 MultiOS-USB 在启用了安全启动时引导 Windows ISO 的效果。为了测试该补丁，我下载了该仓库的 CI/CD [带着该补丁自动编译出的 GRUB 文件][multios-usb-efi_enable_udf-artifact]，将其中的 `grubx64.efi` 解压到我 U 盘 `MultiOS-EFI` 分区下的 `EFI/BOOT/grubx64.efi` 路径，然后[对 `EFI/BOOT/grubx64.efi` 进行签名][archwiki-shim]，并确保签名所使用的证书已经在我的机器上导入。

[multios-usb-enroll-cert]: https://github.com/Mexit/MultiOS-USB/tree/v0.11.1#first-use
[grub-2.14-shim_lock]: https://gitlab.freedesktop.org/gnu-grub/grub/-/blob/grub-2.14/grub-core/kern/efi/sb.c#L198
[ventoy-grub-core]: https://github.com/ventoy/Ventoy/tree/v1.1.12/GRUB2/MOD_SRC/grub-2.04/grub-core/commands/efi
[grub-2.04-shim_lock]: https://gitlab.freedesktop.org/gnu-grub/grub/-/blob/grub-2.04/grub-core/commands/efi/shim_lock.c?ref_type=tags
[grub-disable-fs-lockdown]: https://gitlab.freedesktop.org/gnu-grub/grub/-/commit/c4bc55da28543d2522a939ba4ee0acde45f2fa74
[multios-usb-grub-enable-udf]: https://gitlab.com/MultiOS-USB/grub/-/blob/efi_enable_udf/0008-enable-udf.patch?ref_type=heads
[multios-usb-efi_enable_udf-artifact]: https://gitlab.com/MultiOS-USB/grub/-/jobs/14794248390/artifacts/file/grub-.tar.gz
[archwiki-shim]: https://wiki.archlinuxcn.org/wiki/UEFI/%E5%AE%89%E5%85%A8%E5%90%AF%E5%8A%A8#shim%E4%B8%8E%E5%AF%86%E9%92%A5
