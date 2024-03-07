---
title: "新建一篇测试帖"
weight: 40
---

我们可以通过创建一个有多种语言翻译的测试帖来检查 Polyglot 的配置是否正确。在 `_posts` 文件夹中，为您的网站支持的每种语言创建一个文件夹。文件夹的名称应与 `_config.yml` 文件中该语言的 ISO 639-1 代码一致。

```console
site-root$ cd _posts
site-root/_posts$ mkdir en zh
site-root/_posts$ ls
en  zh
```

接着，在每个文件夹下创建一个文件名格式为 `YEAR-MONTH-DAY-title.MARKUP` 的文件，详情可参阅 [Jekyll 官方文档的描述](https://jekyllrb.com/docs/posts/#creating-posts)。然后在每个文件头部的信息块中加入一个 `lang` 变量，它的值就是当前文件中的帖子的语言。

```console
site-root/_posts$ ls *
en:
2020-04-26-test-post.md

zh:
2020-04-26-test-post.md
site-root/_posts$ cat en/2020-04-26-test-post.md
---
layout: default
title: "Test Post"
lang: zh
---

This is a test post.
site-root/_posts$ cat zh/2020-04-26-test-post.md
---
layout: default
title: "测试帖"
lang: zh
---

此为测试帖
```

现在回到您网站源文件的根目录，然后运行 `bundle exec jekyll build` 来构建网站。

```console
site-root/_posts$ cd ..
site-root$ bundle exec jekyll build
Configuration file: site-root/_config.yml
            Source: site-root
       Destination: site-root/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
                    done in 0.055 seconds.
 Auto-regeneration: disabled. Use --watch to enable.
```

默认情况下，网站会生成在 `_site` 文件夹下。该文件夹的结构应该是类似于以下这样的：

```
_site
├── 2020
│   └── 04
│       └── 26
│           └── test-post.html
├── assets
│   └── css
│       └── main.css
├── index.html
└── zh
    ├── 2020
    │   └── 04
    │       └── 26
    │           └── test-post.html
    └── index.html
```

看一下生成的 HTML 文件的内容，可以看到 Polyglot 起了作用，为同一篇帖子的不同语言版本生成了不同的页面。（实际生成的 HTML 文件会随使用的主题而变化）

```console
site-root$ cat _site/2020/04/26/test-post.html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="utf-8">
    <title>Test Post - My Site</title>
    <link rel="stylesheet" href="/assets/css/main.css">
  </head>
  <body>
    <p>This is a test post.</p>

  </body>
</html>
site-root$ cat _site/zh/2020/04/26/test-post.html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="utf-8">
    <title>测试帖 - My Site</title>
    <link rel="stylesheet" href="/assets/css/main.css">
  </head>
  <body>
    <p>此为测试帖</p>

  </body>
</html>
```

您可以用 `bundle exec jekyll serve` 命令来预览您的网站，默认情况下，运行该命令后，访问 `http://localhost:4000/` 就可以查看了。把上面两个 HTML 文件相对于 `_site` 文件夹的路径粘贴到该网址后面，可以在浏览器里查看对应的网页。例如，在上面的例子中，我会访问 `http://localhost:4000/2020/04/26/test-post.html` 和 `http://localhost:4000/zh/2020/04/26/test-post.html`。

这些生成的 HTML 文件里还有些不完美的地方，比如说网站的标题没有被翻译。接下来我们就开始着手解决这些问题。
