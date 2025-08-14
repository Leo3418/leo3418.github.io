---
title: "Ptyxis 终端模拟器体验"
tags:
  - GNU/Linux
categories:
  - 博客
---

我使用 GNOME 已经有好几年了，这期间用的一直是 GNOME 终端（GNOME Terminal），我感觉很好用。虽然后面又出现了 GNOME 控制台（GNOME Console），有一些不错的新功能，但它却没有个别 GNOME 终端中存在、且我需要用到的功能，所以一直以来我仍然在坚守 GNOME 终端。而到了现在，随着 Ptyxis（英文发音 [/ˈtɪksɪs/][ptyxis-wiktionary]）的出现，为 GNOME 设计的终端模拟器程序已经多达三个。简单上手体验了 Ptyxis 后，我很快就对它爱不释手，而在花了几天折腾一番后，我成功让 Ptyxis 达到了可以取代 GNOME 终端的标准。

[ptyxis-wiktionary]: https://en.wiktionary.org/wiki/ptyxis

## 背景

我对 GNOME 终端一直相当满意。虽然它目前仍在使用已经有了年头的 GTK 3，但我在评估软件时，更注重软件的功能，而非其背后的技术栈。尽管如此，它还是有一个偶尔发作的小 bug。个别情况下，当我在 GNOME 终端内关闭标签页或者还原最大化的窗口后，终端窗口的大小就会不断萎缩：我每切换一次窗口，终端就会少显示一行内容。GNOME 终端项目的 bug 追踪器中已经有关于此 bug 的[记录][gnome-terminal-issue-129]，是 2019 年开的，但直到撰文之时，该 bug 记录仍然处于未解决状态，已被搁置了 6 年。

这个小问题只是偶尔发作，因此还可以忍受，我也一直没当回事。不过，我还是因为这个问题而搜索过几次其它合我口味的终端模拟器程序。我试过 GNOME 控制台；如上文所述，它缺少一个功能——当用户新建标签页时，它不会维持终端文本的行列数（尤其是行数）。相反，GNOME 控制台维持的是*窗口*大小（即窗口本身的像素数量）。开启新标签页后，GNOME 控制台就会显示标签页切换器，在用户界面就要占据额外空间。因此，为了维持窗口大小，就需要缩减用于显示终端文本的窗口空间。例如，在 80 行×24 列的单标签页窗口中开启新标签页后，GNOME 控制台就会将终端大小缩减至 80×21。而 GNOME 终端在用户新建标签页时，就会保持终端文本的行列数、并延展窗口以容纳标签页切换器，因此开启新标签页后，终端大小依然是 80×24。我个人还是喜欢维持终端文本的行列数，宁愿让窗口伸展。

{{< video.inline "kgx-new-tab.webm" >}}
{{- with .Get 0 }}
<p>
<video controls style="width: 100%;">
<source src="{{ partial "static-path.html"
    (dict "page" $.Page "type" "img" "file" . ) }}" />
</video>
</p>
{{- end }}
{{< /video.inline >}}

因此，安装 Ptyxis 后，我做的第一件事就是确认它在用户打开新标签页时是否维持终端文本行列数。看到 Ptyxis 会维持终端大小后，我心里一悦。经过一番快速的探索，我发现我需要的 GNOME 终端功能在 Ptyxis 里也都有，因此，和之前试用 GNOME 控制台时不同，这次我并没有在试用后立刻卸载它。

[gnome-terminal-issue-129]: https://gitlab.gnome.org/GNOME/gnome-terminal/-/issues/129

## 与其它 GNOME 组件的整合

对于大多数人来说，折腾终端模拟器的主要内容就是折腾它的外观；从一定程度上来讲，这种说法对我也不例外。不过，我折腾 Ptyxis 的经历中最有趣的部分，不是关于它的外观，而是让 GNOME 将 Ptyxis 用作默认的终端模拟器程序，从而让我能安全卸载 GNOME 终端且不影响其它 GNOME 组件的功能。为了达到这一目的，我花了一些时间研究，好在最后找到了解决方案，因此我将解决方案放在本文前面的部分，方便想实现同样效果的读者参考。

经我研究发现，GNOME 终端与其它 GNOME 组件共有两处整合：GNOME 文件管理器内右键菜单中的“在终端打开”选项、以及被用来启动纯终端桌面图标（terminal-only desktop entry，即含有 `Terminal=true` 设定的 `.desktop` 文件）。如果不对 GNOME 作任何修改，且只安装了 Ptyxis、未安装 GNOME 终端，那么上述右键菜单选项就会消失，且在活动概览界面中点击纯终端桌面图标后什么也不会发生。

{{<fig>}}
![GNOME 文件管理器内右键菜单中的“在终端打开”选项截图]({{< static-path img nautilus-open-in-terminal.png l10n >}})
{{<figcaption>}}
GNOME 文件管理器内右键菜单中的“在终端打开”选项
{{</figcaption>}}
{{</fig>}}

