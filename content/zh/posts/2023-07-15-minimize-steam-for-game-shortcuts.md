---
title: "让 Steam 在启动游戏快捷方式时最小化到托盘（仅适用于 Windows）"
categories:
  - 教程
toc: true
---

最近 Steam 客户端的大更新在大改界面的同时，在用户体验方面却有所退步：如果在 Steam 客户端没有运行的时候，使用桌面或开始菜单的快捷方式启动 Steam 游戏，那么 Steam 会在启动游戏前弹出客户端窗口；而在大更新之前，用快捷方式启动游戏后，Steam 是会直接最小化到系统托盘的，压根不会显示客户端窗口。

新版客户端的这一特性，对于喜欢用快捷方式启动 Steam 游戏、并且不想让 Steam 开机自启的用户来说，无疑十分烦人。因为现在用快捷方式启动游戏后，必须手动关闭 Steam 自己弹出的客户端窗口，才能将 Steam 最小化到系统托盘，否则 Steam 的窗口就会一直待在前台。

本文将介绍一种在 Windows 上解决此问题的方法，以阻止新版 Steam 客户端在启动游戏快捷方式时弹出客户端窗口。该解决方法的原理为：通过修改系统注册表，改变启动游戏快捷方式时，系统使用的 Steam 客户端启动选项。

## 要求

- 本文中的操作步骤仅适用于 Windows。

- 执行本文中的操作步骤前，Steam 客户端必须至少启动过一次。

## 修改注册表

### 启动注册表编辑器

打开*运行*对话框（可使用 Windows 键+R 快捷键），输入 `regedit`，然后按下回车键。

![从运行对话框启动注册表编辑器]({{< static-path img 01-regedit-launch.png l10n >}})

如果出现*用户帐户控制*对话框，选择“是”或者输入管理员密码。

![启动注册表编辑器时出现的用户帐户控制对话框]({{< static-path img 02-uac.png l10n >}})

### 编辑注册表数据

在注册表编辑器中，转到路径 `HKEY_CLASSES_ROOT\steam\Shell\Open\Command`。

![注册表编辑器中显示的要编辑的数据]({{< static-path img 03-reg-original.png l10n >}})

该路径下应该只有一个`(默认)`数据。编辑数据（可通过双击打开编辑对话框），然后在双连字符（`--`）前添加 `-silent` 以及一个空格。例如：

```diff
- "C:\Program Files (x86)\Steam\steam.exe" -- "%1"
+ "C:\Program Files (x86)\Steam\steam.exe" -silent -- "%1"
```

![编辑注册表数据]({{< static-path img 04-reg-edit-value.png l10n >}})

**解释**：在系统注册表中，`HKEY_CLASSES_ROOT\steam\Shell\Open\Command` 路径下存放的是系统在打开 `steam://` URL 时应使用的程序和参数。因为 Steam 游戏快捷方式的目标都是 `steam://` URL（例如，如下图所示，《传送门》的快捷方式 URL 是 `steam://rungameid/400`），所以修改该注册表路径下的数据，就等于修改系统如何启动 Steam 游戏快捷方式。上述的 [`-silent` 选项][steam-launch-options]会让 Steam 客户端启动时直接最小化到系统托盘，不弹出客户端窗口。因此，完成注册表修改后，使用快捷方式启动 Steam 游戏时，Steam 客户端会使用 `-silent` 选项启动，也就不会弹出客户端窗口了。

![Steam 创建的《传送门》快捷方式]({{< static-path img steam-game-shortcut.png l10n >}})

[steam-launch-options]: https://help.steampowered.com/zh/faqs/view/0188-6BB7-D467-08E1

## 防止 Steam 覆写注册表

烦恼还没有结束：Steam 客户端会覆写上述注册表路径，将被修改的数据还原为默认值。要想完全解决问题，还需要修改该注册表路径的权限设置，以阻止 Steam 客户端将其覆写。

1. 打开 `HKEY_CLASSES_ROOT\steam\Shell\Open\Command` 的权限设置（可在导航面板中右键点击该路径，然后在右键菜单中选择“权限”）。

   ![从导航面板打开权限设置]({{< static-path img 05-perm-menu.png l10n >}})

