---
title: "本地化日期格式"
ordinal: 55
level: 2
lang: zh
---
{% include img-path.liquid %}
在网站上发表帖子的时候，您可能想在网页上显示帖子的发布日期。既然有了日期，那也就有了日期格式的问题。世界各地使用的日期格式是不同的：中国惯用的是年/月/日的格式；欧洲的许多国家使用的却是日/月/年的格式；美国使用的是月/日/年的格式。一旦日期格式不统一，就容易造成歧义，比如 01/09/2020，许多欧洲人会读作 2020 年 9 月 1 日，可美国人就会看成 2020 年 1 月 9 日。因此，本地化的日期格式必不可少。接下来我们就来看如何让网站上的日期格式随同语言一起变化。

首先，将您要使用的每种日期格式转化为日期格式字符串。我在这里列出了一些常见的日期格式以及它们对应的格式字符串：

| 格式字符串 | 日期格式 |
| :---: | :---: |
{% assign formats = "%e %B %Y | %A, %B %e, %Y | %a %b %d, %Y | %F | %m/%d/%Y | %d/%m/%y" | split: " | " %}
{%- for format in formats -%}
| `{{ format }}` | {{ "2020-09-01" | date: format }} |
{% endfor %}

如果您需要的日期格式在这里没有列出，您可以在[此处](http://man7.org/linux/man-pages/man3/strftime.3.html#DESCRIPTION)查阅所有的日期格式指示符。

确定了每种语言下的日期格式后，就可以将它们加入各语言所对应的 `l10n.yml` 文件中了。

```console
site-root$ cat _data/en/l10n.yml
lang_name: "English"
title: "My Site"
date_format: "%b %e, %Y"
site-root$ cat _data/zh/l10n.yml
lang_name: "中文"
title: "本人的网站"
date_format: "%F"
```

适用于当前语言的日期格式字符串就可以通过 `site.data.l10n.date_format` 变量来读取了。如果要格式化一个日期，可以使用 Liquid 的 [`date` 过滤器](https://shopify.github.io/liquid/filters/date/)。例如，如果要格式化当前页面的日期，那么就在页面里插入如下代码：

{% raw %}
```liquid
{{ page.date | date: site.data.l10n.date_format }}
```
{% endraw %}

## 替换 Minima 的日期格式

Minima 会自动在网页上列出一篇帖子的日期，也支持使用 `site.minima.date_format` 变量 [自定义日期格式](https://github.com/jekyll/minima/blob/v2.5.1/README.md#change-default-date-format)。不过，和[网站标题](localize-site-title)的情况类似，我们只能指定一种日期格式，而不是多种。

解决这个问题的办法和本地化网站标题差不多，也就是找出 Minima 的主题文件中哪里会用到 `site.minima.date_format` 变量的值，然后对这些地方进行修改。

{% raw %}
```console
minima-x.y.z$ grep -nr "site.minima.date_format"
_layouts/home.html:17:        {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
_layouts/post.html:10:        {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
README.md:129:You can change the default date format by specifying `site.minima.date_format`
```

```diff
--- minima-x.y.z/_layouts/home.html
+++ site-root/_layouts/home.html

     <ul class="post-list">
       {%- for post in site.posts -%}
       <li>
-        {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
+        {%- assign date_format = site.data.l10n.date_format | default: "%b %-d, %Y" -%}
         <span class="post-meta">{{ post.date | date: date_format }}</span>
         <h3>
           <a class="post-link" href="{{ post.url | relative_url }}">
 
--- minima-x.y.z/_layouts/post.html
+++ site-root/_layouts/post.html

     <h1 class="post-title p-name" itemprop="name headline">{{ page.title | escape }}</h1>
     <p class="post-meta">
       <time class="dt-published" datetime="{{ page.date | date_to_xmlschema }}" itemprop="datePublished">
-        {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
+        {%- assign date_format = site.data.l10n.date_format | default: "%b %-d, %Y" -%}
         {{ page.date | date: date_format }}
       </time>
       {%- if page.author -%}
```
{% endraw %}

完成上述修改后，访问您的网站的每个语言版本，应该可以看到日期的格式都被本地化了。

![本地化后的中文日期格式]({{ img_path }}/after-zh.png)
