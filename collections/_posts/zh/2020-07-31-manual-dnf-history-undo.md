---
title: "手动进行 `dnf history undo`"
lang: zh
asciinema-player: true
toc: true
---
{% include res-path.liquid %}

我平时常用的 GNU/Linux 发行版包括 Fedora 和 CentOS。后者主要在服务器上使用，而在其它的使用场景下，比如我自己的电脑，就会使用前者。选择这两个发行版主要是因为这它们都使用 DNF 作为软件包管理器前端。有人嫌 DNF 太慢，但我喜欢它是因为它不仅会详细列出它将要进行的操作，包括装卸什么软件包、什么架构、什么版本，还允许方便地查询历史记录。DNF 对其运行的每个事务都保存记录（一个事务就是一次安装或卸载软件包的操作），并且还支持使用 `dnf history undo` 撤销事务，或使用 `dnf history rollback` 回滚到某一个事务。其它的一些像 APT 和 Pacman 的软件包尽管也会保存日志，但是并没有类似的撤销操作的功能。

正是因为有 `dnf history undo` 这种功能，我方能保持系统的整洁。如果我用 DNF 装了一个软件包，却发现并不是我想要的，可以直接用 `dnf history undo last` 将其卸载。最为重要的是，这个命令还会将该软件包的所有依赖一并删除，不会出现一个软件包被卸载但依赖包还残留在系统中，导致系统里无用的软件包越来越多的情况。

## 无法使用 `dnf history undo` 的情况

用 `dnf history undo` 撤销一个不久前运行的事务往往没有问题，但是如果一个事务是一段时间以前运行的，可能就不好用。我最近就遇到了一例。

一个月以前，为了能在 Fedora 上玩一些本该在 Windows 上运行的老游戏，我装了一个 Wine。一段时间过后，我发现兼容性并没有那么完美，不得不回到 Windows，故准备卸载 Wine。

我首先运行的指令是 `dnf history list wine`，用来查询哪些事务牵扯到了 `wine` 软件包。从程序输出中可以看出，事务 217 是安装了 `wine` 的事务。

{% include asciinema-player.html name="view-history.cast" poster="npt:5" %}

所以说，运行 `dnf history undo 217` 就可以卸载了。然而……

{% include asciinema-player.html name="failed-history-undo.cast"
    poster="npt:5" %}

这个时候，所有跟 Wine 有关的软件包都还没卸载呢，可为什么 DNF 报了错，说这些软件包没被安装呢？原因是 217 号事务（[日志]({{ res_path }}/transaction-217.txt)）安装了 Wine 5.10，但是 229 号事务（[日志]({{ res_path }}/transaction-229.txt)）把 Wine 更新到了 5.12。`dnf history undo` 在查找软件包时，会同时根据包名、版本和架构来寻找，所以在这条命令看来， `wine-5.10-1.fc32.x86_64` 和 `wine-5.12-1.fc32.x86_64` 就不是同一个软件包。

总而言之，**如果您更新了一个事务中任何改动过的软件包，那么用 `dnf history undo` 撤销该事务就会失败**。这也是为什么撤销近期的事务一般能成功，但撤销比较久远的事务可能不行。

## `dnf remove` 可以用吗？

`dnf remove` 可以连带移除一个软件包的依赖，所以直接运行 `dnf remove wine` 和 `dnf history undo 217` 的理论效果应当是一样的。不过，当我运行它的时候……

{% include asciinema-player.html name="remove.cast" poster="npt:4" %}

DNF 告诉我这条命令只会删除 83 个软件包，但是刚刚 `dnf history list wine` 命令的输出显示的相关软件包数量是 197 个，也就是说如果我用 `dnf remove` 的话，会残留 114 个无用的软件包。

## 手动撤销事务

虽然直接用 `dnf history undo` 撤销 217 号事务不可行，但是仍然可以从 `dnf history info 217` 命令的[输出]({{ res_path }}/transaction-217.txt)中查看这个事务都安装了哪些软件包。我当时的思路就是从这条命令的输出中把所有被安装的软件包的名字找出来，然后作为参数传入 `dnf remove` 命令来全部删除。

以下是该命令输出的节选：

```
    ...
    Install pulseaudio-libs-13.99.1-4.fc32.i686                       @updates
    Install samba-common-tools-2:4.12.3-0.fc32.1.x86_64               @updates
    Install samba-libs-2:4.12.3-0.fc32.1.x86_64                       @updates
    Install samba-winbind-2:4.12.3-0.fc32.1.x86_64                    @updates
    Install samba-winbind-clients-2:4.12.3-0.fc32.1.x86_64            @updates
    Install samba-winbind-modules-2:4.12.3-0.fc32.1.x86_64            @updates
    Install sane-backends-drivers-cameras-1.0.30-1.fc32.i686          @updates
    Install sane-backends-drivers-scanners-1.0.30-1.fc32.i686         @updates
    Install sane-backends-libs-1.0.30-1.fc32.i686                     @updates
    Install spirv-tools-libs-2019.5-2.20200421.git67f4838.fc32.i686   @updates
    Install spirv-tools-libs-2019.5-2.20200421.git67f4838.fc32.x86_64 @updates
    ...
```

