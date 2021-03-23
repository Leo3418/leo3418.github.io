---
title: "通过 Portage 打补丁以修复上游软件 Bug"
lang: zh
tags:
  - Gentoo
  - GNU/Linux
categories:
  - 博客
toc: true
asciinema-player: true
---
{% include img-path.liquid %}
如果您经常关注与自由软件相关的一手资讯，您肯定或多或少地读到过某款软件的 bug 最近被修复、或者某款软件有了什么新功能和改进的新闻，然后发现这些 bug 修复和新功能在一段时间内无非就是空气，因为实际收到包含这些修复或者改进的新版本的时候往往可能已经过了很长时间。当一个修复 bug 或者添加新功能的补丁被完成后，需要先提交给上游开发者进行审核、测试和整合，然后要等上游发布下个版本的时候才能正式生效，最后还要等您的发行版将新的上游版本添加到发行版自己的软件仓库，您才能收到包含该 bug 修复或新功能的更新。比如说，我们假设可能在今年 3 月发布的 GNOME 40 里包含一项 bug 修复。如果您使用的是 Fedora Workstation，您需要等到大概 4 月底，Fedora 34 推出的时候才能收到这项 bug 修复。如果是 Gentoo 的话，那我估计起码得等到今年下半年了，因为最近几次 GNOME 更新，Gentoo 都是在上游推出新版本之后过了将近半年才推送给用户的。

作为一名普通用户，对于软件上游的新版本，我们能做的似乎只有等待。但是这一等很可能就是好几个月。如果您遇到了妨碍您系统的正常运行和使用的 bug，那么上游推出 bug 的修复补丁之后，您肯定是希望立刻应用该补丁。对于一个严重影响日常使用的 bug，这几个月的更新推送耗时可能根本等不起。

但是，如果您使用 Gentoo 的话，得益于大部分软件包都需要自己编译的特点，您可以在编译的时候自行将上游补丁应用到被编译的软件源码，从而在 Gentoo 推送包含该补丁的更新之前就解决该 bug。Portage 的[用户补丁][user-patch]（英文网页）功能允许用户轻松地在通过系统软件包管理器安装软件时应用自己的补丁。

上周五，我在进行每周例行的系统更新的时候，竟然一连串遇到三个来自不同软件包的 bug！这些 bug 其实都已经有了来自上游的修复补丁，但是因为上面描述的由上游新版本发布以及发行版方面造成的延迟，如果我自己什么也不做的话，那估计就要过好几周乃至好几个月才能接收到相关的软件更新了。我在这篇文章里就将以这三个 bug 为例，演示如何借助 Portage 的用户补丁功能，自行应用上游补丁，即刻修复软件 bug。妈妈再也不用担心我每天盼星星盼月亮，就是盼不来软件 bug 修复的推送了。

[user-patch]: https://wiki.gentoo.org/wiki//etc/portage/patches

## `systemd-rfkill` 单元启动失败

- 受影响的软件包：[`sys-apps/systemd`][systemd-gentoo]
- Bug 报告：<https://github.com/systemd/systemd/issues/18677>
- 修复补丁：<https://github.com/systemd/systemd/pull/18679>

这次系统更新中，systemd 被从 246 升级到了 247。更新完后，我就在开机时留意到了一个一闪而过的单元失败提示；进入系统后一查，发现是 `systemd-rfkill.service`：

![Linux 5.11 上 systemd-rfkill.service 的状态]({{ img_path }}/rfkill-5.11.png)

我一开始自然以为是 systemd 更新造成的问题，于是回滚到了 systemd 246，但是问题依然存在。这样看来，这个错误的始作俑者并不是新的 systemd 版本中的退化，而多半是其它近期有变化的系统组件。于是我想到了内核，因为近期我也是刚从 5.10 的内核升级到了 5.11。我恰巧留了一个之前编译的 5.10 内核，于是就用 5.10.17 的内核加 systemd 247 启动了系统，看还会不会发生同样的错误。这次，虽然 `systemd-rfkill.service` 不再失败了，但是当我查看它的详细状态的时候，还是看到了几条错误信息。也就是说，其实这个问题在我还在用 5.10 内核的时候就有了，只不过当时并没有明显的报错，所以我一直没有注意到罢了。

![Linux 5.10 上 systemd-rfkill.service 的状态]({{ img_path }}/rfkill-5.10.png)

我就把这些错误信息拿到网上搜索了一下，于是就来到了上面链接对应的 GitHub 上的 bug 报告。报告里描述的错误信息和我看到的错误完全一致。幸运的是，那个 GitHub issue 正好有一个对应的 pull request，而且还已经被合并了，所以我决定应用一下那个 pull request 里的补丁，来尝试解决这个问题。

