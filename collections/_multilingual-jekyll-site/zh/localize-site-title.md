---
title: "本地化网站标题"
ordinal: 51
level: 2
lang: zh
---
{% include img-path.liquid %}
一个普通的 Jekyll 网站的标题会在 `_config.yml` 中的 `title` 选项下定义，然后可以通过 `site.title` 变量来读取。大部分 Jekyll 主题就是以这种方法来获取网站标题。然而，对于一个多语言 Jekyll 网站来说，可能会有不同语言的标题，但是只有一个 `site.title` 变量，存不下。即使我们在 `site.title` 下给每种语言下的标题都单独定义一个键值，Polyglot 也不知道应该怎么读取它们。

![英文版网站下的标题显示正常]({{ img_path }}/before-en.png)

![中文版网站下的标题未被翻译]({{ img_path }}/before-zh.png)

我们要做的是直接在主题的文件中找到读取 `site.title` 的值的地方，然后让它们从其它变量读取本地化的网站标题。我的想法是在 Jekyll 网站的数据文件中保存本地化的标题，因为 Polyglot 连数据文件都[支持](https://github.com/untra/polyglot/blob/1.3.2/README.md#localized-sitedata)本地化。在 `_data` 文件夹下为每种语言创建一个文件夹，用于保存该语言的本地化数据。如果您的网站没有 `_data` 文件夹，那么先创建一个，然后再进行操作即可。

```console
site-root$ cd _data
site-root$/_data$ mkdir en zh
```

随后，在每个文件夹下创建一个 `l10n.yml` 文件，用于存储对应的语言的本地化数据，然后在该文件中定义网站标题的翻译：

```console
site-root/_data$ ls en zh
en:
l10n.yml

zh:
l10n.yml
site-root/_data$ cat en/l10n.yml
title: "My Site"
site-root/_data$ cat zh/l10n.yml
title: "本人的网站"
```

这些值都可以使用 `site.data.l10n.title` 变量来读取。Polyglot 的数据文件本地化功能可以让任何以 `site.data` 开头的变量的值变为本地化的值。现在唯一需要做的就是让网站的主题从 `site.data.l10n.title` 变量获取网站的标题。

如果您当时创建网站时使用的是 `jekyll new PATH` 命令，自动应用了 Minima 主题，您可能会好奇主题的文件被存在了哪里，毕竟现在网站文件夹下并没有任何看起来和主题相关的文件：

```console
site-root$ ls
404.html        _config.yml  Gemfile       index.markdown  _site
about.markdown  _data        Gemfile.lock  _posts
```

Jekyll 的文档对此作出了[解释](https://jekyllrb.com/docs/themes/#understanding-gem-based-themes)：和主题相关的文件是直接存储在您机器上专门存放已安装的 Ruby gem 的位置。不过，Jekyll 文档也有如何覆写主题文件的[步骤](https://jekyllrb.com/docs/themes/#overriding-theme-defaults)，大致就是从主题的安装路径中将要覆写的文件复制到您的网站的文件中，然后进行修改。

现在需要解决的一个问题是如何找出要覆写的文件，也就是如何找出用到 `site.title` 变量的文件。如果您的机器上有 `grep` 的话，可以在主题安装路径下，用下面的命令来找出使用了该变量的文件：

{% raw %}
```console
minima-x.y.z$ grep -nr "site\.title"
_includes/header.html:6:    <a class="site-title" rel="author" href="{{ "/" | relative_url }}">{{ site.title | escape }}</a>
_includes/footer.html:6:    <h2 class="footer-heading">{{ site.title | escape }}</h2>
_includes/footer.html:15:              {{ site.title | escape }}
README.md:81:Usually the `site.title` itself would suffice...（已删减）
```
{% endraw %}

`README.md` 是 Minima 的自述文档，可以忽略；其它的几个文件就是我们需要修改的，包括 `_includes/header.html` 和 `_includes/footer.html`。将它们复制到您的网站根目录下的 `_includes` 文件夹内，然后对它们进行编辑。`grep` 的 `-n` 选项让输出的结果显示每条结果是在文件中的第几行出现的，可以用这一信息来找出这些文件需要被修改的地方的位置。

{% raw %}
```diff
--- minima-x.y.z/_includes/header.html
+++ site-root/_includes/header.html

   <div class="wrapper">
     {%- assign default_paths = site.pages | map: "path" -%}
     {%- assign page_paths = site.header_pages | default: default_paths -%}
-    <a class="site-title" rel="author" href="{{ "/" | relative_url }}">{{ site.title | escape }}</a>
+    <a class="site-title" rel="author" href="{{ "/" | relative_url }}">{{ site.data.l10n.title | escape }}</a>

     {%- if page_paths -%}
       <nav class="site-nav">
 
--- minima-x.y.z/_includes/footer.html
+++ site-root/_includes/footer.html

   <div class="wrapper">
 
-    <h2 class="footer-heading">{{ site.title | escape }}</h2>
+    <h2 class="footer-heading">{{ site.data.l10n.title | escape }}</h2>

     <div class="footer-col-wrapper">
       <div class="footer-col footer-col-1">
         <ul class="contact-list">
           <li class="p-name">
             {%- if site.author -%}
               {{ site.author | escape }}
             {%- else -%}
-              {{ site.title | escape }}
+              {{ site.data.l10n.title | escape }}
             {%- endif -%}
             </li>
```
{% endraw %}

如果您自己写的 `_includes` 文件和布局文件中也有用到 `site.title` 变量的地方，也可以在网站根目录下运行同样的命令，查找哪些文件的哪些位置需要修改。

现在，网站的标题就应该随着语言而变化了。

![网页上展示的网站标题被翻译]({{ img_path }}/site-title-after-zh.png)

## 针对 Minima 的特别步骤：更改 HTML 中的标题元素

虽然网页上的标题改过来了，但仔细看下上面的截图左上角标签页的标题，您会发现在浏览器上显示的、由 HTML `<title>` 标签定义的网站标题还是没有本地化的。然而，刚才用 `grep` 命令查找用到 `site.title` 的地方的时候，为什么漏掉了这里呢？

造成此现象的原因是 Minima 根本不用 `<title>` 标签定义标题。在 Minima 安装路径下运行 `grep -nr "<title>"` ，没有任何搜索结果，就可以看出来这一点。虽是如此，我们仍然可以尝试寻找一些蛛丝马迹。`<title>` 标签是要在 `<head>` 标签中使用的，所以可以搜索一下 Minima 的主题文件中有哪里用到了 `<head>`：

```console
minima-x.y.z$ grep -nr "<head>"
_includes/head.html:1:<head>
README.md:48:  - `head.html` &mdash; Code-block that defines the `<head></head>` in *default* layout.
```

可以看到 `_includes/head.html` 文件使用了 `<head>`。果不其然，这个文件里面没有用到 `<title>`。

{% raw %}
```console
minima-x.y.z$ cat _includes/head.html
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  {%- seo -%}
  <link rel="stylesheet" href="{{ "/assets/main.css" | relative_url }}">
  {%- feed_meta -%}
  {%- if jekyll.environment == 'production' and site.google_analytics -%}
    {%- include google-analytics.html -%}
  {%- endif -%}
</head>
```
{% endraw %}

不过，这个文件里仍然隐藏着一些东西。这里面有一个 {% raw %}`{%- seo -%}`{% endraw %} Liquid 标签，用于调用 [jekyll-seo-tag
插件](https://github.com/jekyll/jekyll-seo-tag)，而 `<title>` 就是由该插件自动生成的。我们可以[禁用 jekyll-seo-tag 插件自动生成 `<title>` 标签的行为](https://github.com/jekyll/jekyll-seo-tag/blob/v2.6.1/docs/advanced-usage.md#disabling-title-output)，然后手动定义该标签。

和之前一样，将 `_includes/head.html` 从 Minima 的安装路径复制到您的网站的文件夹下，然后进行编辑：

{% raw %}
```diff
--- minima-x.y.z/_includes/head.html
+++ site-root/_includes/head.html

   <meta charset="utf-8">
   <meta http-equiv="X-UA-Compatible" content="IE=edge">
   <meta name="viewport" content="width=device-width, initial-scale=1">
-  {%- seo -%}
+  {%- seo title=false -%}
+  <title>{{ site.data.l10n.title }}</title>
   <link rel="stylesheet" href="{{ "/assets/main.css" | relative_url }}">
   {%- feed_meta -%}
   {%- if jekyll.environment == 'production' and site.google_analytics -%}
```
{% endraw %}

现在，HTML 标题中不再显示 SEO 插件自动在网站标题后面插入的描述，但是标题可以被正确地翻译了。

![英文版网站的 HTML 标题]({{ img_path }}/html-title-after-en.png)

![中文版网站的 HTML 标题，已被正确翻译]({{ img_path }}/html-title-after-zh.png)
