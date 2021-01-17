---
title: "在树莓派集群上配置 Fedora"
lang: zh
tags:
  - 树莓派
  - Fedora
  - GNU/Linux
categories:
  - 教程
asciinema-player: true
toc: true
---
{% include img-path.liquid %}
在开始之前，我首先要感谢考森同志 [**@ColsonXu**](https://github.com/ColsonXu) 给了我一个折腾树莓派的机会。他买了几个树莓派 4，准备组一个计算用的集群，可是建好后却没什么可计算的，没什么用场。直到一天早晨，达西 [**@mrdarcychen**](https://github.com/mrdarcychen) 在 Fedora 杂志上发现了一篇[在树莓派上跑 Rosetta@home 的文章](https://fedoramagazine.org/running-rosettahome-on-a-raspberry-pi-with-fedora-iot/)，于是就问考森要不要搞。在他同意之后，我便开始着手配置他的树莓派集群。

我拿到这堆树莓派的时候，集群已经设置好了。尽管我并没有问过机主本人他当时集群是怎么弄的，但他应该是按照[这篇 MagPi 杂志文章](https://magpi.raspberrypi.org/articles/build-a-raspberry-pi-cluster-computer)配置的。这篇文章里用的是树莓派 OS（旧称 Raspbian）而非 Fedora；如果想弄一个运行 Fedora 的树莓派集群，大体的流程还是相同的，但是具体的步骤和运行的命令有些不一样。接下来我将具体地介绍如何在 Fedora 上完成同样的集群配置步骤。

## 硬件

这个集群由四块树莓派 4 Model B 组成，用支持[以太网供电](https://zh.wikipedia.org/zh-cn/%E4%BB%A5%E5%A4%AA%E7%BD%91%E4%BE%9B%E7%94%B5)（PoE）的交换机连接。PoE 的好处就是供电也可以用网线顺便解决了，不用每个树莓派都弄一条电源线。尽管支持 PoE 的交换机不便宜，而且每个树莓派还得加一个 PoE 板，增加了成本，但好处是没有那么多线缆，相当整洁。

![用 PoE 供电的集群]({{ img_path }}/hardware-setup.png)

## 为何选择 Fedora 而非树莓派 OS

我拿到这个集群的硬件的时候，上面装是已经配置好的树莓派 OS，本质上就是个给树莓派定制的 Debian GNU/Linux。

既然是 Fedora 杂志，那发表在上面的文章肯定也是围绕着 Fedora 的，运行 Rosetta@home 的那篇文章里自然也是用 Fedora 来实现的。文章的作者用 Podman——Red Hat 开发的 Docker 替代方案——跑 [BOINC 客户端映像](https://hub.docker.com/r/boinc/client)的容器。Podman 和 Docker 作用类似，我完全可以在需要 Podman 的地方用 Docker，而且树莓派 OS 上也能安装和使用 Docker，所以我就先尝试不动已经有的操作系统，直接在上面安装 Docker 然后在容器里运行 BOINC 客户端。

这时候问题就出现了：Rosetta@home 要求 64 位环境。此帖被撰写之时，64 位版本的树莓派 OS 仍然在测试阶段，这个树莓派集群里的节点运行的也都是 32 位的版本，所以尽管树莓派 4 的 CPU 支持 64 位，Rosetta@home 不能运行。

现在看来，必须得装个 `aarch64` 架构的 64 位 Fedora 才能运行 Rosetta@home ，不能用原有的树莓派 OS 了。其实，任何支持 `aarch64` 架构的 GNU/Linux 发行版都可以用；我选择 Fedora 是因为比较熟悉，我在我自己的笔记本上用的就是它。

## 安装 Fedora

虽然 Fedora 官方还未支持树莓派 4，但是我仍然能成功安装并启动 Fedora 32 Minimal `aarch64` 映像。该映像可以从[这里](https://download.fedoraproject.org/pub/fedora-secondary/releases/32/Spins/aarch64/images/Fedora-Minimal-32-1.6.aarch64.raw.xz)下载。

因为我在自己电脑上用的就是 Fedora，所以我就装了 Fedora 的 `arm-image-installer` 来把映像写入到 SD 卡。如果您用的是别的操作系统也不用担心，有些其它的方法也可以写入映像：

- 参考 Fedora 官方文档的[指南](https://docs.fedoraproject.org/zh_CN/quick-docs/raspberry-pi/)，里面有在非 Fedora 系统上的操作方法。

- 如果您使用的是其它 GNU/Linux 发行版并且有一定的动手能力，您可以直接从[这里](https://pagure.io/arm-image-installer/releases)下载 `arm-image-installer`。

Fedora 杂志的那篇文章和 Fedora 的文档都有关于如何使用 `arm-image-installer` 的说明，这里我也就不再赘述了。我用来写入映像的命令是：

```console
$ sudo arm-image-installer --image Fedora-Minimal-32-1.6.aarch64.raw.xz \
    --target=rpi4 --media=/dev/sdX --resizefs --norootpass \
    --addkey ~/.ssh/id_rsa.pub
```

这个命令一些选项的含义：

- `--target=rpi4` 指定这个映像要用于一台树莓派 4。
- `--norootpass` 和 `--addkey` 选项允许使用您本机的 SSH 密钥远程登录到树莓派上的系统的 `root` 帐户，同时禁止通过使用密码登录 `root`，这也是一种比较安全的设定。如果您的机器上还没有 SSH 密钥，可以先使用 `ssh-keygen` 创建一个。

{% include asciinema-player.html name="arm-image-installer.cast"
   poster="npt:6" %}

切记要在每张要用的 SD 卡上都写入一遍映像！

## 启动 Fedora

成功写入映像后，把 SD 卡插进一块树莓派。如果您需要视频输出的话，就先连接显示器线再插电，然后根据屏幕指示登录。

如果您想和我一样，不准备把树莓派接到显示器上，纯粹通过 SSH 连接来管理的话，就在插上 SD 卡后直接开机，连上有线网，然后等候大概一分钟，让系统启动。因为 Fedora 默认是启用 SSH 的，所以只要知道树莓派的 IP 地址就可以远程登录。

目前大部分家用路由器都应该是支持查看连接的设备列表的，您可以从那里找到树莓派的 IP 地址。如果要用这种方法来查询 IP 地址的话，我建议一台一台地开机，而不是一股脑把所有树莓派都插上电，这样您就可以知道每台树莓派的 IP 地址是多少，而不是一下看到一堆新的 IP 却不知道谁是谁。

![我的路由器的配置界面]({{ img_path }}/router-config.png)

找到树莓派的 IP 地址后，就可以使用 SSH 登录 `root` 帐户了。

{% include asciinema-player.html name="init-ssh-con.cast" poster="npt:5" %}

## 设置主机名

MagPi 的那篇文章推荐给集群里的每个节点都设置一个独有的主机名，用来标识每一台树莓派。

在 Fedora 中修改主机名的最直接的方法就是编辑 `/etc/hostname` 文件，然后在里面填入您要使用的主机名。

{% include asciinema-player.html name="hostname.cast" poster="npt:4.8" %}

我这里准备把四个节点的主机名分别设为 `Summit0`、`Summit1`、`Summit2` 和 `Summit3`，因为我拿到这些树莓派时它们的主机名就是这样配置的，这样就可以和之前保持一致。您可以随便选您喜欢的主机名，还可以跳过 0 ，从 1 开始编号。

## 连接 Wi-Fi

Fedora 使用 `NetworkManager` 管理有线和无线网络。如果要连 Wi-Fi，首先使用命令 `nmcli dev wifi` 扫描周围的 Wi-Fi 网络，按 `Q` 键退出网络列表，然后用下面的命令连接您的 Wi-Fi：

```console
# nmcli dev wifi connect <SSID> password <PASSWD>
```

记得把 `<SSID>` 替换为您的 Wi-Fi 的名字，`<PASSWD>` 替换为密码。

{% include asciinema-player.html name="wifi-con.cast" poster="npt:4.7" %}

如果您要连接到隐藏的 Wi-Fi，那么请使用以下命令：

```console
# nmcli dev wifi connect <SSID> password <PASSWD> hidden yes
```

## 设置静态 IP 地址

MagPi 文章推荐给集群内的每个节点配置一个在 `10.0.0.0/24` 子网下的静态 IP 地址。如果您将树莓派用网线直连到路由器上的话，这么配置可能没有必要，不过我依然会介绍如何配置静态 IP。

**注意：进行这一步前，强烈建议您已经将树莓派连到了 Wi-Fi。**如果您没有显示器、树莓派也没连到 Wi-Fi 的话，那么设置静态 IP 之后，您可能就登不上您的树莓派了。即使您有显示器，因为大多数家用路由器并不使用 `10.0.0.0/24` 网段，所以给树莓派设置了静态 IP 后树莓派也上不了网，就必须依靠 Wi-Fi 来取得互联网连接。

下面两条命令会给树莓派分配一个 `10.0.0.0/24` 子网中的静态 IPv4 地址。请将第一条命令里 IP 地址中的 `X` 替换为合适的数值。

```console
# nmcli con mod 'Wired connection 1' ipv4.address 10.0.0.X/24 
# nmcli con mod 'Wired connection 1' ipv4.method manual
```

从此以后，当您需要通过 SSH 连接到树莓派时，您需要用无线网卡 `wlan0` 的 IP 地址来连接。使用 `ip addr` 命令可以查询无线网络连接的 IP 地址：

{% include asciinema-player.html name="view-ip-addr.cast" poster="npt:23.7"
    start_at="20" %}

我这里这条命令的输出中，`wlan0` 下面有个新的 IP 地址 `192.168.1.160`，以后再通过 SSH 连接的时候就应该用这个地址。

知道了无线网卡的 IP 地址后，重启树莓派。如果您使用 SSH 的话，尝试用新的 IP 地址来连接。

{% include asciinema-player.html name="connect-via-wifi.cast"
    poster="npt:2.7" %}

## 配置防火墙

在树莓派 OS 上是不需要配置防火墙的，所以 MagPi 文章里也没有提及。但是 Fedora 默认的防火墙——`firewalld`——限制更加严格一些，所以就需要手动配置防火墙规则，避免集群之间的网络通讯被屏蔽。

运行以下命令将 `10.0.0.0/24` 子网加入到 `firewalld` 的 `trusted` 区域中：

```console
# firewall-cmd --zone=trusted --add-source=10.0.0.0/24 --permanent
```

所有处于 `trusted` 区域的连接都会被无条件地接受，所以节点之间就可以进行网络通讯了。

然后，运行下面的命令重启防火墙：

```console
# systemctl restart firewalld
```

您可以用下面的命令检查设置的规则是否生效：

```console
# firewall-cmd --zone=trusted --list-all
```

{% include asciinema-player.html name="firewall.cast" poster="npt:15" %}

## 创建一个日常使用的用户帐户

到这里为止，您就已经完成了所有涉及到网络的配置任务了。这些任务都是用 `root` 帐户完成的，因为它们基本都需要超级用户权限；所以用 `root` 帐户可以省去每个命令前面都要加 `sudo` 的麻烦。但是，使用 `root` 完成日常的系统管理任务是不推荐的；最好的习惯还是用一个普通的帐户搭配 `sudo`。接下来的步骤就是创建一个平时用的帐户，这里的用户名就暂且使用 `pi`。

使用下面的命令来创建一个新用户，并设置密码：

```console
# useradd pi
# passwd pi
```

{% include asciinema-player.html name="create-user.cast" poster="npt:17" %}

在 Fedora 上，如果想允许一个用户使用 `sudo` 提权，只需把该用户添加到 `wheel` 用户组即可：

```console
# usermod -aG wheel pi
```

现在尝试使用新的 `pi` 帐户登录，然后用 `sudo` 跑一个命令，看是否配置成功。

{% include asciinema-player.html name="allow-sudo.cast" poster="npt:8"
    start_at="8" %}

## 安装 MPI

MagPi 的那篇文章使用[信息传递接口](https://zh.wikipedia.org/zh-cn/%E8%A8%8A%E6%81%AF%E5%82%B3%E9%81%9E%E4%BB%8B%E9%9D%A2)（MPI）来让多个树莓派并发执行一个任务，所以这里我也将使用同样的方案，在 Fedora 上安装 MPI。Fedora 提供两种 MPI 的实现：Open MPI 和 MPICH。它们都提供用来在多台设备上同时执行一个命令的 `mpiexec` 指令。因为我当时没有深入研究，随便选了 Open MPI，所以这里提供的也是配置 Open MPI 的步骤；但是配置 MPICH 的步骤是相同的。

首先，使用下面的命令安装 Open MPI 本身：

```console
$ sudo dnf install opemmpi
```

{% include asciinema-player.html name="install-mpi.cast" poster="npt:5.3" %}

如果您想安装 MPI 的 Python 绑定，请使用下列命令：

```console
$ sudo dnf install openmpi python3-mpi4py-openmpi
```

`mpiexec` 命令被安装在了 `/usr/lib64/openmpi/bin` 路径下而非 `/usr/bin`，而这个路径并不在 `PATH` 环境变量中，所以如果想运行此命令的话，您就得键入它的完整路径，显然是相当麻烦的。解决这个问题的方法也很简单：把 `/usr/lib64/openmpi/bin` 添加到 `PATH` 下就可以了。编辑 `~/.bashrc` 文件，添加下面一行：

```sh
PATH="/usr/lib64/openmpi/bin:$PATH"
```

完成编辑后，运行下列命令应用设置：

```console
$ source ~/.bashrc
```

现在，您就应该可以直接运行 `mpiexec` 命令，不需要输入完整路径了。

{% include asciinema-player.html name="set-mpi-path.cast" poster="npt:10.5" %}

如果您想装 MPICH，那么直接把上述步骤中所有出现 `openmpi` 的地方都替换为 `mpich` 即可，就这么简单！

```console
$ sudo dnf install mpich
```
```console
$ sudo dnf install mpich python3-mpi4py-mpich
```
```sh
PATH="/usr/lib64/mpich/bin:$PATH"
```

不过，我后来简单尝试了一下 MPICH，发现它的 `mpiexec` 程序的错误提示不如 Open MPI 友好，故选择了继续使用后者。

## 去除 `sudo` 的密码提示

`sudo` 命令在被运行时会询问密码，然后通过控制台标准输入读取您输入的密码。但是 `mpiexec` 不会把终端提供给程序作为标准输入，所以如果用 `mpiexec` 执行 `sudo` 命令的话，会遇到无法输入密码的情况。

这种情况下，只能曲线救国，让 `sudo` 不需要密码也可以执行命令。要做到这点，就得运行下面的命令来修改 `sudo` 的配置文件：

```console
$ sudo visudo
```

然后，在配置文件中进行如下改动：

```diff
 ## Allows people in group wheel to run all commands
-%wheel        ALL=(ALL)        ALL
+# %wheel        ALL=(ALL)        ALL

 ## Same thing without a password
-# %wheel        ALL=(ALL)        NOPASSWD: ALL
+%wheel        ALL=(ALL)        NOPASSWD: ALL
```

{% include asciinema-player.html name="rm-sudo-passwd.cast" poster="npt:13" %}

在 Fedora 的默认配置下，`visudo` 使用的文本编辑器是 `vi`。如果您对 `vi` 不熟悉的话，可以参考下面的步骤来完成上述修改：

1.	输入 `/wheel` 然后按下回车键。这个操作的目的是在配置文件里搜索 `wheel`，效果是直接跳到配置文件里要修改的地方。

2.	按一下 `j` 将光标向下移动一行，然后按 `Shift-I` 移动到行首并开始编辑。此时，终端下方会出现 **`-- INSERT --`** 指示符。

3.	输入井号 `#`，将当前这一行变为注释。然后按 `Esc` 键，**`-- INSERT --`** 指示符会随之消失。

4.	按三下 `j` 将光标向下移动三行，然后按 `0` 将光标移到行首，再按两下 `x` 删除两个字符。这样一来，这行里的 `#` 会被删除，也就不再是注释了。

5.	输入 `:wq` 然后按下回车键，保存并退出编辑器。

## 在剩下的节点上重复上述步骤

第一个节点的准备工作到这里就结束了。然而，这些步骤需要在集群里所有的节点上都重复一遍。下面是对准备工作所有步骤的一个概括：

1.	将 Fedora 的映像写入到 SD 卡上
2.	启动树莓派并查询其 IP 地址
3.	将树莓派连接到 Wi-Fi
4.	配置静态 IP 地址
5.	配置树莓派上的防火墙
6.	创建一个用户并将其加入到 `wheel` 用户组
7.	安装 MPI 并设置 `PATH` 环境变量
8.	移除 `sudo` 的密码提示

在重复上述步骤时，请特别留意以下几个会有变化的地方：

- 每个树莓派获得的 IP 地址可能不一样
- 在不同的节点上，应该使用不同的主机名
- 不同节点的静态 IP 地址应当不同

当您在所有节点上都完成了上述步骤后，可以试试从每个树莓派 `ping` 其它的树莓派。如果能 `ping` 通，说明配置正确，节点之间可以互相通讯，就可以进行最后一步了。

{% include asciinema-player.html name="ping.cast" poster="npt:6" %}

## 创建并复制 SSH 密钥

`mpiexec` 命令依赖 SSH 来在多个节点上并发运行同一个任务。当您使用 `ssh` 命令连接到一台服务器上时，如果服务器允许使用密码登录，您就可以通过输入密码来进行验证。然而，`mpiexec` 是不使用密码进行验证的。假设要在有几十个甚至成千上百个节点的集群上用 `mpiexec` 运行一个命令，那光是输入密码就得输入半天；即使是只有四个树莓派的集群，也得输入三次密码（运行 `mpiexec` 命令的节点不需要密码）。取代密码验证的就是 SSH 密钥验证了。

首先，选择一个节点来作为整个集群的主节点，也就是用来运行 `mpiexec` 命令的节点；剩下的节点自然就成为了从属节点。MagPi 文章推荐使用第一个节点，也就是 IP 地址是 `10.0.0.1` 的节点来作为主节点。

接下来，通过 SSH 从主节点连接到每个从属节点，然后运行下列命令：

```console
$ ssh-keygen
$ ssh-copy-id 10.0.0.1
```

在运行 `ssh-keygen` 时，一路按回车键使用默认选项即可。特别需要注意的一点：不要给 SSH 密钥设置密码。

{% include asciinema-player.html name="ssh-key-w2m.cast" poster="npt:16" %}

在每个从属节点上都运行完上述命令后，回到主节点上，以同样的方式运行一次 `ssh-keygen` ，然后运行 `ssh-copy-id` 若干次，将主节点的 SSH 密钥复制到每个从属节点上。下面是我使用的命令；如果您给树莓派分配了不同的静态 IP 地址，或者节点数量不同，那么请相应地对运行的命令进行调整。

```console
$ ssh-keygen
$ ssh-copy-id 10.0.0.2
$ ssh-copy-id 10.0.0.3
$ ssh-copy-id 10.0.0.4
```

{% include asciinema-player.html name="ssh-key-m2w.cast" poster="npt:15" %}

## 大功告成

到这里，SSH 密钥配置好了，就可以开始用 `mpiexec` 并发执行命令了。您可以运行下面的命令进行简单的测试：

```console
$ mpiexec -n 4 --host 10.0.0.1,10.0.0.2,10.0.0.3,10.0.0.4 hostname
```

在此命令中，`-n` 选项指定集群里的节点数量，`--host` 选项指定节点的 IP 地址。如果您的节点数量或静态 IP 地址配置不同，请对命令作出相应的修改。

正常情况下，这条命令应当输出您给所有树莓派设置的主机名。主机名的顺序可能会是乱序并且会发生变化；这是正常现象。只要所有主机名都出现了，就说明您的配置没有问题。

{% include asciinema-player.html name="run-mpiexec.cast" poster="npt:21" %}