若要让上述 GNOME 组件使用 Ptyxis 而非 GNOME 终端作为终端模拟器程序，需要修改两个软件包的源代码并重新编译它们（俗称“打补丁”）：GNOME 文件管理器和 GLib。

### GNOME 文件管理器

GNOME 文件管理器需要来自 Fedora 的一个[补丁][fedora-nautilus-patch]。Fedora Workstation 在 Fedora 41 时将默认的终端模拟器程序从 GNOME 终端换成了 Ptyxis，且其默认已不再安装 GNOME 终端，因此 Fedora 需要对 GNOME 文件管理器的源代码应用补丁，以让其能与 Ptyxis 整合。

应用该补丁后，只要系统上已安装了 Ptyxis，GNOME 文件管理器的右键菜单中就会出现一个“在控制台打开”的选项，并且该选项开启的程序就是 Ptyxis。如果在当前打开的文件夹中的空白位置点击右键，弹出的菜单中就直接包括了该选项。但是，如果在当前文件夹中的一个文件夹上点右键，那么该选项就需要在“打开”二级菜单中才能找到，并非像 GNOME 终端的“在终端打开”选项那样在一级菜单中，导致本来只需要一次点击的操作现在需要两次（像极了 Windows 11 中的很多用户体验改动）……

{{<fig>}}
![NOME 文件管理器内右键菜单中的“在控制台打开”选项截图]({{< static-path img nautilus-open-in-console.png l10n >}})
{{<figcaption>}}
子文件夹右键菜单中的“在控制台打开”选项
{{</figcaption>}}
{{</fig>}}

值得一提的是，该 Fedora 补丁所做的事，是在 GNOME 文件管理器的源代码中，将所有对 GNOME 控制台的引用（而非 GNOME 终端）都改为对 Ptyxis 的引用。首先需要解释的是，“在终端打开”（对应 GNOME 终端）和“在控制台打开”（对应 GNOME 控制台或者 Ptyxis）这两个选项的实现方式不同：前者是由 GNOME 终端附带的 GNOME 文件管理器插件（`/usr/lib64/nautilus/extensions-4/libterminal-nautilus.so`）添加的，而后者是 GNOME 文件管理器自身在检测到系统上安装了 GNOME 控制台后自行显示的。该补丁所影响的是后者。此外，如果系统上同时安装了 GNOME 终端和 Ptyxis，那么应用了此补丁后，右键菜单里会两个选项都显示。与此同时，这也意味着在应用了该补丁后，从 GNOME 文件管理器就无法启动 GNOME 控制台了。这对我个人而言倒无所谓，因为我本来也不使用 GNOME 控制台。

[fedora-nautilus-patch]: https://src.fedoraproject.org/rpms/nautilus/blob/f42/f/default-terminal.patch

### GLib

GLib 需要来自 Fedora 的另一个[补丁][fedora-glib2-patch]。该补丁所做的是将 Ptyxis 加到 GLib 源代码中列举已知的终端模拟器应用程序的列表当中。我也是看到这个补丁才了解到 GNOME 启动应用的过程并非由其独自完成，而是要借助 GLib。

其实这个补丁完全可以提交到 GLib 上游，这样在所有 Linux 发行版上，GNOME 就都能用 Ptyxis 启动纯终端桌面图标，各发行版就无需像 Fedora 这样在下游应用补丁了。不过，GLib 上游已经拒绝了一个[类似的补丁][glib-ptyxis-mr]，原因是他们倾向于直接用 [`xdg-terminal-exec`]。`xdg-terminal-exec` 是一项目前仍在提议阶段的 XDG 新标准，将为应用程序提供一套接口，以允许程序将自身注册为终端模拟器应用；但是，该标准从最初起草至今已经过去 6 年了，到现在都还未被正式批准成为官方 XDG 标准！好在，该标准的草稿在近期依然有修订。但愿 `xdg-terminal-exec` 或者其它类似的标准（例如 `xdg-default-apps`）能尽快通过，这样就不需要这个补丁了。

[fedora-glib2-patch]: https://src.fedoraproject.org/rpms/glib2/blob/f42/f/default-terminal.patch
[glib-ptyxis-mr]: https://gitlab.gnome.org/GNOME/glib/-/merge_requests/4503
[`xdg-terminal-exec`]: https://github.com/Vladimir-csp/xdg-terminal-exec/

### 在 Gentoo 上应用补丁

我使用的发行版是 Gentoo，其以允许用户从源代码编译系统上的软件包而闻名，因此我可以轻松地应用上述的补丁：只需将它们作为用户补丁添加到 Portage 即可。上述的两个软件包在 Gentoo 上分别为 `gnome-base/nautilus` 和 `dev-libs/glib`，使用 Gentoo 的读者可以参考。

