---
title: "用于在基于 Linux 的系统上查看 CPU 温度和频率的小脚本"
lang: zh
tags:
  - Unix 程序
  - GNU/Linux
categories:
  - 教程
asciinema-player: true
---
{% include img-path.liquid %}
在这篇帖子中，我将展示在基于 Linux 的系统上，如何仅依赖主流 GNU/Linux 发行版预装的软件包查看 CPU 频率和温度信息。这种方法不需要借助任何额外的和硬件驱动和支持相关的软件包，只需要用一个只有几行的 Bash 脚本，利用 Linux 内核自身提供的机制和一些最基础的 Unix 命令就能读取 CPU 的硬件状态信息。

如果想直入正题，您可以点击[此处][script]直接跳到脚本的内容。如果您想了解我发现这种方法的探究历程，欢迎继续向下阅读。

[script]: #script

如果您是一名有一定电脑使用知识的 Windows 用户，您肯定有过使用任务管理器监测系统状态的经历。任务管理器提供了 CPU 占用率和频率信息，方便我们了解系统负载。虽然任务管理器提供的监测功能绝不是最全面的，但作为一个系统自带、并且可以快速调出的工具，任务管理器有它独有的优势。

![Windows 任务管理器中的 CPU 信息]({{ img_path }}/windows-task-manager.png)

我一直想找一个 GNU/Linux 上和 Windows 的任务管理器的功能和性质类似的硬件监测工具，但始终没找到理想的选择。我平时使用的桌面环境是 GNOME，它自带的系统监视器（如下图所示）只能显示 CPU 每个线程的占用率，并不能显示它们的频率。[htop][htop] 倒是个不错的工具，但有的发行版上没有预装，例如 Fedora，这时就需要额外安装软件包了。

[htop]: https://htop.dev/

![GNOME 系统监视器并不显示 CPU 频率]({{ img_path }}/gnome-system-monitor.png)

就在最近，我发现了在 `x86_64` 平台上读取 CPU 每个线程的频率的方法，只需要依赖 `grep`，一个非常基本的 Unix 程序，在各大 GNU/Linux 发行版上也应该是预装的命令。

```console
$ grep 'cpu MHz' /proc/cpuinfo
```

{% include asciinema-player.html name="cpu-freq.cast" poster="npt:6.2" %}

除了看频率以外，有的时候我也想同时看一下 CPU 温度，尤其是要测试散热性能的时候。我在网上简单寻找后，发现也有一种不需要任何像 `lm-sensors` 这种和硬件传感器相关的软件包的方法：

```console
$ cat /sys/class/thermal/thermal_zone0/temp
```

{% include asciinema-player.html name="cpu-temp.cast" poster="npt:6" %}

这行命令输出的值是当前 CPU 温度（以摄氏度为单位）乘以 1000。把后面的三个零去掉，就得到了我们熟悉的摄氏度温度数值。可以用下面的命令，在 Bash 里直接进行除法运算：

```console
$ echo $(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
```

同时说明一下，上面这两条命令都是假设 `/sys/class/thermal/thermal_zone0` 对应的是 CPU，而不是硬盘或者无线网卡等其它硬件。在我手头所有运行 Linux 并且允许我访问系统内部信息的设备上，这个对应的都是 CPU，应该只有极少数情况下会出现不同。

有了这些具体的命令，我们就可以把它们做成一个可以显示 CPU 状态信息的 Bash 脚本了：

```bash
#!/usr/bin/env bash

grep --color=never 'cpu MHz' /proc/cpuinfo
cpu_temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
echo "cpu temperature : ${cpu_temp}"
```
{: #script}

把这个脚本放到一个 `PATH` 环境变量中声明的路径下，就可以方便地随处调用它了。比如，在绝大多数 GNU/Linux 发行版中，~/.local/bin 都在 `PATH` 里。如果要看 `PATH` 中都声明了哪些路径，可以使用 `printenv PATH` 命令。除此之外，别忘了给脚本设上可执行权限（`chmod +x`）。

{% include asciinema-player.html name="install.cast" poster="npt:3.5" %}

如果您想持续监测 CPU 频率和温度的话，您可以使用 [`watch`][watch] 工具运行它。`watch` 默认每隔 2 秒运行一次您指定的命令，并显示命令运行后输出的内容。如果您想改变运行间隔，您可以使用 `-n` 选项指定间隔时长。例如，`watch -n 1` 就是每隔 1 秒运行一次命令。

[watch]: https://man.archlinux.org/man/watch.1

{% include asciinema-player.html name="watch.cast" poster="npt:3.8" %}

## 兼容性

这个脚本应该和比较新的 AMD 还有英特尔的 `x86_64` CPU 都兼容。我在 Ryzen 7 4700U 和酷睿 i5-7200U 上都测试了这个脚本，没有出现问题。

{% include asciinema-player.html name="amd-4700u.cast" poster="npt:5.5" %}

{% include asciinema-player.html name="intel-7200u.cast" poster="npt:7.5" %}

我甚至还在几台 `aarch64` 设备上测试了这个脚本。CPU 频率无法读取，但 CPU 温度仍然能正常显示。我测试的设备为运行 Fedora 的 Linux 5.10.9 内核的树莓派 4、和装了 [Gentoo Android][gentoo-android] 的跑着第三方 ROM 的 3.10 内核的 Nexus 9 平板。

[gentoo-android]: https://wiki.gentoo.org/wiki/Project:Android

{% include asciinema-player.html name="raspi-4.cast"
    poster="data:text/plain,树莓派 4" %}

{% include asciinema-player.html name="nexus-9.cast"
    poster="data:text/plain,Nexus 9" %}
