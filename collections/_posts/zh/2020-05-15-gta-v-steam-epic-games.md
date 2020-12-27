---
title: "让 Steam 和 Epic Games 共用同一份 GTA V 游戏文件"
lang: zh
tags:
  - GTA Online
categories:
  - 教程
excerpt_separator: "<!--more-->"
toc: true
last_modified_at: 2020-12-27
---
{% include img-path.liquid %}
继 Epic Games 宣布 GTA V 将在他们的平台上限免一周后，大量玩家蜂拥而至，其中甚至不乏一些已经在 Steam 上买了 GTA V，想再弄一个甚至好几个小号的人。

然而，很多人在 Steam 和 Epic Games 上同时拥有 GTA V 之后却发现即使已经从 Steam 上下过了游戏，也要从 Epic Games 上重新下载一遍。其实，只要利用一些小技巧，就可以让 Steam 和 Epic Games 共用同一份 GTA V 游戏文件，既省去了重新下载的麻烦，又能节省磁盘空间。我们可以利用 Windows 上一个不知名的 `MKLINK` 命令来建立一个链接：链接给人的感觉类似于快捷方式，能够让被连的文件看起来是放在了链接所在的位置，但其实是被存在了另一个位置。而链接本身占用的空间也是非常小的，所以可以节省大量的磁盘空间。
<!--more-->

我相信这次几乎所有玩家都是想把已经在 Steam 上下的文件给 Epic Games 用，而不是反过来，所以下面的步骤是在 Epic Games 游戏安装路径下创建一个连到 Steam 下载的游戏文件的链接的步骤。

## 步骤

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

9.  在命令提示符里运行命令 `mklink /D "<Epic Games 路径>" "<Steam 路径>"`，在 Epic Games 游戏安装路径下创建一个连到 Steam 游戏文件的链接。分别将第 1 步和第 6 步里的路径代入该命令中。记得用英文的双引号把路径括起来，不要用中文的双引号。

    ![]({{ img_path }}/09-1-mklink.png)

    命令跑完后，您就能看到 `GTAV` 链接在 Epic Games 游戏安装路径下被创建了。

    ![]({{ img_path }}/09-2-link-created.png)

10. 把第 4 步中被挪动的 `.egstore` 文件夹挪回 `GTAV` 中。

    ![]({{ img_path }}/10-restore-egstore.png)

11. 现在启动 Epic Games 启动器。如果游戏下载仍然处于暂停状态的话，手动恢复下载。然后，您应该就能发现已经开始验证游戏文件了，说明操作成功！等待它完成即可。

    ![]({{ img_path }}/11-epic-games-verifies.png)

12. 当 Epic Games 启动器显示可以启动 GTA V 时，前往 GTA V 游戏文件所在路径，再次将 `GTA5.exe` 和 `PlayGTAV.exe` 复制出来，并记下它们是来自于 Epic Games 下载的文件。

    ![]({{ img_path }}/12-two-copies-of-executables.png)

以后，如果您想从 Steam 启动 GTA V，那么就将第 7 步中从 Steam 的文件复制出来的两个 EXE 文件复制回 GTA V 游戏文件所在路径当中；如果想从 Epic Games 启动，那就复制第 12 步得到的文件。在 GTA V 的关键游戏文件中，只有 `GTA5.exe` 和 `PlayGTAV.exe` 这两个文件从 Steam 下载和从 Epic Games 下载会出现不同，别的文件全部都是一样的。

## 提前退出您原有的 Social Club 帐号！

贴吧里已经有人反映称，在电脑上已经装了从 Steam 下载的 GTA V 之后，再从 Epic Games 启动 GTA V 时会将免费领的游戏绑定到原来的 Social Club 帐号下，导致小号未能创建。如果您想弄一个新的线上小号的话，请一定记得先在 R 星启动器里退出您原来的 Social Club 帐号。

## 游戏有更新时需执行的步骤

如果您在使用上述步骤成功让两个平台共用游戏文件之后，GTA V 有更新，那么请执行下面的步骤：

1.	在游戏平台 A（可以是 Steam，也可以是 Epic Games）上更新 GTA V。

2.	将 GTA V 安装路径中的 `GTA5.exe` 和 `PlayGTAV.exe` 复制到别处，并记下它们是游戏平台 A 下载的文件。

3.	在游戏平台 B（另一个游戏平台）上更新 GTA V。

4.	再次将 GTA V 安装路径中的 `GTA5.exe` 和 `PlayGTAV.exe` 复制到别处，并记下它们是游戏平台 B 下载的文件。

之后，您就可以像以前一样正常启动游戏、以及在两个平台之间来回切换。
