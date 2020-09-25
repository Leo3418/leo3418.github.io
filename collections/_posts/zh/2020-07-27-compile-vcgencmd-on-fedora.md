---
title: "在 Fedora 上安装树莓派的 `vcgencmd` 命令"
lang: zh
tags:
  - 树莓派
  - Fedora
  - GNU/Linux
categories:
  - 教程
asciinema-player: true
toc: true
last_modified_at: 2020-09-25
---

这篇帖子算是对我之前关于[在树莓派集群上配置 Fedora](/2020/07/24/fedora-raspi-cluster.html) 的那篇的一个延续。集群配置好后，我告知机主 [**@ColsonXu**](https://github.com/ColsonXu) 他的集群已经正式投入运算，他就告诉我可以运行一个命令来查看树莓派的 CPU 温度，监视硬件状况：

```console
$ /opt/vc/bin/vcgencmd measure_temp
```

这个 [`vcgencmd` 命令](https://www.raspberrypi.org/documentation/raspbian/applications/vcgencmd.md)是树莓派 OS（旧称 Raspbian）上用来获取硬件相关信息的命令。然而，这个命令在 Fedora 官方的软件仓库里并没有提供。好在 `vcgencmd` 的源代码是可以下载的，所以我们可以自行编译它，就能在 Fedora 上使用了。`vcgencmd` 是树莓派 OS 中 `userland` 软件包的一部分，而整个 `userland` 的源代码都可以直接从网上获取。

## 构建和安装过程

1.  下载构建过程中所需的工具和编译器、以及用于下载源代码的 Git。

    ```console
    $ sudo dnf install cmake gcc gcc-c++ make git
    ```

    {% include asciinema-player.html name="install-deps.cast" poster="npt:9" %}

2.  下载 `userland` 软件包的源代码，然后进入下载的目录。

    ```console
    $ git clone https://github.com/raspberrypi/userland.git
    $ cd userland
    ```

3.  运行 `./buildme --aarch64` 命令，为 Fedora 使用的 `aarch64` 架构编译软件包。

    命令运行过程中，当编译完成、准备安装编译好的程序时，可能会出现 `sudo` 要求输入密码的提示，相应地输入密码即可。

    ```console
    $ ./buildme --aarch64
    ```

    {% include asciinema-player.html name="build-and-install.cast"
    poster="npt:16.5" start_at="10" %}

命令完成后，就可以在 `/opt/vc/bin` 下找到 `vcgencmd` 命令了。

{% include asciinema-player.html name="after-install.cast" poster="npt:6" %}

## 注册与 `/opt/vc` 相关的路径

虽然 `vcgencmd` 安装好了，但是如果现在运行它的话，会出现如下报错：

```console
$ /opt/vc/bin/vcgencmd
/opt/vc/bin/vcgencmd: error while loading shared libraries: libvchiq_arm.so: cannot open shared object file: No such file or directory
```

这条错误信息的意思是找不到运行 `vcgencmd` 所需要的库 `libvchiq_arm.so`。虽然 `/opt/vc/lib` 下面是有这个文件的，但是 `/opt/vc/lib` 不在系统搜索函数库的范围内，所以会说找不到该文件。解决这个问题的方法是在 `/etc/ld.so.conf.d` 下新建一个后缀为 `.conf` 的文件，然后在该文件中写上下面一行：

```
/opt/vc/lib
```

之后运行如下命令，应用刚创建的新文件：

```console
$ sudo ldconfig
```

现在再运行 `/opt/vc/bin/vcgencmd` 就不会再出现同样的报错了。

{% include asciinema-player.html name="ldconfig.cast" poster="npt:5" %}

目前还有一个小瑕疵，那就是每次运行 `vcgencmd` 的时候都需要输入它的完整的绝对路径。如果不想这么麻烦的话，可以把 `vcgencmd` 所在的 `/opt/vc/bin` 加到 `PATH` 环境变量中。编辑 `~/.bashrc` 并作出如下修改：

```diff
 # User specific environment
 if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
 then
     PATH="$HOME/.local/bin:$HOME/bin:$PATH"
 fi
+PATH="/opt/vc/bin:$PATH"
 export PATH
```

之后运行下面的命令，应用刚才的改动：

```console
$ source ~/.bashrc
```

{% include asciinema-player.html name="add-to-path.cast" poster="npt:17" %}

## 配置设备权限和用户组

此时尝试在一个普通的用户下运行 `vcgencmd` 读取硬件信息的话，还是会遇到 `VCHI initialization failed` 的错误信息。

{% include asciinema-player.html name="init-failed.cast" poster="npt:7" %}

这个问题的解决方案在网上很多地方都能找到，那就是将该用户加入到 `video` 用户组中。不过这个办法都是只适用于树莓派 OS。在 Fedora 上的话，还需要一道额外步骤：允许 `video` 组中的的用户访问 VCHI 设备。具体的做法是添加一个新的 [udev 规则](https://wiki.archlinux.org/index.php/Udev_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#udev_%E8%A7%84%E5%88%99)，可以使用 GitHub 用户 [**@sakaki-**](https://github.com/sakaki-) 在[此处](https://github.com/sakaki-/genpi64-overlay/blob/master/media-libs/raspberrypi-userland/files/92-local-vchiq-permissions.rules)发布的规则文件。

```console
$ cd /usr/lib/udev/rules.d/
$ sudo curl -O https://raw.githubusercontent.com/sakaki-/genpi64-overlay/master/media-libs/raspberrypi-userland/files/92-local-vchiq-permissions.rules
```

{% include asciinema-player.html name="udev-rule.cast" poster="npt:11" %}

之后，`video` 组中的用户就可以正常调用 `vcgencmd` 命令了。

```console
$ sudo usermod -aG video $USER
```

{: .notice--warning}
**注意：**此部分中提及的改动需要重启才能生效。

{% include asciinema-player.html name="add-to-group.cast" poster="npt:7.2" %}

## 使用 DNF 安装 `vcgencmd`

虽然能自己编译所需的软件是一项有用的技能，但如果不想自己编译的话，可以直接使用我制作的 RPM 软件包来安装。我把软件包上传到了一个 [Copr 仓库](https://copr.fedorainfracloud.org/coprs/leo3418/raspberrypi-userland/)，可从该处下载然后安装，就可以直接开始使用 `vcgencmd`。

```console
$ sudo dnf copr enable leo3418/raspberrypi-userland
$ sudo dnf install raspberrypi-userland
```

如果用我的 RPM 软件包的话，就可以跳过上面的构建和安装步骤了，包括在 `/etc/ld.so.conf.d` 下创建 `.conf` 文件、修改 `~/.bashrc`、以及安装 udev 规则。您唯一需要额外进行的操作就是将您的用户帐户添加到 `video` 用户组中。

{% include asciinema-player.html name="dnf.cast" poster="npt:3.8" %}

您还可以使用我写的 SPEC 文件自行创建 `userland` 的 RPM 软件包，这里我就只做一个演示，不给出详细步骤了。

{% include asciinema-player.html name="build-rpm.cast"
    poster="data:text/plain,RPM 构建演示" %}