## 配色方案

解决了 Ptyxis 与其它 GNOME 组件的整合后，我便开始折腾起了所有人都喜欢炫耀的东西：终端的外观。

Ptyxis 提供了大量内置的终端配色方案以及选择内置配色方案的图形界面，但截至版本 47.13，Ptyxis 的图形界面暂未提供让用户创建自己的配色方案的功能，也未提供单独修改内置配色方案中的每一种颜色的功能。而 GNOME 终端的图形界面就允许单独修改每种颜色。因此，我一开始以为 Ptyxis 是根本没提供自定义配色方案的功能。

![Ptyxis 首选项中的外观选项]({{< static-path img ptyxis-prefs-appearance.png l10n >}})

不过，后来通过在线搜索，我发现 Ptyxis 还是支持完全自定义配色方案的，只是自定义需要通过配置文件来进行，而非图形界面。用户通过在正确的路径下创建 `.palette` 文件，即可创建自己的配色方案；正确的路径在 [Ptyxis 项目的 README 文件][ptyxis-readme-customization]中有介绍。想创建自己的 `.palette` 文件用户，可参考[内置配色方案的 `.palette` 文件][ptyxis-src-palettes]为例。

Ptyxis 通过纯文本配置文件实现配色方案自定义这一点，我觉得是不错的，因为这样一来，备份和还原自定义配色方案就容易很多。相比之下，GNOME 终端的自定义配色方案设置是存在 dconf 里的，相当于 Windows 的注册表。虽然 dconf 设置可以以纯文本形式导入和导出，就像 Windows 注册表的 `.REG` 文件那样，但是额外的导入导出流程终究还是让备份和还原设置的流程变得比直接用纯文本配置文件更繁琐。

考虑到 Ptyxis 的主要目标用户群体是软件开发人员，或许它不支持通过图形界面自定义配色方案也不是什么大问题；毕竟它的 README 文件是这样介绍它的：“it's engineered... for modern development workflows within the GNOME desktop, where local containers are first-class citizens.”软件开发人员普遍都接触过软件配置文件，并且很多开发者都更倾向于使用纯文本的配置文件，而非像 dconf 和 Windows 注册表这些二进制格式的数据库。不过我认为，Ptyxis 的图形界面哪怕只是加一行字，提示用户应使用 `.palette` 文件而非图形界面来自定义配色方案，也是项不错的改进，能让用户更容易发现这个功能。

[ptyxis-readme-customization]: https://gitlab.gnome.org/chergert/ptyxis#customization--theming
[ptyxis-src-palettes]: https://gitlab.gnome.org/chergert/ptyxis/-/tree/main/src/palettes

### 内置配色方案

因为我可能在多台电脑上安装 Ptyxis，我还是决定先找个我喜欢的内置配色方案。毕竟如果我用自定义配色方案、且我想在所有电脑上应用同样的终端外观的话，我就还得将我自己创建的 `.palette` 文件同步到所有电脑上，需要额外的步骤。如果我用某个内置配色方案的话，我就只需要在每台电脑上的 Ptyxis 首选项中选择该方案就行了，不需要额外复制 `.palette` 文件。

默认的“GNOME”配色方案与我理想中的配色方案已经很接近了，但仍然有个缺点。至少在我看来，它的深蓝色太暗，在深色背景之上对比度太低，导致文字可读性差，例如下图中的 IPv6 地址（`inet6`）。其实，我在用 GNOME 终端时选择的也是它的“GNOME”配色方案，和 Ptyxis 的同名方案基本是一样的，但我会把深蓝色调亮，以提高可读性。我当然也可以选择在 Ptyxis 里通过创建自己的 `.palette` 文件同样地将深蓝色调亮，但我还是想先看看其它内置配色方案有没有我满意的；如果有的话，我就可以省去创建 `.palette` 文件的麻烦了。

![Ptyxis 的“GNOME”配色方案样例]({{< static-path img ptyxis-gnome-palette.png >}})

Ptyxis 内置的配色方案多达 200 多个；我尽力把每个都至少简单看一下。最后，我选择了 Argonaut。它的默认文本颜色足够亮，背景颜色足够暗，且不同颜色间的对比度也不错，即使是在打开夜光的情况下。如果 Argonaut 的深紫色能亮一点就更好了。我心中的第二名是 Ibm3270，而它不好的一点是，在夜光开启时，我很难区分蓝色和白色的文字。

{{<fig>}}
![Ptyxis 的“Argonaut”配色方案样例]({{< static-path img
ptyxis-argonaut-palette.png >}})
{{<figcaption>}}Argonaut 配色方案{{</figcaption>}}
{{</fig>}}

