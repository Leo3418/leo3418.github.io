---
title: "在 Hugo 模板中使用新功能并兼顾向后兼容性"
categories:
  - 博客
---

在最近发布的 Hugo v0.109.0 中，页面对象新增了一个 `.Ancestors` 变量，可以用来方便地实现[面包屑导航][wikipedia-breadcrumb-navigation]的[模板][hugo-docs-breadcrumb]。光是通过对比此次更新前后 Hugo 文档中给的面包屑模板例子，就可以看出这个变量的作用了：有了它，面包屑就不需要通过递归调用辅助模板（即下面例子中的 `breadcrumbnav`）来生成了，代码简洁明了了不少。（为便于阅读，以下代码的格式被重新整理过）

<!--more-->

```html
<!-- Hugo 0.108.0 的面包屑模板样例 -->

<ol class="nav navbar-nav">
  {{ template "breadcrumbnav" (dict "p1" . "p2" .) }}
</ol>

{{ define "breadcrumbnav" }}
  {{ if .p1.Parent }}
    {{ template "breadcrumbnav" (dict "p1" .p1.Parent "p2" .p2 )  }}
  {{ else if not .p1.IsHome }}
    {{ template "breadcrumbnav" (dict "p1" .p1.Site.Home "p2" .p2 )  }}
  {{ end }}
  <li{{ if eq .p1 .p2 }} class="active" aria-current="page" {{ end }}>
    <a href="{{ .p1.Permalink }}">{{ .p1.Title }}</a>
  </li>
{{ end }}
```

```html
<!-- Hugo 0.109.0 的面包屑模板样例 -->

<ol class="nav navbar-nav">
  {{- range .Ancestors.Reverse }}
    <li><a href="{{ .Permalink }}">{{ .Title }}</a></li>
  {{- end }}
  <li class="active" aria-current="page">
    <a href="{{ .Permalink }}">{{ .Title }}</a>
  </li>
</ol>
```

使用 `.Ancestors` 除了能让面包屑模板更简洁，还能让模板的速度更快。我对这两个版本的样例模板进行了性能测试，分别使用它们为本网站上的全部 174 个页面（统计于本文被编写时）生成面包屑，结果是使用 `.Ancestors` 的模板的速度是不使用它的模板的大约两倍。（关于性能测试的更多详情，请参见[附录][appendix-benchmark]。）

{{< date.inline >}}{{ "2023-01-10" | time.Format ":date_long" }}{{< /date.inline >}}更新：我使用 Hugo 的 `--ignoreCache` 和 `--renderToMemory` 选项重新运行了一遍性能测试，并相应地更新了测试结果。这两个选项分别会让 Hugo 不使用缓存以及将网站渲染到内存；和我在第一次测试时将生成的文件写到 tmpfs 相比，这两个选项理论上能更好地避免文件系统读写造成的性能波动。
{.notice}

| 面包屑模板           |  平均总运行耗时 |
| :----------------- | ------------: |
| 不使用 `.Ancestors` | 22.4727531 ms |
| 使用 `.Ancestors`   | 10.9241115 ms |

因为我一直以来都在自行编写和维护本网站使用的 Hugo 模板，所以一看到使用 `.Ancestors` 的样例模板，就开始想着把[我自己的面包屑模板][my-tmpl-breadcrumb-old]也改成差不多的。以前的模板在以后的 Hugo 版本中肯定是还能继续用的，所以我也不是说*必须*改模板；甚至，根据“代码能跑就不要再乱动”的原则，我是*不应该*改它的。但是一想到用了 `.Ancestors` 的让代码既能更美观、也能更快的好处，我直接大手一挥，管它有什么原则，干就完了。

然而，有一个我无法忽略的事实摆在面前：在我干活用的本地机器上的 Gentoo 系统中，Hugo 的版本还是 0.108.0，还没有更新到 0.109.0，也就是说如果我开始在模板里用 `.Ancestors`，那么在本地构建网站的时候，就会出现错误。虽然我可以下载 0.109.0 在本地运行，但我还是想等 Gentoo 上的 Hugo 软件包更新到 0.109.0 再升级，因为我一直都是尽量用系统的软件包管理器安装软件。等到 Gentoo 更新 Hugo 软件包再改模板也是可行的，但我还是想把握住全神贯注想着这件事时的状态，马上动工。

当时，我能想到的最好的方案就是先下载 Hugo 官方编译的 0.109.0 可执行文件，保存到 `/tmp` 下，就可以先暂时用它更新下模板，然后把新模板先存在别处；等 Gentoo 的 Hugo 软件包更新到了 0.109.0，再把新模板拷回来替换旧的。因为 `/tmp` 下的文件在重启后就会消失，所以这样一来，我也不需要担心不通过系统软件包管理器安装软件造成的程序文件残留的问题。

新模板写好后，我就开始想该把它存在哪里。本地文件？同步到云端的笔记？还是先放在面包屑模板文件里注释起来，等我更新 Hugo 0.109.0 了再取消注释？最后一个想法给了我启发，让我想到一种可以把新代码直接存在模板文件里、不需要注释起来、甚至还不会影响模板对 0.108.0 兼容性的办法。这个办法就是，利用条件语句，在不同 Hugo 版本上运行不同的代码。其逻辑是这样的：

