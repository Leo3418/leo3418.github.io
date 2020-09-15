---
title: "在 Windows Terminal 中使用 Cygwin 命令行或 Git Bash"
lang: zh
tags:
  - Windows
toc: true
---
{% include img-path.liquid %}

近日，微软发布了 Windows Terminal 的首个正式版本。Windows Terminal 是 Windows 10 上全新的终端程序。和命令提示符还有 Windows Subsystem for Linux (WSL) 默认使用的系统自带老式控制台 `conhost.exe` 相比，它允许使用多种不同的壳层（shell），例如 Windows PowerShell、命令提示符、以及 WSL。除此之外，Windows Terminal 提供的功能和自定义选项也是比原有的控制台多许多。

得益于可自行添加 shell 的功能，我们可以将 [Cygwin](https://www.cygwin.com/) 的 shell 和 [Git for Windows](https://gitforwindows.org/) 中的 Git Bash 也加到 Windows Terminal 里，就可以在没有 WSL 的情况下在 Windows Terminal 里使用 Unix shell 和其它的一些 Unix 程序了。这篇文章将介绍相应的方法。

此文章的目的并不是推荐各位使用 Cygwin 或者 Git Bash 替代 WSL，主要是为了方便已经安装了 Cygwin 或者 Git Bash 的人。当然了，如果愿意的话，即使您之前没用过这些软件，也可以装一下，体验下它们。

添加 Cygwin 和 Git Bash 的操作步骤大同小异，所以我会先写怎么把 Cygwin 的 shell 加到 Windows Terminal 里，然后再说弄 Git Bash 的时候哪些步骤是不同的。

## 添加 Cygwin 的 Shell 的步骤

下述的步骤假设您在 Cygwin 中安装了 Bash。其它的 shell 应该也可以用，不过如果要用别的 shell，那么配置文件也会和示范中的不同，请多加留意。

1. 从[应用商店](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701)下载 Windows Terminal。

   ![应用商店中的 Windows Terminal]({{ img_path_l10n }}/store-page.png)

2. 打开 Windows Terminal。在窗口上方，您可以看到一个打开下拉菜单的按钮，里面有各种 shell 的配置。接下来我们也准备给 Cygwin 的 shell 创建一个新配置。

   ![Windows Terminal 的下拉菜单]({{ img_path_l10n }}/wt-profiles.png)

3. 在菜单中选择“设置”，会弹出 Windows Terminal 的配置文件。往下翻一点，您会看见一个 `profiles` 选项，里面有个 `list`，就是我们要加新配置的地方。

   ![Windows Terminal 配置文件]({{ img_path }}/wt-config.png)

   一个基本的配置应该具有以下属性：

   - `guid`：该配置的独立 ID

   - `name`：配置名称

   - `commandline`：运行此配置对应的 shell 的命令行

4. `guid` 中的 ID 可以随便弄一个 128 位的 UUID，前提是不和配置文件中已有的 UUID 重复。不过需要特别注意的是，**即使您要删除配置文件中自带的配置，也不能用它们的 ID**。 比如说，您根本用不着 Azure Cloud Shell，所以把它的配置删了，但即使是删除过后，也不能把它配置中的 `guid` 给别的配置用。

   其实这不应该是什么问题，因为生成 UUID 的方法有很多：
   - 在 Cygwin 的 shell 里运行一下 `uuidgen` 命令
   - 用一个网上找的 UUID 生成器
   - 直接用我的示范里生成的 UUID：`a1f2ceb2-795d-4f2a-81cc-723cceec49c0`

   ![在 Cygwin 的 shell 里运行 “uuidgen” 命令]({{ img_path }}/uuidgen.png)

5. 找出启动 Cygwin 的 shell 的命令行指令。

   首先确定 Cygwin 的安装路径。如果您装的是 64 位版本，那么默认的安装路径是 `C:\cygwin64`。Bash 的可执行文件 `bash.exe` 存在 Cygwin 安装路径下的 `bin` 文件夹中，因此在默认的情况下，该文件的绝对路径是 `C:\cygwin64\bin\bash.exe`。

   此处需要注意的一点是，Cygwin 中的 Bash 需要以交互式登录 shell（interactive login shell）的形式启动，否则的话，在运行一些包括 `ls` 在内的基本指令的时候会出 "command not found" 的消息。这个的原因是只有登录 shell 会在启动的时候运行 `/etc/profile`，然后 Cygwin 中的 `/etc/profile` 会把 `/usr/bin` 和 `/usr/local/bin` 加到 `PATH` 环境变量当中。如果开启的不是登录 shell，那么 `/etc/profile` 不会被运行，环境变量也就不会被设置。启动交互式登录 shell 的方法是使用 `-i -l` 选项。如果您想使用别的 shell，那么请自行确认下让 `/usr/bin` 和 `/usr/local/bin` 被添加到 `PATH` 下的方法。

   因此，启动 Cygwin 的 Bash 的完整命令是 `C:\cygwin64\bin\bash.exe -i -l`；如果您把 Cygwin 装在了别的地方，或者想用别的 shell，请对命令进行相应的修改。

   Windows Terminal 的配置文件里支持使用正斜杠 `/` 用作路径分割符，所以在填写路径的时候，可将反斜杠 `\` 替换为 `/`。比如说，上面的命令就会变成 `C:/cygwin64/bin/bash.exe -i -l`。如果要用反斜杠作为分割符的话，就需要在反斜杠前再加一个反斜杠，也就是像 `C:\\cygwin64\\bin\\bash.exe -i -l` 这样。

6. 到这里，我们就可以把新配置的信息加到配置文件里了：

   ```json
            {
                "guid": "{a1f2ceb2-795d-4f2a-81cc-723cceec49c0}",
                "name": "Bash",
                "commandline": "C:/cygwin64/bin/bash.exe -i -l"
            },
   ```

   配置文件中各个配置的出现顺序和它们在 Windows Terminal 里出现的顺序是一致的。所以，如果我想把 Bash 放在最上面，那我在配置文件中也是把它放在第一个。

   如果不是把配置加到列表最后的话，别忘了在右花括号后面加个逗号，如上面示例所示；如果是加在最后的话，就不用给新加的配置加逗号了，但仍然别忘了给原先就在最后的配置后面补一个逗号。

   ![添加新的配置]({{ img_path }}/config-new-profile.png)

7. 保存配置文件。如果文件中没有语法错误的话，您现在应该就可以在菜单中看到刚添加的配置了。点一下该配置，Bash 就会在一个新的标签里启动了。

   ![新添加的配置]({{ img_path_l10n }}/wt-new-profile.png)

   ![在 Windows Terminal 中运行 Bash]({{ img_path }}/cygwin-bash-added.png)

## 添加 Git Bash 的步骤

Git Bash 的步骤和 Cygwin 的步骤只有两处不同：

- Git Bash 里没有 `uuidgen` 命令。但是因为还有其它获取 UUID 的方法，所以这不是什么大问题。

- Shell 的路径和 Cygwin 不一样了：如果 Git for Windows 安装在 `C:\Program Files\Git`，那么 Git Bash 可执行文件的绝对路径就是 `C:\Program Files\Git\bin\bash.exe`。

  ![Git Bash 的命令行路径]({{ img_path }}/git-bash-cmd.png)

## 避免 "Process Exited With Code x" 提示信息

![非零退出状态导致的提示信息]({{ img_path }}/non-zero-exit-status.png)

在使用 `exit` 命令或 Ctrl-D 退出 shell 的时候，如果最后执行的命令的退出状态（exit status）不是 0 的话，可能会出现上图所示的提示信息。有的时候即使一个命令都没跑就直接退出 shell，也可能出现这种提示；这种情况则是因为诸如 `.bashrc` 的初始化脚本内有命令的退出状态非零。

如果出现了这类错误提示，就必须得手动关闭 Windows Terminal 窗口。不过，有一种解决办法可以避免这类消息出现：在配置中添加 `"closeOnExit": "always"` 选项，即可阻止 Windows Terminal 显示该信息。需要注意的一点是，如果该选项是此配置的最后一行，那么您需要确保此选项的上一行结尾有一个逗号。

![在配置文件中添加此选项]({{ img_path }}/fix-non-zero-exit-msg.png)

## 选择 Windows Terminal 的默认配置

Windows Terminal 的配置文件中有个 `defaultProfile` 选项可以用来选择启动时默认打开的 shell。如果想指定一个配置作为默认配置，那就把该配置的 `guid` 复制到这个选项的值中就行了。

![选择默认配置]({{ img_path }}/set-default-profile.png)