2. 单击“高级”按钮。

   ![权限设置窗口中的“高级”按钮]({{< static-path img 06-perm-advanced.png l10n >}})

3. 在弹出的*高级安全设置*窗口中，单击“禁用继承”按钮。

   ![高级安全设置窗口中的“禁用继承”按钮]({{< static-path img 07-perm-disable-inherit.png l10n >}})

4. 在弹出的*阻止继承*对话框中，选择“将已继承的权限转换为此对象的显式权限。”

   ![阻止继承对话框]({{< static-path img 08-perm-convert.png l10n >}})

5. 在*高级安全设置*窗口中，先在*权限条目*下选中当前用户帐户，然后单击“编辑”按钮。

   ![高级安全设置窗口中选中的当前用户帐户、以及“编辑”按钮]({{< static-path img 09-perm-edit.png l10n >}})

6. 在弹出的*权限项目*窗口中，单击“显示高级权限”。

   ![权限项目窗口中的“显示高级权限”选项]({{< static-path img 10-perm-show-advanced.png l10n >}})

7. *高级权限*出现后，取消勾选“设置数值”，然后单击“确定”关闭*权限项目*窗口。

   ![在高级权限中取消勾选“设置数值”]({{< static-path img 11-perm-no-set-value.png l10n >}})

8. 单击“确定”关闭*高级安全设置*窗口。

   ![关闭高级安全设置窗口]({{< static-path img 12-perm-close.png l10n >}})

**解释**：完成上述权限修改后，当前用户帐户就无法修改该注册表路径下的数据了。因为 Steam 客户端一般都以当前用户身份运行，所以 Steam 也同样无法覆写该路径。不过，当前用户帐户仍然可以使用注册表编辑器修改该路径，因为注册表编辑器是以管理员身份运行的，并且上述权限修改并不影响管理员帐户的权限设置，因此管理员帐户仍然享有完全控制。

## 其它值得一提的解决方法

我在找到此方法前，先在网上搜索了现有的方法，但是我能找到的几个方法都不完美。

### 让 Steam 开机自启

让 Steam 在开机时自动启动可以从一定程度上缓解此问题，但仍然有限制。

在开机自启时，Steam 会直接最小化到系统托盘（在新版客户端刚推出时，Steam 即使是在开机自启时也会弹出客户端窗口，但后来的更新已经改回去了）；当 Steam 已经在后台运行时，使用快捷方式启动 Steam 游戏就不会弹出客户端窗口了。

这种解决方法的限制包括：

- 即使用户不愿意，也得打开 Steam 的开机自启。毕竟不是所有人用电脑都只是为了玩游戏。当用户不准备玩任何 Steam 游戏时，让 Steam 开机自启不仅没有任何好处，反而还浪费系统资源。

  - 系统不但需要更长时间才能完全启动、进入准备就绪的状态，而且在关机时，如果用户没有提前关闭 Steam 客户端，也需要花费更多时间。

  - Steam 在后台运行时会不必要地消耗内存资源。

- 如果用户先关闭 Steam 客户端，再使用快捷方式启动 Steam 游戏的话，Steam 仍然会弹出客户端窗口。

### 逐一修改每个游戏快捷方式的 URL

本文介绍的修改注册表的方法是从全局解决问题，无论是已有的还是以后创建的 Steam 游戏快捷方式都适用。还有一种方法，就是将 Steam 客户端的 `-silent` 启动选项分别添加到每个快捷方式的 URL 中。具体的操作是：在快捷方式 URL 的尾部添加 `" -silent`（即一个双引号、一个空格、然后是 `-silent`），例如：

```diff
- steam://rungameid/400
+ steam://rungameid/400" -silent
```

![通过修改 Steam 游戏快捷方式来阻止 Steam 弹出客户端窗口]({{< static-path img modify-game-shortcut.png l10n >}})

这种解决方法，无论是对于有大量 Steam 游戏快捷方式的用户，还是从长远角度看，可行性都是很低的，因为用户不仅需要把每个已有的快捷方式都改一遍，还得在以后每次 Steam 创建新快捷方式时重复同样的修改。