对于同样想挑选一个内置配色方案的读者，我推荐参考 Gogh 的一个[网页][gogh-preview]。Ptyxis 的大部分内置配色方案都来自 Gogh，因此 Gogh 的这个网页可以用来方便地预览配色方案。

![Gogh 网页的内容]({{< static-path img gogh.png >}})

[gogh-preview]: https://gogh-co.github.io/Gogh/

## 用户体验

外观并非评价软件的唯一因素（否则 Windows 11 就不会有这么多差评了）；软件的功能和用户体验如果不是更重要的因素，至少也是同样重要的因素。Ptyxis 的用户体验给我的感觉非常好，乃至于比 GNOME 终端的用户体验要更胜一筹。

一开始，Ptyxis 给了我个惊喜：我发现我在 GNOME 终端中熟悉的“查找”按钮，到了 Ptyxis 中就无影无踪了。起初，我还以为是 Ptyxis 不支持搜索终端历史。我在 GNOME 终端中虽然经常用快捷键完成一些操作，例如 Shift+Ctrl+N 打开新标签页，但听起来可能比较魔幻的是，在搜索终端历史时，我却一直都是点击图形界面上的“查找”按钮。当然，Ptyxis 还是支持搜索历史的（要是还有哪个终端模拟器不支持搜索历史，那也是奇葩了），只是要用键盘快捷键激活（Shift+Ctrl+F）。因为在搜索历史时，用户肯定会用键盘来键入要搜索的关键词，所以使用键盘快捷键（而非用户界面上需要用鼠标点击的按钮）来激活搜索功能的设计倒也合理。

{{<fig>}}
![GNOME 终端和 Ptyxis 用户界面的顶栏]({{< static-path img top-bars.png >}})
{{<figcaption>}}
上：GNOME 终端的顶栏，可见其“查找”按钮。下：Ptyxis 的顶栏，并无“查找”按钮。
{{</figcaption>}}
{{</fig>}}

Ptyxis 的“已复制到剪贴板”提示信息是个不错的功能，为结果不明显的操作提供了明确的反馈。GNOME 终端是没有这样的信息的。

![Ptyxis 的“已复制到剪贴板”提示信息]({{< static-path img copied-to-clipboard.png l10n >}})

Ptyxis 还有其它几个可圈可点的功能，应该拜 GNOME 控制台所赐：这些功能都是首先在 GNOME 控制台中出现、但在 Ptyxis 中也实现了的。

第一个功能是，建立交互式 SSH 连接时，窗口顶栏的颜色会发生变化。这个功能对我非常有用，因为不同的顶栏颜色有助于我轻松区分远程连接的终端和本机的终端。我有时会开启多个终端窗口，分别连接到不同的机器；在用 GNOME 终端时，我就犯过几次在错误的终端窗口中运行 `rm` 、导致删错文件的失误。因为我之前没有采取任何在视觉上明显区分远程和本地终端的措施，所以选错了窗口，酿成了失误。

{{<fig>}}
![两个看起来一模一样的 GNOME 终端窗口并排显示]({{< static-path img gnome-terminal-local-remote.png >}})
{{<figcaption>}}
两个 GNOME 终端窗口，其中一个是本地终端，而另一个则连接到远程机器。你能区分出哪个是本地、哪个是远程吗？
{{</figcaption>}}
{{</fig>}}

为了避免类似的失误再次发生，我一直以来采取的策略是在登录 SSH 会话后马上运行 tmux，这样就可以用 tmux 的绿色底栏来鉴别远程连接的终端了。而现在使用了 Ptyxis 后，远程连接的终端，其顶栏颜色会自动变化，我也就不必非要这样操作了。

![两个 Ptyxis 终端窗口并排显示；远程连接的终端顶栏变为蓝色]({{< static-path img ptyxis-local-remote.png >}})

调整窗口大小时，窗口右下角显示的终端行列数也是我觉得很实用的功能。我有时想把终端调整到某个确切的尺寸，比如我个人习惯的 80 行×24 列。有了右下角显示的终端大小，我就能更轻松地将窗口调整到正确的尺寸。

![Ptyxis 在窗口右下角显示的终端大小]({{< static-path img terminal-size-pop-up.png >}})

“命令已完成”的通知也非常好。几年前我还在日常使用 Fedora 时，我见过 GNOME 终端弹出这种通知。然而，这种通知并非 GNOME 终端的原生功能，而是由 Fedora 通过[下游补丁][fedora-vte291-patch]才实现的。因此，我在 Gentoo 上从未见过 GNOME 终端弹出这种通知，除非我应用 Fedora 的补丁。而 Ptyxis 原生就支持在命令完成时发出此类通知，无需任何补丁。

![“命令已完成”通知]({{< static-path img command-completed.png l10n >}})

[fedora-vte291-patch]: https://src.fedoraproject.org/rpms/vte291/blob/f39/f/vte291-cntnr-precmd-preexec-scroll.patch#_267
