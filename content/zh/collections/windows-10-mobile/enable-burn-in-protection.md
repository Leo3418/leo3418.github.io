---
title: "打开 Windows 10 Mobile 烧屏保护功能的方法"
date: 2016-10-20
---

Lumia 650、950 和 950 XL 三款设备为使用 Super AMOLED （以下简称 A 屏）并采用屏幕虚拟按钮的机型。由于 Super AMOLED 屏幕每个像素点衰老速度不同、以及显示纯黑色时像素点几乎完全不亮的特性，随着屏幕使用时间的累积，屏幕下方的导航栏区域可能会产生显著的“烧屏”现象：整个屏幕在全屏显示纯色（尤其是蓝色、白色）时，导航栏区域和其它区域的颜色并不相同。如果您长期使用深色主题模式并且没有在导航栏上使用配色，其它区域与导航栏区域相比可能偏黄；如果您长期使用浅色主题模式，或在导航栏上使用了配色，导航栏区域可能更黄。

这也是我个人认为直到全面屏手机成为潮流之前，三星的 Galaxy 系列一直使用实体和电容按键的一个原因：采用自家 A 屏的设备不会因为底部虚拟按键而造成明显的烧屏。诺基亚时代的部分 Lumia 机型虽然也采用 A 屏，但也都是电容按键；而微软时代的 Lumia 开始推行导航栏和虚拟按键，于是就产生了烧屏的问题。

如果您可以接受定期更换系统主题模式、定期开关导航栏颜色等折中的办法，那么虽然屏幕还是会衰老，但衰老相对平均，屏幕各个区域的使用累积时长相近，因此虽然屏幕整体会发黄，但不会看出烧屏现象。而本教程也将介绍另一种方法：通过修改注册表，打开系统隐藏的导航栏烧屏保护模式，从一定程度上可以缓解烧屏的发生。

假如使用 A 屏的机型的用户因为电容按键失灵需要启用虚拟按键担心烧屏问题，或者使用 LCD 屏幕的机型的用户担心导航栏造成的屏幕残印问题（与烧屏的原理不同，发生概率很低，一般完全没必要担心，不过我在一台 Xperia Z1 上见到过），也可以按照本教程打开烧屏保护模式。

## 适用范围

所有支持使用 Interop Tools 修改注册表的机型。

## 步骤

1. **下载、安装并配置最新版本的 [Interop Tools](http://forum.xda-developers.com/windows-10-mobile/windows-10-mobile-apps-and-games/app-interop-tools-versatile-registry-t3445271)。** 这是由 [XDA Developers](http://forum.xda-developers.com) 论坛用户 [gus33000](http://forum.xda-developers.com/member.php?u=7651894) 开发的修改 Windows 10 Mobile 系统注册表的应用。请自行搜索相关资源和教程。如果您已经安装好该应用并可以使用，请跳过此步骤。

2. **修改注册表。** 在 Interop Tools 中，浏览至注册表路径 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Shell\NavigationBar`，点击屏幕界面右下角的“+”，在 `Registry Type` 下选择 `Integer`，在 `Registry Value Name` 下填写 `IsBurnInProtectionEnabled`;，在 `Registry Value Data` 下填写 `1`，然后点击“Write”。

   ![修改注册表]({{< static-path img step2.png >}})
   {.half}

3. **重新启动手机。** 现在您就成功开启了烧屏保护模式。当您大约 1 分钟没有使用导航栏时，该模式就会自动激活。

   如果导航栏是黑色的，那么在此模式被激活时，亦或部分导航栏区域内的像素点亮起，避免导航栏区域衰老较慢；亦或虚拟按钮的亮度降低，防止虚拟按钮图标衰老过快。

   ![黑色导航栏区域像素亮起]({{< static-path img black_1.png >}})
   {.half}

   ![虚拟按钮变暗]({{< static-path img black_2.png >}})
   {.half}

   如果导航栏有颜色，那么部分像素点会熄灭，避免导航栏区域衰老过快。

   ![白色导航栏区域像素熄灭]({{< static-path img white.png >}})
   {.half}

   ![其它颜色导航栏区域像素熄灭]({{< static-path img color.png >}})
   {.half}

   值得一提的是，每次激活此模式时，亮起或熄灭的像素点都会发生变化，以尽量保证衰老速度的平均。

如果需要关掉该功能，将步骤 2 所述的注册表值由 1 改为 0 再重启即可。
