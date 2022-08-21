---
title: "打开与关闭 Windows 10 Mobile 完整文件系统访问权限的方法"
date: 2016-10-19
---

在 Windows 10 Mobile 中，只需要安装由 [XDA Developers](http://forum.xda-developers.com) 论坛用户 [gus33000](http://forum.xda-developers.com/member.php?u=7651894) 开发的 [Interop Tools](http://forum.xda-developers.com/windows-10-mobile/windows-10-mobile-apps-and-games/app-interop-tools-versatile-registry-t3445271) 就可以实现修改注册表、访问完整文件系统等“越狱”后的权限。Interop Tools 中有一个打开完整文件系统访问权限的开关，但由于相关的说明不够详细，包括我在内的一些用户遭遇了不能看到所有文件、打开选项后关掉却依然在将手机连接电脑时看到完整文件系统等问题。此教程将对此类问题进行解答。

## 适用范围

所有受 Interop Tools 中的此功能支持的机型，包括 Lumia 810、Lumia \*2\*（预装 Windows Phone 8 的第 2 代 Lumia 设备以及 Lumia Icon）、Lumia \*3\*（预装 Windows Phone 8.1 的第 3 代 Lumia 设备）、Lumia 540、Lumia 640 以及 Lumia 640 XL。

需要升级至 Windows 10 Mobile 版本 1511（10.0.10586）或版本 1607（10.0.14393）。

## 步骤

1. **下载、安装并配置最新版本的 Interop Tools。** 请自行搜索相关资源和教程。如果您已经安装好该应用并可以使用，请跳过此步骤。

### 打开完整文件系统访问权限的方法

1. **打开 Interop Tools，在主菜单中的“Interop Unlock”里，打开“Full Filesystem Access”选项。**

   ![打开 Full Filesystem Access]({{< static-path img step2.png >}})
   {.half}

2. **重新启动手机。** 尽管现在将手机连接到电脑后可以显示文件系统中的部分文件夹，但并不完整。

   ![刚打开选项后可访问的内容]({{< static-path img step3_1.png >}})

   此时需要重新启动手机，然后就可以看到完整的文件系统，如 PROGRAMS 文件夹。

   ![重启手机后可访问的内容]({{< static-path img step3_2.png >}})

### 关闭完整文件系统访问权限的方法

1. **打开 Interop Tools，在主菜单中的“Interop Unlock”里，关闭“Full Filesystem Access”选项。**

   ![关闭 Full Filesystem Access]({{< static-path img step4.png >}})
   {.half}

2. **现在将手机连接电脑时还是会显示完整的文件系统，需要修改注册表项** `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MTP\DataStore` **为** `C:\Data\Users\Public`**，才能彻底关闭访问权限。**

   ![修改注册表项]({{< static-path img step5.png >}})
   {.half}

以后如果需要重新开启，重复打开完整文件系统访问权限的步骤即可。
