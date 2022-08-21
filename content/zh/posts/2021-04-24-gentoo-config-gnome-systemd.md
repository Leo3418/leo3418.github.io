---
title: "Gentoo 配置指南：基于 systemd 的 GNOME"
tags:
  - Gentoo
  - GNU/Linux
categories:
  - 教程
toc: true
lastmod: 2021-04-24
---

想在 Gentoo 上完美配置 GNOME 虽然不难，但需要经验。只要成功配置过一遍后就可能会觉得是小菜一碟，但是第一次操作的时候很容易遇到重重坎坷。虽然根据 [Gentoo Wiki 上的 GNOME 指南][gentoo-gnome-guide]可以配置一个最基础且能用的 GNOME 环境，但是想要完善 GNOME 配置的话，就还需要执行许多指南中没提到的额外步骤。比如，如果不进行额外配置的话，修改网络连接选项时就需要输入用户密码以验证权限，在 Wayland 会话中也无法从包括 Chrome 在内的浏览器共享屏幕内容。而且，该指南的中文翻译质量也有些堪忧。

因此，在这篇文章中，我将介绍让 Gentoo 上的 GNOME 更加完美地运行的一些关键步骤。其中，一些比较基础的步骤在 Gentoo GNOME 指南中已经提到，而剩下的指南中未提到的步骤则会提升用户体验。

此文章的步骤适用于基于 systemd 的系统，不适用于基于 OpenRC 的系统。

[gentoo-gnome-guide]: https://wiki.gentoo.org/wiki/GNOME/Guide/zh-cn

## 选择配置文件并安装 GNOME 软件包

在 Gentoo 手册的系统安装步骤中，有一步是[选择配置文件][handbook-profile]，想基于 systemd 安装 GNOME 的用户就会选择 GNOME systemd 配置文件。这里有一点需要留意，那就是 GNOME 并不会在选择了这个配置文件后自动安装。这个配置文件唯一所做的就是设置一些 USE 标志和其它 Portage 选项，以允许 GNOME 的安装和运行。换言之，选定了 GNOME 配置文件后，用户还需要使用 `emerge` 手动安装 GNOME 组件。

```console
# emerge --ask gnome-base/gnome
```

[handbook-profile]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base/zh-cn#.E9.80.89.E6.8B.A9.E6.AD.A3.E7.A1.AE.E7.9A.84.E9.85.8D.E7.BD.AE.E6.96.87.E4.BB.B6

## 启用 GNOME 显示管理器的 systemd 单元

如果想让 GNOME 开机自启动的话，就需要手动启用 GNOME 显示管理器（GDM）的 systemd 单元。否则，开机后系统还是会显示纯文本登录界面。

```console
# systemctl enable gdm.service
```

如果 `gdm.service` 已被启用了，但是重启系统后，GNOME 登录界面依然不显示，那么请尝试将 systemd 的默认目标明确设定为 `graphical.target`：

```console
# systemctl set-default graphical.target
```

## 启用更多 systemd 单元供 GNOME 设置使用

如果想使用 GNOME 设置应用（又称为 `gnome-control-center`）调整电脑的设置，那么就需要再启用一些额外的 systemd 单元。

- 如果想从 GNOME 设置中管理网络连接，请启用 `NetworkManager.service`。这样一来，NetworkManager 就会在开机后运行，管理系统网络连接。如果 `systemd-networkd` 也被启用了的话，那么建议禁用 `systemd-networkd.service` 以防止这两个网络管理服务产生冲突。
- 如果想访问蓝牙设置，请启用 `bluetooth.service`。
- 如果想启用打印机设置，请启用 `cups.service`。

```console
# systemctl enable NetworkManager.service
# systemctl disable systemd-networkd.service
# systemctl enable bluetooth.service
# systemctl enable cups.service
```

## 允许在不进行验证的情况下修改网络设置

在默认情况下，通过 GNOME 设置调整网络设置是需要超级用户权限的，所以当用户连接到新 Wi-Fi 网络或者修改网络配置时，可能会看到下面的界面，被要求进行验证：

![修改网络设置时出现的验证对话框]({{< static-path img polkit-nm.png >}})

若要允许所有用户帐户修改网络设置，可在 `/etc/polkit-1/rules.d` 下创建一个 `*.rules` 文件，然后在该文件中添加下列规则：

```js
/* /etc/polkit-1/rules.d/10-networkmanager.rules */

// 允许所有用户通过 NetworkManager 管理网络连接
polkit.addRule(function (action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.local) {
        return polkit.Result.YES;
    }
});
```

然后，重启 systemd 单元 `polkit.service` 以应用新规则：

```console
# systemctl restart polkit.service
```

## 允许 `wheel` 用户组中的用户在 GNOME 中使用自己的帐户凭据进行验证

