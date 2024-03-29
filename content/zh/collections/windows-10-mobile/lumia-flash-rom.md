---
title: "Nokia/Microsoft Lumia 使用 FFUTool 刷机教程"
date: 2016-10-08
---

安卓可以刷机这一事实，许多人都应该是知道的。比如说我们买了一部国行的 Samsung Galaxy S6，但不喜欢冗余的预装软件，或者是想使用 Google Play 服务，我们可以通过刷个港版、美版固件的方式来从另一种方式去解决。或者对于那些有第三方 ROM 的手机，我们还可以选择一个自己喜欢的 ROM 去刷入。

而对于 Windows Phone，我们显然不能刷入其它的 ROM，比如刷个安卓什么的，肯定不行。但我们可以像刚才叙述的前者那样，刷个其它地区的固件。Windows Phone 上的刷机一词就是指代这种刷机的方法。

之前就有过给我的 Lumia 535 刷一个港版 ROM 的念头。当时刷机文件都下好了，唯独找不到刷机工具，被迫放弃。后来，我发现了 FFUTool，可以给所有 Lumia 手机（预装 Windows Phone 8 及以上者）刷机，又尝试了一下，终于成功告别坑爹的国行 ROM，刷入港版 ROM！想到找到这个方法也不容易（尽管现在网上已经能找到挺多教程了），于是决定写篇教程，介绍一下如何使用 FFUTool 给包括 Lumia 535 在内的所有 Lumia 设备刷机。

## 准备

您需要：
- 一台 Lumia 设备
- 一根适合您手机的 USB 数据线
- 一台运行 Windows 的可以联网的电脑

## 步骤

1. **下载固件。** 去找一个您想刷入的 ROM，扩展名是 .ffu。如果您不知道哪里可以下载，可以前往 [LumiaFirmware](http://www.lumiafirmware.com/)。

2. **下载刷机工具 FFUTool。** 这是一个基于命令行的刷机软件，不过操作也相当简单。

3. **备份您手机上所有希望保留的文件。** 刷机会清除您手机上所有的文件，包括图片、音乐、视频，以及系统设置、联系人、短信、通话记录等。请务必备份所有您希望保留的文件。

4. **进入刷机模式。** 首先将手机关机。按住**音量加键**不放，然后按住**电源键**到手机震动后立即松开，但此时仍不要松开音量加键。等到手机显示如下画面的时候，就可以松开音量加键了。

   ![手机处于刷机模式下的屏幕画面]({{< static-path img step4.jpg >}})
   {.half}

5. **连接手机并安装驱动。** 使用 USB 线将手机与电脑连接。看系统有没有提示正在安装驱动程序。在 Windows 7 及以前的版本上，系统会提示是否成功安装驱动程序。

   如果连接后，系统没有发出任何提示，那么请更换 USB 插口或数据线。如果无法安装驱动，请先确保电脑已经联网，已经启用了 Windows Update，并且允许系统自动下载驱动程序软件，如果不行则更换电脑、换用不同操作系统。

6. **启动 FFUTool。** 在文件资源管理器里，找到 FFUTool 所在的文件夹，按下 **Shift + F10**，然后点击 **“在此处打开命令窗口”**。

   ![在文件资源管理器中打开命令窗口]({{< static-path img step6.jpg >}})

7. **检查电脑是否能识别手机。** 输入命令 `ffutool -list`，然后按下 Enter 键。只要看得到 `Devices found: 1`，就说明手机已经正确连接，准备好刷机了。如果没有类似的提示，请重新执行第 5 步。

   ![手机正确连接后命令行输出内容]({{< static-path img step7.jpg >}})

8. **刷入固件。** 输入命令 `ffutool -flash [path]`，其中 `[path]`  是您下载的 FFU 文件所在的路径，然后按下 Enter 键。例如，我将 FFU 文件存储在了 F 盘的根目录下，文件名叫 RM1090.ffu，那么我就输入 `ffutool -flash F:\RM1090.ffu`。

   输入命令后，会出现进度条、完成百分比和刷入速度。

   ![刷机过程中命令行输出内容]({{< static-path img step8.jpg >}})

9. **等待刷机完成。** 等到进度条走满时，刷机就完成了，手机会自动重启，启动刷好的系统。

   ![刷机完成后命令行输出内容]({{< static-path img step9.jpg >}})
