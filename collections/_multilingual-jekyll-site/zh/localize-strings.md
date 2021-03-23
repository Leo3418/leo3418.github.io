---
title: "本地化字符串"
ordinal: 53
level: 2
lang: zh
---
{% include img-path.liquid %}
Jekyll 主题里往往会有一些字符串出现在网页的结构中，但主题并没有提供自定义这些字符串的功能。比如说，Minima 主题会在主页的帖子列表上方显示“Posts”，然后在帖子列表底部显示“subscribe via RSS”。即使网页上的内容是以其它语言呈现的，这些字符串依然以英文显示：

![未翻译的字符串]({{ img_path }}/not-translated.png)

接下来要做的就是将这些字符串本地化，让它们的语言和网页内容的语言一致。我们首先从“subscribe via RSS”入手，因为它是一个很平常和普通的例子。和之前一样，在 Minima 的安装路径中搜索这个字符串在什么地方出现过。不过，因为这个字符串中的“via RSS”是一个超链接，所以直接搜索整个字符串可能会搜不到，因此我们直接搜索“subscribe”：

{% raw %}
```console
minima-x.y.z$ grep -nr "subscribe"
_layouts/home.html:31:    <p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | relative_url }}">via RSS</a></p>
```
{% endraw %}

果然如预料之中的那样，“via RSS”被放在了一个 `<a>` 标签中，所以直接搜“subscribe via RSS”是搜不到的。

找到包含这个字符串的文件后，我们就可以把它拷到自己网站的文件中，开始编辑。在此之前，需要先规划一个存放翻译过的字符串的位置。尽管我们可以选择给每个语言都创建一个独立的 `_layouts/home.html` 文件然后在里面本地化，但是除非是想给不同语言的网页设计不同的布局，否则这样做并不是特别好的习惯。假如所有语言的网站的页面布局都是一样的，但是每个语言都有一份自己的布局文件，那么如果日后想改整个网站的布局，就得去修改每一个文件。

我想到的解决办法是和之前本地化网站标题一样，在 `_data` 文件夹下创建一个专门存放翻译后的字符串的文件 `strings.yml`：

```console
site-root/_data$ ls *
en:
l10n.yml  strings.yml

zh:
l10n.yml  strings.yml
```

然后，在每个 `strings.yml` 文件当中，用 YAML 语法来为每个要翻译的字符串定义键值。

{% raw %}
```console
site-root/_data$ cat en/strings.yml
rss_subscribe: 'subscribe <a href="$url">via RSS</a>'
site-root/_data$ cat zh/strings.yml
rss_subscribe: '<a href="$url">通过 RSS</a> 订阅'
```
{% endraw %}

这里使用了一个网址的占位符 `$url`，日后如果想更改网址的话，就不需要修改 `strings.yml` 了。

接下来要做的就是修改网站源文件根目录下的 `_layouts/home.html`，使用翻译过后的字符串，并且填入链接的网址：

{% raw %}
```diff
--- minima-x.y.z/_layouts/home.html
+++ site-root/_layouts/home.html

       {%- endfor -%}
     </ul>

-    <p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | relative_url }}">via RSS</a></p>
+    {%- assign feed_url = "/feed.xml" | relative_url -%}
+    <p class="rss-subscribe">{{ site.data.strings.rss_subscribe | replace: "$url", feed_url }}</p>
   {%- endif -%}

 </div>
```
{% endraw %}

现在，切换语言后，“subscribe via RSS”就会变为翻译后的字符串了。您可以点一下链接，确认上述占位符处填入的网址没有问题。

![“subscribe via RSS”已被翻译]({{ img_path }}/rss-subscribe-translated.png)

不过，“Posts”的本地化还没有完成，在 Minima 的安装路径中再次用 `grep` 搜索它：

{% raw %}
```console
minima-x.y.z$ grep -nr "Posts"
_layouts/home.html:13:    <h2 class="post-list-heading">{{ page.list_title | default: "Posts" }}</h2>
_sass/minima/_layout.scss:213: * Posts
README.md:79:From Minima v2.2 onwards, the *home* layout will inject all content from your `index.md` / `index.html` **before** the **`Posts`** heading. This will allow you to include non-posts related content to be published on the landing page under a dedicated heading. *We recommended that you title this section with a Heading2 (`##`)*.
README.md:88:The title for this section is `Posts` by default and rendered with an `<h2>` tag. You can customize this heading by defining a `list_title` variable in the document's front matter.
```
{% endraw %}

这里的搜索结果有点特别。首先，我们来看最后一条结果 `README.md:88`：

> You can customize this heading by defining a `list_title` variable in the
> document's front matter.

翻译过来如下：

> 您可以在文档头部的信息块中定义 `list_title` 变量，然后自定义此标题的文本。

这里所讲的就是 `_layouts/home/html:13` 所做的事：Minima 首先尝试读取 `page.list_title` 变量的值；如果该变量已被定义了一个有效的值，那么就直接用该值来做帖子列表的标题；否则，使用默认的“Posts”作为标题。既然 Minima 没有硬编码这个字符串，允许自定义，我们可以直接按照它的指示，在信息块里修改它。

在本地化这个字符串前，我们先小试牛刀，在信息块里定义这个变量，看修改它会产生什么样的结果：

```console
site-root$ cat index.md
---
layout: home
list_title: "List of Posts"
---
```

![帖子列表的标题发生了变化]({{ img_path }}/list-title-changed.png)

成功了！现在要做的就是为您的网站支持的每一种语言都创建一个 `index.md` 文件，然后在文件头部的信息块定义本地化的字符串。别忘了同时在信息块中声明 [Polyglot 需要的永久链接和语言代码](https://github.com/untra/polyglot/blob/1.3.2/README.md#how-to-use-it)。在此基础上，您还可以选择在英文主页中省略 `list_title` 的定义，直接使用默认的标题；如果您的网站的默认语言有自己的 `index.md`，还可以将原有的 `index.md` 文件删除。

```console
site-root$ cat index-en.md
---
layout: home
permalink: "/"
lang: zh
---
site-root$ cat index-zh.md
---
layout: home
list_title: "帖子列表"
permalink: "/"
lang: zh
---
```

![本地化后的帖子列表标题]({{ img_path }}/list-title-localized.png)

目前唯一没有本地化的网页元素就是右下角的网站描述了，不过对它进行本地化的步骤和[上一部分](localize-site-title)提及的本地化网站标题的步骤是相似的，也就不再赘述了。