那么问题来了，怎样把一个 GitHub pull request 变成一个补丁呢？无独有偶，我当时看这个 pull request 的时候，网页下方正好有一个完美回答我的问题的提示，说是直接往网址后面加 `.patch` 后缀即可：

![如何下载 GitHub pull request 对应的补丁的小提示]({{ img_path }}/github-pr-to-patch.jpg)

```diff
- https://github.com/systemd/systemd/pull/18679
+ https://github.com/systemd/systemd/pull/18679.patch
```

这个补丁是要应用给 `sys-apps/systemd` 的，因此应该被放置在 `/etc/portage/patches/sys-apps/systemd` 路径下。您还可以在路径后面[加上版本号信息][patch-specific-ver]，可以只对 systemd 247 应用该补丁，不过这不是必须的。我就选择了不指定具体的版本，因为我实测这个补丁与 systemd 246 和 247 都兼容。不过，这也意味着等到 Gentoo 推送了来自上游的新 systemd 版本，并且该版本中已经应用了这个补丁的时候，我需要将该补丁删除。

{% include asciinema-player.html name="portage-add-patch.cast"
    poster="data:text/plain,从命令行添加用户补丁" %}

补丁就位后，需要重新构建软件包，才能将其应用：

```console
# emerge --ask --oneshot sys-apps/systemd
```

如果 `emerge` 命令输出中有“User patches applied”字样，就说明补丁成功应用了：

