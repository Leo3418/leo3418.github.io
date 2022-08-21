---
title: "在 Fedora 上安装树莓派的 `vcgencmd` 命令"
tags:
  - 树莓派
  - Fedora
  - GNU/Linux
categories:
  - 教程
toc: true
lastmod: 2022-03-11
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

    {{< asciicast poster="npt:9" >}}
    {{< static-path res install-deps.cast >}}
    {{< /asciicast >}}

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

    {{< asciicast poster="npt:16.5" startAt=10 >}}
    {{< static-path res build-and-install.cast >}}
    {{< /asciicast >}}

命令完成后，就可以在 `/opt/vc/bin` 下找到 `vcgencmd` 命令了。

{{< asciicast poster="npt:6" >}}
{{< static-path res after-install.cast >}}
{{< /asciicast >}}

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

{{< asciicast poster="npt:5" >}}
{{< static-path res ldconfig.cast >}}
{{< /asciicast >}}

目前还有一个小瑕疵，那就是每次运行 `vcgencmd` 的时候都需要输入它的完整的绝对路径。如果不想这么麻烦的话，可以把 `vcgencmd` 所在的 `/opt/vc/bin` 加到 `PATH` 环境变量中。变动 `PATH` 环境变量的一种方法是编辑 `~/.bashrc`，作出如下修改：

```diff
  # User specific environment
  if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
  then
      PATH="$HOME/.local/bin:$HOME/bin:$PATH"
  fi
+ PATH="/opt/vc/bin:$PATH"
  export PATH
```

之后运行下面的命令，应用刚才的改动：

```console
$ source ~/.bashrc
```

{{< asciicast poster="npt:17" >}}
{{< static-path res add-to-path.cast >}}
{{< /asciicast >}}

## 配置设备权限和用户组

此时，如果尝试在一个普通的用户下运行 `vcgencmd` 读取硬件信息的话，还是会遇到 `VCHI initialization failed` 的错误信息。

{{< asciicast poster="npt:7" >}}
{{< static-path res init-failed.cast >}}
{{< /asciicast >}}

这个问题的解决方案在网上很多地方都能找到，那就是将该用户加入到 `video` 用户组中。不过，这个办法只适用于树莓派 OS；在 Fedora 上的话，还需要一道额外步骤：允许 `video` 组中的的用户访问 VCHI 设备。具体的做法是添加一个新的 [udev 规则](https://wiki.archlinux.org/index.php/Udev_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#udev_%E8%A7%84%E5%88%99)：

```
KERNEL=="vchiq",GROUP="video",MODE="0660"
```

目前，该 udev 规则仅在相对比较新的内核（5.16 及以上）上测试过；在老版本内核上可能无法达到预期的效果。如果使用的内核版本比较老，并且该规则不管用的话，请升级到最新的内核。
{.notice--warning}

添加 udev 规则的方法是在 `/etc/udev/rules.d` 下创建一个文件扩展名是 `.rules` 的文件，然后将规则文本加到该文件中。可以使用下列命令来完成此操作，将规则添加至名为 `92-local-vchiq-permissions.rules` 的文件：

```console
$ sudo tee /etc/udev/rules.d/92-local-vchiq-permissions.rules <<< 'KERNEL=="vchiq",GROUP="video",MODE="0660"'
```

udev 规则加好后，无需重启，直接运行下列命令即可应用规则：

```console
$ sudo udevadm trigger /dev/vchiq
```

若要检查 udev 规则是否被应用，可以查看 VCHI 设备文件 `/dev/vchiq` 的权限设定。如果该文件所属的用户组是 `video`，就说明规则应用成功了。

```console
$ ls -l /dev/vchiq
crw-rw----. 1 root video 511, 0 Nov  9 23:17 /dev/vchiq
```

之后，`video` 组中的用户就可以正常调用 `vcgencmd` 命令了。可以用下面的命令将当前的用户添加到 `video` 组中，但是在运行完命令后**必须重新登录才能令更改生效**。

```console
$ sudo usermod -aG video $USER
```

{{< asciicast poster="npt:7.2" >}}
{{< static-path res add-to-group.cast >}}
{{< /asciicast >}}

## 使用 DNF 安装 `vcgencmd`

虽然能自己编译所需的软件是一项有用的技能，但如果不想自己编译的话，可以直接使用我制作的 RPM 软件包来安装。我把软件包上传到了一个 [Copr 仓库](https://copr.fedorainfracloud.org/coprs/leo3418/raspberrypi-userland/)，可从该处下载然后安装，就可以直接开始使用 `vcgencmd`。

```console
$ sudo dnf copr enable leo3418/raspberrypi-userland
$ sudo dnf install raspberrypi-userland
```

如果用我的 RPM 软件包的话，就可以跳过上面的构建和安装步骤了，包括在 `/etc/ld.so.conf.d` 下创建 `.conf` 文件、修改 `~/.bashrc`、以及安装 udev 规则。唯一需要手动额外进行的操作就是将用户帐户添加到 `video` 用户组中。

{{< asciicast poster="npt:3.8" >}}
{{< static-path res dnf.cast >}}
{{< /asciicast >}}

也可以使用我写的 SPEC 文件自行创建 `userland` 的 RPM 软件包，这里我就只做一个演示，不给出详细步骤了。

{{< asciicast poster="data:text/plain,RPM 构建演示" >}}
{{< static-path res build-rpm.cast >}}
{{< /asciicast >}}
