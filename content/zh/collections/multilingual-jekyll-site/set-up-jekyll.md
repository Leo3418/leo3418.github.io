---
title: "配置 Jekyll"
weight: 10
---

第一步需要做的是在您的机器上安装 Jekyll，具体的做法可以参考 Jekyll 官方文档中的[安装指南](https://jekyllrb.com/docs/installation/)。

如果是在 Fedora 上安装，有一点需要注意：按照 Jekyll 官方的指南安装的时候，可能会在运行 `gem install jekyll bundler` 命令时遇到如下报错：

```
current directory: /usr/local/share/gems/gems/http_parser.rb-0.6.0/ext/ruby_http_parser
make "DESTDIR="
gcc -I. -I/usr/include -I/usr/include/ruby/backward -I/usr/include -I.   -fPIC -O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -fPIC -I/usr/local/share/gems/gems/http_parser.rb-0.6.0/ext/ruby_http_parser -m64 -o ruby_http_parser.o -c ruby_http_parser.c
gcc: fatal error: cannot read spec file ‘/usr/lib/rpm/redhat/redhat-hardened-cc1’: No such file or directory
compilation terminated.
make: *** [Makefile:245: ruby_http_parser.o] Error 1
```

如果遇到了这种情况，只需要以 root 权限运行命令 `dnf install /usr/lib/rpm/redhat/redhat-hardened-cc1` 来安装缺失的软件包，就可以继续安装 Jekyll 了。除此以外，在安装 Jekyll 的依赖包时，可以用 `gcc gcc-c++ make` 来代替 `@development-tools`，减少需要安装的软件包的数量。

{{< asciicast poster="data:text/plain,Jekyll 在 Fedora 上的安装演示" >}}
{{< static-path res install-on-fedora.cast >}}
{{< /asciicast >}}

安装好 Jekyll 后，就可以创建一个新的 Jekyll 网站了。有两种创建选项：

1. 运行命令 `jekyll new PATH`（用您想保存网站文件的路径代替 `PATH`）。以此法创建的网站会自动应用 [Minima](https://github.com/jekyll/minima/) 主题（撰稿之时，此网站使用的就是这个主题的修改版），新建的网站相对来说显得更完善一些。

2. 运行 `jekyll new PATH --blank`，然后到 `PATH` 路径下运行 `bundle init`，再在 `Gemfile` 里写入如下内容：

   ```ruby
   gem "jekyll"
   ```

   以此法创建的是最基本的网站，更适合后续大量的自定义。

您可以选择任意一个选项，后续的指引中我们会尽量覆盖每个选项的情形。