{% include asciinema-player.html name="emerge-patch-applied.cast"
    poster="data:text/plain,重新构建软件包
            \x1b[G
            \x1b[G注意：我这里为了精简命令输出，用了 '--quiet' 选项，但这个选项不是必须的" %}

[systemd-gentoo]: https://packages.gentoo.org/packages/sys-apps/systemd
[patch-specific-ver]: https://wiki.gentoo.org/wiki//etc/portage/patches#Adding_user_patches

重新构建完 systemd 后，我重启了系统，`systemd-rfkill.service` 就不再报错，可以正常启动了。

## GNOME 和 systemd 用户单元造成关机 2 分钟延迟

- 受影响的软件包：[`gnome-base/gnome-session`][gnome-session-gentoo]
- Bug 报告：<https://gitlab.gnome.org/GNOME/gnome-session/-/issues/74>
- 修复补丁：<https://gitlab.gnome.org/GNOME/gnome-session/-/merge_requests/55>

其实 `systemd-rfkill.service` 启动失败并没有造成明显的问题，所以即使我一时修复不了也罢，系统仍然能正常使用。但是另一个问题在关机的时候出现了：一个关机任务会卡住。尽管系统会给它 2 分钟的时间让它完成，但它是彻底卡住了，根本无法在给定的时间内完成，所以一直都是 2 分钟过后，这个任务因为超时被强制结束，关机过程才得以继续。这样一来，实际就相当于关机时间被强制加长了 2 分钟，可以说是已经影响到了日常的使用，必须尽快解决。

![系统关机时卡在一个关机任务上]({{ img_path }}/poweroff-delay.jpg){: .half}

与前面服务启动失败的 bug 不同，这个问题在我回滚到 systemd 246 后就消失了，所以很可能是 systemd 247 中的什么变动导致了它的出现。因此，我在网上搜索“*systemd 247 a stop job is running for user manager for uid*”，然后就找到了上面链接对应的 GNOME GitLab 上的 bug 报告。从报告里面用户和开发者之间的讨论来看，这个 bug 会在用户使用 GNOME 和 [systemd 用户单元][systemd-user-unit]时出现，并且的确是 systemd 247 中的一项更改造成的，不过 bug 的修复却是在 GNOME 中进行的。

同样地，这个 bug 报告也有一个关联的 merge request（GitLab 对 pull request 的叫法）。GitLab 把下载 merge request 对应的补丁的功能设计得更明显，页面上直接放了一个下载按钮。这里无论是下载“Email patches”还是“Plain diff”都可以，Portage 都会接受，但我推荐“Email patches”，因为它带 Git 提交信息，在日后您忘了这个补丁是干什么的时候可以帮您回想起它的作用。

![下载 GitLab merge request 对应的补丁]({{ img_path }}/gitlab-mr-to-patch.png)

安装这个补丁的方法和上一节中介绍的方法一样。我重新构建了软件包之后，第一次关机仍然会有这 2 分钟的延迟，但是之后再关机就非常顺畅了，没有任何问题。

那如果我不通过 Portage 自己应用修复这个 bug 的补丁，而是等更新到 GNOME 40 来解决这个问题的话，大概要等多久呢？现在最新的 GNOME 上游版本，也就是 GNOME 3.38，在 Gentoo 上仍然还没有推出呢。目前 Gentoo 自带的最新版本是 3.36，是 2020 年 8 月正式推送给 Gentoo 用户的，也就是上游发布后过了近 5 个月才推送的。因此，我估计要直到今年 9 月份才能收到这个 bug 的修复，也就意味着接下来 6 个月我都得忍受这个关机延迟 2 分钟的问题。

[gnome-session-gentoo]: https://packages.gentoo.org/packages/gnome-base/gnome-session
[systemd-user-unit]: https://wiki.archlinux.org/index.php/Systemd_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/User_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)

## 使用 AMD 锐龙 4000 系列 CPU 的笔记本运行 Linux 5.11 时关机后自动重新开机

- 受影响的软件包：Linux 内核
- Bug 报告：<https://gitlab.freedesktop.org/drm/amd/-/issues/1499>
- 修复补丁：<https://gitlab.freedesktop.org/drm/amd/uploads/b7b5a131c5df5143cb37cc6f9b784871/0001-drm-amdgpu-fix-shutdown-with-s0ix.patch>

说实话，其实关机 2 分钟延迟也不是完全不能忍，用这个时间起来活动一下筋骨、放松一会儿，也挺好的。但是这 2 分钟熬过去就算完了吗？并没有：当系统完成关机、我笔记本的电源指示灯熄灭后，没几秒钟，笔记本竟然在没有任何操控的情况下，自己重新开机了！

这个现象只会在 Linux 5.11 上出现，我用 5.10 内核启动就不会遇到这个问题。和前面两个 bug 一样，我依然找到了一个这个 bug 的报告。报告者反映称其一台宏碁 SF314-42 笔记本，配置 Ryzen 5 4500U、运行 Linux 5.11 内核，在关机时会卡住或者自动重启。我的配置是惠普 Envy x360 13-ay0000 和 Ryzen 7 4700U，并且我是只看到过自动重启。不过，报告者和我用的内核版本一样，并且我们的笔记本上的 CPU 还都是 Renoir 架构的锐龙 4000 系笔记本 CPU 系列。报告者还试图找出是 5.11 内核中的哪个改动造成了这个问题，最后发现是一个和 AMD 平台 [s0ix 睡眠支持][amd-s0ix-update][^1]相关的 Git 提交背锅。我本来寄希望于 Linux 5.11 来解决 Renoir 平台上存在已久、并且我已面对多时的 s0ix 睡眠问题，但是很遗憾，正如[用户所反馈的][amd-s0ix-issue]，新版本的内核不仅没能解决这个问题，还加剧了不稳定性。

Bug 报告中一名内核开发者提供的补丁成功地消除了这个问题：我启动应用该补丁的内核后，关机功能就能恢复正常，不再自动重启了。s0ix 睡眠和 Linux 5.9 与 5.10 时一样，依然存在问题，但至少没有任何其它的退化了。除了要等到 5.13 才能看到下次对 s0ix 问题的修复外，我也没什么可抱怨的了。

我相信这个补丁很快就会被并入 Linux 5.11 了。现在这个补丁只是[出现][patch-5.12-rc1]在了 Linux 5.12-rc1 的改动中，还没被应用到 5.11，也就意味着在 5.11.1 和 5.11.2 上还是有这个 bug 的。不过，一个已经被并入 RC 版本内核的更改应该也会被很快被移植到稳定版本内核分支中的。

由于 Gentoo 提供好几个不同的内核软件包，根据您选用的内核包的不同，补丁安装路径也不同。我个人用的是 [`sys-kernel/vanilla-kernel`][vanilla-kernel]，补丁就应该放在 `/etc/portage/patches/sys-kernel/vanilla-kernel` 中。如果您使用的内核包不一样，您也应相应地将该补丁放在不同的路径下。如果您用的是已经预编译的发行版内核 [`sys-kernel/gentoo-kernel-bin`][gentoo-kernel-bin]，您就得换用一个需要您自己编译内核的软件包才能应用自己的内核补丁。

[^1]:
	s0ix 是微软大力推广的一种新型睡眠机制，被微软称为“[Modern Standby][modern-standby]”。我在微软自己的文档网站上并没有找到它的官方中文译名。如果您愿意坐和放宽的话，您可以点击[这个链接][msft-wdnmd]，来看什么是微软的机器翻译对这一个概念，这通常不会太久。我在 B 站随便点了几个提到这项机制的视频，他们都管这项技术叫“快速唤醒”，那我就姑且先用这个名字了。快速唤醒的目的就是让笔记本的睡眠表现更加接近智能手机。

	过去二十多年中，笔记本和许多台式机都是通过进入 [ACPI S3 状态][acpi-s3]实现的睡眠。在 S3 状态下，包括 CPU 和网卡在内的硬件的电源都会被断开，只有内存的供电会被保持。这样的睡眠机制并不能让笔记本像手机那样，待机的时候仍然能继续接收推送消息、以及播放音乐等，毕竟 CPU 和网卡之类的硬件都被关闭了。但是，在 s0ix 状态下，CPU 不会被完全关闭，顶多是进入低功耗模式；包括网卡在内的一些其它硬件也会保持在运行状态。这样一来，笔记本就能在睡眠时保持网络连接，继续接收消息推送了。

	作为一个历史悠久的标准，Linux 对 ACPI S3 的支持肯定没有任何问题。而 s0ix 睡眠仍然是个比较新的概念，而且基本是一个微软闭门造车的产物，并不是作为一个通用标准开发的，所以 Linux 对其支持很差。

	更为雪上加霜的是，s0ix 和 S3 从技术上就是互不兼容的。许多笔记本厂商都买了微软的账，在他们的产品上使用了 s0ix 睡眠方案；因为 s0ix 和 S3 相斥，所以这些产品一般都不支持 S3。这对 GNU/Linux 用户造成了相当大的不便。有些厂商就很好，在 BIOS 里提供了一个允许在 S3 和 s0ix 间切换的选项，但并不是所有厂商都这么良心。所以，如果您购买的机型使用的是 s0ix 睡眠，并且 BIOS 设置里不提供这样的切换选项的话，您应做好接受 Linux 睡眠问题的准备。

[amd-s0ix-update]: https://www.phoronix.com/scan.php?page=news_item&px=AMD-S2idle-ACPI-Linux-5.11
[amd-s0ix-issue]: https://gitlab.freedesktop.org/drm/amd/-/issues/1230
[modern-standby]: https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby
[msft-wdnmd]: https://docs.microsoft.com/zh-cn/windows-hardware/design/device-experiences/modern-standby
[acpi-s3]: https://zh.wikipedia.org/zh-cn/%E9%AB%98%E7%BA%A7%E9%85%8D%E7%BD%AE%E4%B8%8E%E7%94%B5%E6%BA%90%E6%8E%A5%E5%8F%A3#%E5%85%A8%E5%B1%80%E7%8A%B6%E6%80%81%EF%BC%88Global_System_States%EF%BC%8CG-State%EF%BC%89
[patch-5.12-rc1]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=b092b19602cfd47de1eeeb3a1b03822afd86b136
[vanilla-kernel]: https://packages.gentoo.org/packages/sys-kernel/vanilla-kernel
[gentoo-kernel-bin]: https://packages.gentoo.org/packages/sys-kernel/gentoo-kernel-bin

## 总结

可以看出，这次系统更新中升级的几个软件包的确造成了系统不稳定，以至于我需要给三个不同的软件包打额外的补丁，才能回到和以前一样稳定的状态。但应用了补丁之后，这些 bug 都能立即得到有效解决，我也不需要苦等软件上游发布新版本、或者发行版推送新版本了。如果我用的是一个普通的基于二进制软件包的发行版，我就得依赖发行版的维护人员及时推送包含 bug 修复的更新才能解决这类 bug 了，因为把用户自己的补丁整合进发行版提供的软件包是项困难的工作。但是在 Gentoo 上，我就可以利用 Portage 的用户补丁功能，通过软件包管理器来修改安装在我系统上的程序，整个过程也既简单又流畅。

这篇文章应该能让您大致体会到为运行在各种不同平台的自由软件项目寻找并下载补丁的过程是什么样的了。首先要做的应该是确定是哪个软件的什么版本导致的问题。究竟是系统内核，init，还是用户层的程序？回滚到上一个版本后，问题是会消失还是依旧存在？接下来就可以善用搜索引擎，用软件包名称、出问题的版本以及几个概括问题情况的关键词来搜索。如果别人也碰到了同样的问题，您就应该能看到相关的 bug 报告。然后，您就可以留意一下有没有相关的补丁、pull request 或者 merge request。这篇文章里举的三个例子恰好也分别展示了怎么从一个 GitHub pull request、一个 GitLab merge request 以及一个 URL 链接下载补丁。