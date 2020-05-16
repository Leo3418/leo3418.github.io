---
title: "让 Windows 10 Mobile 停留在 10586.545 不再更新的方法"
lang: zh
---

Windows 10 Mobile 10586.545 版本是 1511 版本分支中最后一个版本。部分 Windows 10 Mobile 用户可能因为更好的系统表现、自带收音机或其它原因选择停留在版本 1511，但由于系统强制自动升级，部分设备又会被强制升级至更高的版本。本篇教程将指导您如何通过修改系统注册表来让 Windows 10 Mobile 不再能检测到更高的版本的更新，从而停留在 10586.545。

## 基本原理

对于一些比较老旧的 Windows Phone，例如 Lumia 1020，微软是不提供官方的 Windows 10 Mobile 支持的，这些设备在检查更新的时候也无法检测到比 1511 更高的版本。我们可以通过修改系统注册表的方式，将自己的手机伪装成这些设备中的一员，在检查更新的时候就不会收到任何更新了。

## 适用范围

所有预装或官方支持升级到 Windows 10 Mobile 的设备，包括但不限于 Lumia 430，435，532，535，540，550，635（1 GB RAM 版本），636（1 GB RAM 版本），638（1 GB RAM 版本），640，640 XL，650，730，735，830，929（亦称 Lumia Icon），930，950，950 XL，1520。

由于其它运行 Windows Phone 8.1 但未获得官方 Windows 10 Mobile 支持的设备在检查更新时最高只能检查到 10586.545 版本，因此没有必要再进行任何修改。

## 准备

您需要：
- 一台在上述“适用范围”中的 Windows Phone 或 Windows 10 Mobile 设备
- 如果您已经更新到了比 10.0.10586.545 更高的版本，您还需要一条适合您手机的 USB 数据线以及一台运行 Windows 的电脑。您可以在“设置→系统→关于→设备信息”下找到手机当前系统的 OS 版本。

## 步骤

0. 如果您已经更新到了比 10.0.10586.545 更高的版本，您需要先回滚至 Windows Phone 8.1 或 Windows 10 Mobile 版本 1511 （取决于您的设备可用的系统版本）。如果您回滚至了 Windows Phone 8.1，那么还需要升级至 Windows 10 Mobile OS 版本 10586.107。回滚的方式有很多，包括使用 Windows Phone Recovery Tool、使用 thor2 刷机、使用 FFUTool 刷机。升级的方式也包括使用应用商店中的“升级顾问”应用和使用离线更新包。请自己选择适合的方式并自行搜索相关教程。
1. **下载、安装并配置最新版本的** [**Interop Tools**](http://forum.xda-developers.com/windows-10-mobile/windows-10-mobile-apps-and-games/app-interop-tools-versatile-registry-t3445271)**。**这是由 [XDA Developers](http://forum.xda-developers.com) 论坛用户 [gus33000](http://forum.xda-developers.com/member.php?u=7651894) 开发的修改 Windows 10 Mobile 系统注册表的应用。请自行搜索相关资源和教程。如果您已经安装好该应用并可以使用，请跳过此步骤。
2. **如果您当前系统的 OS 版本为 10.0.10586.545，请跳过此步骤。**  
如果您的当前系统的 OS 版本比 10.0.10586.545 低，您需要通过修改设备的机型为无官方 Windows 10 Mobile 支持的机型，才会收到 10586.545 版本的更新。否则，您将升级至比 10586.545 更高的版本。
![在“设置”中检查系统版本](/assets/img/{{ page.permalink }}/step2_0.png)
在 Interop Tools 中，找到注册表路径 `HKEY_LOCAL_MACHINE\SYSTEM\Platform\DeviceTargetingInfo\`，并修改如下项目，将您的手机伪装为 Lumia 530，这样就可以收到版本 10586.545 的更新：
  - `PhoneHardwareVariant` 修改为 `RM-1019`
  ![修改 PhoneHardwareVariant](/assets/img/{{ page.permalink }}/step2_1.png)
  - `PhoneManufacturerModelName` 修改为 `RM-1019`
  ![修改 PhoneManufacturerModelName](/assets/img/{{ page.permalink }}/step2_2.png)
  - `PhoneMobileOperatorName` 修改为 `000-CN`
  ![修改 PhoneMobileOperatorName](/assets/img/{{ page.permalink }}/step2_3.png)
  - `PhoneModelName` 修改为 `RM-1019`
  ![修改 PhoneModelName](/assets/img/{{ page.permalink }}/step2_4.png)
改完之后，您可以在“设置→系统→关于”下看到已更改的设备信息。
![查看修改后的设备信息](/assets/img/{{ page.permalink }}/step2_5.png)
随后，在“设置→更新和安全→手机更新”中检查更新，您应该能收到 10586.545 版本的更新。
![下载更新](/assets/img/{{ page.permalink }}/step2_6.png)
3. 当您升级至 10586.545 后，您可以选择以下两种方式来防止系统检查到更高版本的更新。  
  a. 修改手机运营商。运营商定制版的 Windows 手机的系统更新需要取决于运营商，而只需要改一个不存在的运营商，就可以让手机无法检测到更新。  
  在 Interop Tools 中，修改注册表项 `HKEY_LOCAL_MACHINE\SYSTEM\Platform\DeviceTargetingInfo\PhoneMobileOperatorName` 为类似于 `ABC-CN` 这种无意义的运营商代码即可。
  ![修改运营商代码](/assets/img/{{ page.permalink }}/step3_1.png)
  如果您的手机上安装了“附加信息”应用，那么您可以看到您更改的运营商。
  ![“附加信息”应用中可看到修改过的运营商代码](/assets/img/{{ page.permalink }}/step3_2.png)
  b. 修改设备机型为无官方 Windows 10 Mobile 支持的机型。如果您之前执行过步骤 2，那么您无须任何其它操作，大功告成；如果您未执行步骤 2，但选择采取这种方式，请参考步骤 2 中的说明。  
  此方式可能导致一些需要识别设备机型的应用识别出的机型是您修改的机型，而不是实际型号。

现在再检查更新，系统就会提示“你的设备已安装最新的更新”。
![检查更新后发现已无更新](/assets/img/{{ page.permalink }}/step3_3.png)