```
if Hugo 版本不低于 0.109.0:
    运行使用 '.Ancestors' 的代码
else:
    运行不使用 '.Ancestors' 的代码
```

之所以能这样写，是因为在 Hugo 模板中，执行到条件语句时，条件未满足的分支的代码完全不会被调用，故代码即使用到了不存在的变量，因为没有被执行，所以该变量就不会被访问，也就不会出现错误。

{{<div class="notice--success">}}
这个想法和 C 语言等语言的条件编译以及一些动态语言和脚本语言的行为有着相似的理念，就好比下面几个例子中的代码全都可以编译并/或执行：

```c
int main() {
#if 0
    nonexistent_function(); // 不存在的！
#endif
    return 0;
}
```

```bash
#!/usr/bin/env bash

if false; then
    nonexistent_command # 不存在的！
fi
exit 0
```

```python
#!/usr/bin/env python

import sys

if False:
    nonexistent_function()  # 不存在的！
sys.exit(0)
```
{{</div>}}

到了这一步，唯一还需要解决的问题就是怎么在模板中检查 Hugo 的版本。[`hugo` 函数][hugo-docs-hugo]此时就可以派上用场：模板调用这个函数就可以获取关于当前正在运行的 Hugo 实例的各种信息，其中就包括通过 `hugo.Version` 可以获取的版本号字符串。接着需要做的就是将该字符串和 `0.109.0` 进行版本号对比，因为 0.109.0 是第一个支持 `.Ancestors` 变量的版本。Hugo 里似乎是没有版本比较的函数的；一般的比较函数在比较版本号时，对于一些特殊情况会返回错误的结果，比如 `ge "0.99.0" "0.109.0"` 会返回 `true`。我最后采取的方法是从字符串中提取版本号的第二个部分，将其转换成整数值，然后看其数值是否大于等于 109。只要 Hugo 短期内不发布 1.0 版本，这样就是可行的；不然的话，版本号第二部分变成 0，就比 109 小了。

```html
<!-- 既可以利用 Hugo 0.109.0 新增的 '.Ancestors' 变量，也对
     不支持 '.Ancestors' 的 Hugo 旧版本向后兼容的面包屑模板 -->

{{ if ge (index (split hugo.Version ".") 1 | int) 109 }}
    <ol class="nav navbar-nav">
      {{- range .Ancestors.Reverse }}
        <li><a href="{{ .Permalink }}">{{ .Title }}</a></li>
      {{- end }}
      <li class="active" aria-current="page">
        <a href="{{ .Permalink }}">{{ .Title }}</a>
      </li>
    </ol>
{{ else }}
    <ol class="nav navbar-nav">
      {{ template "breadcrumbnav" (dict "p1" . "p2" .) }}
    </ol>
{{ end }}

{{ define "breadcrumbnav" }}
  {{ if .p1.Parent }}
    {{ template "breadcrumbnav" (dict "p1" .p1.Parent "p2" .p2 )  }}
  {{ else if not .p1.IsHome }}
    {{ template "breadcrumbnav" (dict "p1" .p1.Site.Home "p2" .p2 )  }}
  {{ end }}
  <li{{ if eq .p1 .p2 }} class="active" aria-current="page" {{ end }}>
    <a href="{{ .p1.Permalink }}">{{ .p1.Title }}</a>
  </li>
{{ end }}
```

因为在代码块中不能使用 `define`，所以 `{{ define "breadcrumbnav" }}` 代码块必须被移出来到最外层。
{.notice--warning}

我自己的面包屑模板更新之后的版本可[由此][my-tmpl-breadcrumb-new]访问。

因为我的模板只用在我的个人网站上，网站也没有其他协作人员或者贡献者，所以我完全可以选择把我所有需要用到 Hugo 的地方（包括我干活用的本地机器，以及用来自动构建和部署本网站的 [GitHub Actions 流程][my-gh-actions-workflow]）都更新到 0.109.0，就不用像这样折腾了。但是，如果换作是模板被用在多人协作的 Hugo 网站项目上或者公开发布的 Hugo 主题里，那这样的操作还是值得的。当好几个人同时维护一个 Hugo 网站时，要求所有人都立刻升级到最新的 Hugo 版本可能是不现实的。对于可能有数百个网站在使用的 Hugo 主题来说，就更不用提了：如果不兼容旧版本，就意味着成百甚至上千的用户将要面临要么第一时间升级到最新 Hugo 版本，要么只能使用主题的旧版本的窘境。在这些场景下，模板支持尽可能多的 Hugo 版本的价值就体现出来了。使用较新 Hugo 版本的用户可以享受 Hugo 新功能带来的模板性能提升，而与此同时，使用较旧 Hugo 版本的用户也不用担心主题在旧 Hugo 版本上不受支持或功能不全。

