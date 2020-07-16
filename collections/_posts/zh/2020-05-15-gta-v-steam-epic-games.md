---
title: "让 Steam 和 Epic Games 共用同一份 GTA V 游戏文件"
lang: zh
---
{% include img-path.liquid %}

继 Epic Games 宣布 GTA V 将在他们的平台上限免一周后，大量玩家蜂拥而至，其中甚至不乏一些已经在 Steam 上买了 GTA V，想再弄一个甚至好几个小号的人。

然而，很多人在 Steam 和 Epic Games 上同时拥有 GTA V 之后却发现即使已经从 Steam 上下过了游戏，也要从 Epic Games 上重新下载一遍。其实，只要利用一些小技巧，就可以让 Steam 和 Epic Games 共用同一份 GTA V 游戏文件，既省去了重新下载的麻烦，又能节省磁盘空间。我们可以利用 Windows 上一个不知名的 `MKLINK` 命令来建立一个链接：链接给人的感觉类似于快捷方式，能够让被连的文件看起来是放在了链接所在的位置，但其实是被存在了另一个位置。而链接本身占用的空间也是非常小的，所以可以节省大量的磁盘空间。

我相信这次几乎所有玩家都是想把已经在 Steam 上下的文件给 Epic Games 用，而不是反过来，所以下面的步骤是在 Epic Games 游戏安装路径下创建一个连到 Steam 下载的游戏文件的链接的步骤。

1.  在 Epic Games 里下载 GTA V。

    ![]({{ img_path }}/01-1-download-gta-v-in-epic-games.png)

    此时会出现一个让您选择下载路径的提示，随便选一个您想用的路径即可，但要记下这个路径，稍后会用到。

    ![]({{ img_path }}/01-2-choose-path.png)

2.  然后，在开始下载之后立刻暂停下载。

    ![]({{ img_path }}/02-pause-download.png)

3.  退出 Epic Games 启动器。可以忽视退出就取消游戏安装的警告。

    ![]({{ img_path }}/03-quit-epic-games.png)

4.  打开第 1 步里您选择的游戏下载路径，然后拷出其中的 `.egstore` 文件夹。这里我将其拷到了 `GTAV` 文件夹的上层。

    ![]({{ img_path }}/04-move-egstore.png)

5.  删除 `GTAV` 文件夹。

    ![]({{ img_path }}/05-delete-epic-games-gtav-folder.png)

6.  找出 Steam 里的 GTA V 安装路径。在 Steam 里查看 GTA V 的游戏属性，在“本地文件”中选择“浏览本地文件”，然后记下弹出的文件资源管理器里显示的路径。点一下地址栏，就可以将完整路径复制出来。

    ![]({{ img_path }}/06-1-steam-game-properties.png)

    ![]({{ img_path }}/06-2-steam-gta-v-files.png)

7.  把从 Steam 安装的 GTA V 中的 `GTA5.exe` 和 `PlayGTAV.exe` 复制到别处，并记下它们是从 Steam 的文件复制出来的，比如说把它们都复制到一个叫 `Steam` 的文件夹中。

    ![]({{ img_path }}/07-copy-executables.png)

8.  以管理员身份运行命令提示符。

    ![]({{ img_path }}/08-start-cmd.png)

9.  在命令提示符里运行命令 `mklink /J "<Epic Games 路径>" "<Steam 路径>"`，在 Epic Games 游戏安装路径下创建一个连到 Steam 游戏文件的链接。分别将第 1 步和第 6 步里的路径代入该命令中。记得用英文的双引号把路径括起来，不要用中文的双引号。

    ![]({{ img_path }}/09-1-mklink.png)

    命令跑完后，您就能看到 `GTAV` 链接在 Epic Games 游戏安装路径下被创建了。

    ![]({{ img_path }}/09-2-link-created.png)

10. 把第 4 步中被挪动的 `.egstore` 文件夹挪回 `GTAV` 中。

    ![]({{ img_path }}/10-restore-egstore.png)

11. 现在启动 Epic Games 启动器，您应该能发现已经开始验证游戏文件了，说明操作成功！等待它完成即可。

    ![]({{ img_path }}/11-epic-games-verifies.png)

12. 当 Epic Games 启动器显示可以启动 GTA V 时，前往 GTA V 游戏文件所在路径，再次将 `GTA5.exe` 和 `PlayGTAV.exe` 复制出来，并记下它们是来自于 Epic Games 下载的文件。

    ![]({{ img_path }}/12-two-copies-of-executables.png)

以后，如果您想从 Steam 启动 GTA V，那么就将第 7 步中从 Steam 的文件复制出来的两个 EXE 文件复制回 GTA V 游戏文件所在路径当中；如果想从 Epic Games 启动，那就复制第 12 步得到的文件。在 GTA V 的关键游戏文件中，只有 `GTA5.exe` 和 `PlayGTAV.exe` 这两个文件从 Steam 下载和从 Epic Games 下载会出现不同，别的文件全部都是一样的。

## 提前退出您原有的 Social Club 帐号！

贴吧里已经有人反映称，在电脑上已经装了从 Steam 下载的 GTA V 之后，再从 Epic Games 启动 GTA V 时会将免费领的游戏绑定到原来的 Social Club 帐号下，导致小号未能创建。如果您想弄一个新的线上小号的话，请一定记得先在 R 星启动器里退出您原来的 Social Club 帐号。

## 本周新手应做的任务

这周线上地堡打折，地堡出货双倍。地堡是我感觉赚钱最舒服的产业，这周的活动也正适合新手利用地堡迅速起家。

在 Epic Games 上免费领的 GTA V 还附带线上的犯罪集团新手包，里面有一百万 GTA 游戏币和佩利托森林走私地堡。**不要领佩利托地堡，即使它是免费的！**佩利托离洛圣都市区太远，每出一次货都是一次折磨，耗费太多时间。我建议考虑买一个更靠近市区的地堡，例如丘马什或农舍，反正这周地堡打折。买完地堡后，应尽快憋出购买设备升级和员工升级的钱，至于安全升级先不用管。然后，您只需要挂机，等地堡生产出货物后出货，就可以快速赚钱了。