这里列出的软件包都是以它们的 **NEVRA** 表示的。NEVRA 是指 Name, Epoch, Version, Release, Architecture，勉强翻译成中文就是“包名、时期、版本、发布、架构”。

在 RPM 中，时期的作用是避免一些软件项目瞎玩版本号，导致版本号排序出现混乱。比如 Java 5 版本号是 `5.0`，但到了 Java 6 却变成了 `1.6`。由于 `1.6` 比 `5.0` 小，RPM 会认为 Java 6 的版本比 Java 5 低，但这纯粹是因为 Java 版本号混乱导致的。这个时候，在版本号前面加上时期就可以解决排序问题。比如 Java 5 是时期 1，RPM 版本号就是 `1:5.0`；Java 6 版本号编号规则变化，就把时期加一，到了时期 2，RPM 版本号为 `2:1.6`；`2:1.6` 此时就比 `1:5.0` 大了。具体的规则，可以参考 [Fedora 官方文档](https://docs.fedoraproject.org/en-US/packaging-guidelines/Versioning/#_upstream_makes_unsortable_changes)。

而发布的作用就是在一个软件自身的版本没有变化，但是软件包维护者需要重新发布一个相同版本的软件包时，用来区分这两次发布。比如说，Vim 发布了新版本 `8.2.1224`，Fedora 软件包维护者就会下载这个版本的源码，然后根据 Fedora 项目自己写的 RPM 配置文件进行编译和打包，推出 `8.2.1224-1` 版本的 RPM 包，此时是发布 1。但是后来维护者发现编译的时候有几个编译器选项忘了开了，需要重新编译并打包，此时就需要把发布改为 2，重新推出一个 `8.2.1224-2` 版本的 RPM 包了，因为 Vim 上游的版本没变，只是 Fedora 自己重新编译了相同的版本、重发布了一遍。

这里列出的 NEVRA 的格式是 `name-[epoch:]version-release.arch`。当一个软件包被更新时，NEVRA 的 `[epoch:]version-release` 部分会变，但是剩下的 `name` 和 `arch` 会保持一致，所以我这里的思路就是把 `name-[epoch:]version-release.arch` 转成 `name.arch`，就可以标识不同版本的同一软件包。

由于总共有 197 个软件包，手工进行转换不仅无聊还容易出错，所以我就尝试使用 Unix 命令，让电脑来完成这项工作。

首先，我用 `grep` 来精简命令的输出。输出的最开始是一些关于这个事务的一些信息，并不包含任何软件包名，应该被删去。每个有软件包 NEVRA 的行都有“Install”字样，所以可以根据有没有这个词来判断每行文字是否有软件包名。与此同时，我把软件包列表保存到了一个文件里，方便后面的处理。

```console
$ sudo dnf history info 217 | grep 'Install' > /tmp/installed-pkgs.txt
```

{% include asciinema-player.html name="filter-nevras.cast" poster="npt:8" %}

下一步就是把每一行的头和尾都去掉，只保留中间的软件包 NEVRA，也就是把“Install”、以 `@` 开头的软件仓库信息和任何空格都删除。最快捷的方法就是使用 `sed`。我在这里指定了 `-i` 选项，意思就是直接在提供给 `sed` 的文件里原地编辑，并且用了 `-E` 选项以使用扩展正则表达式。

```console
$ sed -i -E 's/^ *Install *//g' /tmp/installed-pkgs.txt
$ sed -i -E 's/ *@.+$//g' /tmp/installed-pkgs.txt
```

{% include asciinema-player.html name="trim-lines.cast" poster="npt:1.5" %}

这样一来，每行就只剩下 `name-[epoch:]version-release.arch` 格式的 NEVRA，没有别的东西了。下一步就可以把它们转换为 `name.arch` 格式了。为此，我尝试写了一个匹配 `-[epoch:]version-release` 的正则表达式规则：

```
   -([0-9]+:)?[0-9][0-9A-Za-z.-]*\.(el|fc)[0-9]+(_[0-9]+)?(\.[0-9]+)?
1~~^^~~~~2~~~^^~~~~~~~~3~~~~~~~~^^~~~~~~~~~~~4~~~~~~~~~~~^^~~~~5~~~~^
```

这个正则表达式总共由五部分组成：

1.	一个横杠 `-`，用来分隔包名和版本信息。

2.	匹配“时期”。时期并不是每个软件包都有的属性，所以这部分以问号 `?` 结尾，在正则表达式里的意思就是它前面的部分是可有可无的。

3.	匹配“版本”、以及“发布”的一部分。一般地，版本都是以数字开头，并且可以包含多个数字和小数点 `.`。但版本也可以包含字母，例如 `tzdata-2020a`。发布当中也可以有字母，如 `crontabs-1.11-22.20190603git`。

4.	匹配 RPM 宏标签 `%{?dist}` 的值。运行命令 `rpm --eval %{?dist}` 就可以查看您的系统上这个标签对应的值。这个值标志着这个 RPM 包是给哪个发行版版本构建的，比如 `.fc32`、`.el8`、或者 `.el8_2`。

5.	有些软件包可能在 `%{?dist}` 后面还有小版本号。和时期一样，不是每个软件包的 NEVRA 都有这部分，所以这部分的正则表达式同样以问号结尾。

这个正则表达式可以用于 Fedora 的大多数软件包和 CentOS 还有 RHEL 所有遵循 Fedora 软件包版本号规范的包。我唯一知道的例外是 `ntfs-3g-system-compression-1.0-3.fc32.x86_64`，因为它的包名里在横杠后面有数字。不过，这个正则表达式已经是我能想到的最好的了。除非您要处理的软件包里有类似的名字里横杠后面有数字的极端情况，否则应该是无所谓的。

为保险起见，您可以先运行下面的命令检查这个正则表达式能否准确匹配每个 NEVRA 的 `-[epoch:]version-release` 部分。匹配的部分会以红色字体标出。

```console
$ grep -E -- '-([0-9]+:)?[0-9][0-9A-Za-z.-]*\.(el|fc)[0-9]+(_[0-9]+)?(\.[0-9]+)?' /tmp/installed-pkgs.txt
```

{% include asciinema-player.html name="check-conversion.cast" poster="npt:7" %}

如果看起来没问题的话，就可以用 `sed` 作正式的修改了。

```console
$ sed -i -E 's/-([0-9]+:)?[0-9][0-9A-Za-z.-]*\.(el|fc)[0-9]+(_[0-9]+)?(\.[0-9]+)?//g' /tmp/installed-pkgs.txt
```

{% include asciinema-player.html name="make-conversion.cast"
    poster="npt:1.5" %}

现在我就得到了以 `name.arch` 格式列出的软件包列表，接下来需要做的就是把列表中的每一个软件包都以命令行参数的形式提供给 `dnf remove` 命令。将一个文件里的每一行都作为一个参数提供给一个命令是 `xargs` 的拿手绝活。`xargs` 默认是从标准输入读取参数，但它的 `-a` 选项允许直接从一个文件来读取。

```console
$ xargs -a /tmp/installed-pkgs.txt sudo dnf remove
```

{% include asciinema-player.html name="xargs.cast" poster="npt:7" %}

这里的事务摘要显示有 197 个软件包会被删除，和之前的软件包数是一致的。没有用不上的软件包会残留在系统中，也没有额外的软件包被意外卸载。当您执行这一步时，也**请仔细核实受影响的软件包数量**，避免意外删除关键的系统软件包。如果发现有任何问题，请检查 DNF 的错误信息和您的软件包列表文件。

到这一步，DNF 事务的手动撤销就完成了。整个过程中使用的命令包括 `dnf history undo`、`grep`、`sed`、`xargs` 和 `dnf remove`，都只是一些普通的命令；`grep`、`sed` 和 `xargs` 更只是平凡的 Unix 程序，却在手动撤销 DNF 事务这一特定任务中发挥了重要作用。这是 Unix 哲学的体现：多个通用的软件协同工作，仅凭纯文本作为彼此之间互相交流的接口，共同完成一个复杂和具体的任务。

## 一个命令包揽整个任务

在上面的步骤中，我创建了一个软件包列表文件 `/tmp/installed-pkgs.txt`，方便我观察上述的每个指令会如何修改软件包列表。然而，这个文件并不是必须的。如果您对每个命令的作用足够熟悉的话，完全不需要通过创建一个文件来观察它们在干什么，直接用 Unix 管道（pipe）把所有命令连接起来即可。管道可以让一个程序的标准输出变成下一个程序的标准输入，中间不需要经过任何文件。与此同时，管道可以将多个零散的命令合并成一个超长的命令。

```console
$ sudo dnf history info <transaction-id> | \
    grep 'Install' | \
    sed -E 's/^ *Install *//g' | \
    sed -E 's/ *@.+//g' | \
    sed -E 's/-([0-9]+:)?[0-9][0-9A-Za-z.-]*\.(el|fc)[0-9]+(_[0-9]+)?(\.[0-9]+)?//g' | \
    xargs -o sudo dnf remove
```

和单独运行每个命令相比，这个使用管道的超长命令有如下不同：

- `sed` 命令的 `-i` 选项不再被使用了。在没有这个选项的情况下，`sed` 会直接将编辑好的文本转移到标准输出中。不过，因为管道需要将一个程序的标准输出作为下一个程序的标准输入，所以这样的行为正是我们需要的。

- 因为我们在这里不使用文件，所以也就不需要 `xargs` 的 `-a` 选项了。取而代之的是 `-o` 选项，允许您通过键盘与 `xargs` 运行的程序进行交互。对于 DNF 而言，它在运行一个事务之前会进行用户交互，要求您输入 `y` 进行确认，所以需要使用 `-o` 选项；不用这个选项的话，就没有输入 `y` 确认的机会。