[hugo-v0.109.0]: https://github.com/gohugoio/hugo/releases/tag/v0.109.0
[wikipedia-breadcrumb-navigation]: https://zh.wikipedia.org/wiki/%E9%9D%A2%E5%8C%85%E5%B1%91%E5%AF%BC%E8%88%AA
[hugo-docs-breadcrumb]: https://gohugo.io/content-management/sections/#example-breadcrumb-navigation
[appendix-benchmark]: {{<relref "#附录面包屑模板性能测试数据">}}
[my-tmpl-breadcrumb-old]: https://github.com/Leo3418/leo3418.github.io/blob/a4696da675372f5d9aa970347628feae4e7b7570/layouts/partials/breadcrumbs.html
[hugo-docs-hugo]: https://gohugo.io/functions/hugo/
[my-tmpl-breadcrumb-new]: https://github.com/Leo3418/leo3418.github.io/blob/f6b6dd0648b55096695ef1f1b7b4d89ce00e9692/layouts/partials/breadcrumbs.html
[my-gh-actions-workflow]: https://github.com/Leo3418/leo3418.github.io/blob/f6b6dd0648b55096695ef1f1b7b4d89ce00e9692/.github/workflows/hugo.yaml

## 附录：面包屑模板性能测试数据

性能测试是通过运行 Hugo 时启用 `--templateMetrics` 选项进行的。该选项会让 Hugo 报告网站使用的每一个模板的总运行耗时（也被称为 cumulative duration，意为累计时长）。欲了解更多有关该选项输出数据的信息，请参阅 [Hugo 文档][hugo-docs-template-metrics]。我在测试每一个脚本的时候，都运行的同一个 Hugo 0.109.0 可执行文件，构建本网站十次，然后收集累计时长数据：

```console
$ /tmp/hugo version
hugo v0.109.0-47b12b83e636224e5e601813ff3e6790c191e371+extended linux/amd64 BuildDate=2022-12-23T10:38:11Z VendorInfo=gohugoio
$ /tmp/hugo --templateMetrics | head -n 8 | tail -n 4

     cumulative       average       maximum
       duration      duration      duration  count  template
     ----------      --------      --------  -----  --------
$ # 测试不使用 '.Ancestors' 的面包屑模板
$ for i in {1..10}; do
> rm -r /tmp/hugo_cache
> /tmp/hugo --destination /tmp/public --templateMetrics | grep -F 'partials/breadcrumbs.html'
> done
    20.843343ms     119.789µs    2.037636ms    174  partials/breadcrumbs.html
     17.97466ms     103.302µs     731.496µs    174  partials/breadcrumbs.html
    20.916035ms     120.207µs    1.324354ms    174  partials/breadcrumbs.html
    21.813846ms     125.366µs    2.276513ms    174  partials/breadcrumbs.html
    28.113151ms     161.569µs    4.627905ms    174  partials/breadcrumbs.html
    17.310946ms      99.488µs    1.667575ms    174  partials/breadcrumbs.html
     23.29696ms      133.89µs    3.878245ms    174  partials/breadcrumbs.html
    20.942715ms      120.36µs    1.319785ms    174  partials/breadcrumbs.html
    27.327393ms     157.053µs    5.052419ms    174  partials/breadcrumbs.html
    26.188482ms     150.508µs     8.38873ms    174  partials/breadcrumbs.html
$ # 测试使用 '.Ancestors' 的面包屑模板
$ for i in {1..10}; do
> rm -r /tmp/hugo_cache
> /tmp/hugo --destination /tmp/public --templateMetrics | grep -F 'partials/breadcrumbs.html'
> done
    13.876398ms      79.749µs    3.214174ms    174  partials/breadcrumbs.html
     9.453452ms       54.33µs     625.308µs    174  partials/breadcrumbs.html
    10.339717ms      59.423µs    1.403833ms    174  partials/breadcrumbs.html
    10.727788ms      61.653µs     796.077µs    174  partials/breadcrumbs.html
     9.777874ms      56.194µs    1.072293ms    174  partials/breadcrumbs.html
     9.753709ms      56.055µs      771.05µs    174  partials/breadcrumbs.html
    10.858828ms      62.407µs    1.250856ms    174  partials/breadcrumbs.html
    12.769683ms      73.388µs    1.658969ms    174  partials/breadcrumbs.html
    10.897951ms      62.631µs     805.244µs    174  partials/breadcrumbs.html
    10.785715ms      61.986µs     772.212µs    174  partials/breadcrumbs.html
```

{{<asciicast
    poster="data:text/plain,性能测试期间的终端输出录像">}}
    {{<static-path res breadcrumb-benchmark.cast>}}
{{</asciicast>}}

下图是将每个模板的累计时长（*t*）使用正态分布逼近产生的结果。由此图可以得出的一个结论是，使用 `.Ancestors` 的面包屑模板（以橙线表示）几乎是一直比不使用 `.Ancestors` 的模板（以蓝线表示）要快。[由此][benchmark-plot-program]可获取绘制此图的程序。

![使用正态分布逼近模板累计时长得出的模型]({{<static-path img exec-time-dist.png>}})

[hugo-docs-template-metrics]: https://gohugo.io/troubleshooting/build-performance/#template-metrics
[benchmark-plot-program]: {{<static-path res plot_exec_time_dist.py>}}