[`wheel` 用户组][wheel-group] 经常被用作 Unix 系统上的管理员组。按照惯例，在配置 `sudo` 这类工具时，经常会授予 `wheel` 组中的用户以超级用户身份运行命令的权限，并且允许用户使用*自己的*密码进行验证，而非 `root` 帐户的密码。

当 GNOME 需要以超级用户权限执行任务时（例如，挂载内部硬盘中的分区），会弹出一个对话框要求用户进行验证。但是，如果配置不到位，验证过程要求输入的就是 `root` 帐户的凭据，和 `sudo` 完全不同。

![询问 root 帐户凭据的验证对话框]({{< static-path img polkit-root.png >}})

如果想实现 `sudo` 风格的验证，让用户输入当前帐户的密码的话，只需同样地在 `/etc/polkit-1/rules.d` 下创建一个 `*.rules` 文件，然后添加如下规则：

```js
/* /etc/polkit-1/rules.d/49-wheel.rules */

// 允许 'wheel' 组中的用户在 GNOME 验证提示中使用自己的密码，而非 root 密码
polkit.addAdminRule(function (action, subject) {
    return ["unix-group:wheel"];
});
```

重启 systemd 单元 `polkit.service` 后，`wheel` 组中的用户就可以使用自己的凭据完成验证流程了。

![询问当前用户凭据的验证对话框]({{< static-path img polkit-wheel.png >}})

[wheel-group]: https://zh.wikipedia.org/zh-cn/Wheel_(%E9%9B%BB%E8%85%A6%E7%A7%91%E5%AD%B8%E8%A1%93%E8%AA%9E)

## 启用浏览器中基于 PipeWire 的 WebRTC 屏幕共享

Wayland 是 GNOME 默认使用的显示服务器协议，而如何在 Wayland 上启用浏览器中的屏幕共享功能也是许多用户都会问的问题。这个问题的解决方法倒是不难，那就是安装 `xdg-desktop-portal-gtk`。但是在 Gentoo 上，这个问题的解决方案更为复杂，因为 Gentoo 的软件包有着 USE 标志的概念，允许对各个软件包中被安装的功能进行精细的调整。如果一些屏幕共享功能必需的 USE 标志没有被启用，那么 `xdg-desktop-portal-gtk` 即使安装了也无法正常工作。

在 Gentoo 上启用屏幕共享的额外注意事项包括：

- 需要在全局范围内启用 `screencast` USE 标志，以启用软件包对 PipeWire 屏幕捕获功能的支持。

- PipeWire 的 systemd 套接字 `pipewire.socket` 需要手动启用，因为其默认是被禁用的。

详细步骤如下：

1. 在全局范围声明 `screencast` USE 标志。Gentoo 手册中记载了一种修改 `/etc/portage/make.conf` 的[方法][handbook-use]；除此之外，还有一种方法，那就是在 `/etc/portage/package.use` 中声明该 USE 标志，如下所示：

   ```sh
   # /etc/portage/package.use

   # 启用 PipeWire 屏幕捕获支持
   */* screencast
   ```

2. 使用新的 USE 标志设置，重新构建已安装的软件包：

   ```console
   # emerge --ask --newuse --deep @world
   ```

3. 安装 `sys-apps/xdg-desktop-portal-gtk`：

   ```console
   # emerge --ask sys-apps/xdg-desktop-portal-gtk
   ```

4. 启用 PipeWire 的 systemd 套接字：

   ```console
   # systemctl --global enable pipewire.socket
   ```

5. 重启系统。

[ArchWiki][archwiki-webrtc] 称，FireFox 默认已经启用了 WebRTC PipeWire 支持，而在 Chromium/Chrome 上则需要启用一个实验性功能：

```
chrome://flags/#enable-webrtc-pipewire-capturer
```

如果想测试配置是否成功，可以在[这个测试页面][screen-capture-test]中点击“Screen capture”按钮。在弹出的系统对话框中，选择共享源，然后就应该能在网页上看到屏幕共享的内容了，并且顶栏中还会显示一个橙色的屏幕共享图标。

![在 Chrome 中共享屏幕]({{< static-path img screen-share.png >}})

### 限制

- Chrome 的屏幕共享没有声音。不过即使是在 Windows 上，从 Chrome 共享屏幕也是没有声音的，所以这应该是 Chrome 的问题。

- 从 Chrome 分享屏幕时，询问分享源的系统对话框会出现两次。

[handbook-use]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Working/USE/zh-cn#.E5.A3.B0.E6.98.8E.E6.B0.B8.E4.B9.85USE.E6.A0.87.E5.BF.97
[archwiki-webrtc]: https://wiki.archlinux.org/index.php/PipeWire#WebRTC_screen_sharing
[screen-capture-test]: https://mozilla.github.io/webrtc-landing/gum_test.html
