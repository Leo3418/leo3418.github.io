---
title: '添加“无翻译”提示信息'
weight: 54
---

如果您准备不提供您网站某些页面的所有语言的翻译的话，您可能想告知访问者这些文章没有他们需要的语言版本。接下来我们就将添加一则这样的提示信息，在需要的时候显示。

首先我们来创建一条只以一种语言发表的测试帖，然后用另一种语言查看该帖，看看会发生什么。

```console
site-root$ cat _posts/en/2020-04-29-special-post.md
---
layout: post
title: "Special Post"
lang: en
---

Heads up! This post is available in English only.
```

得益于 Polyglot 确保网站所有语言版本的站点地图全部一致的特性，访问者们仍然可以看到该帖，并且之前所做的本地化在网页上也全部显现了出来，唯独帖子的内容是按照原样展示的。

![用无翻译的语言查看帖子]({{< static-path img view-post-in-another-lang.png >}})

现在，我们就来尝试在这种情况下在页面顶部显示“此页无翻译”的提示信息。第一步是给提示信息创建一个 HTML 元素：

```html
<div class="message-box" id="no-translation-msg">
    Sorry, this page is not available in this language.
</div>
```

因为这条提示信息可能会在多个网页上展示，所以应该将其放入 `_includes` 文件夹下的一个文件中，以允许复用。此外，作为一个多语言网站，我们自己的提示信息肯定是得翻译的。抽离到一个单独的文件，并本地化提示信息后，差不多应该是下面的情形：

```console
site-root$ cat _includes/no-translation.html
<div class="message-box" id="no-translation-msg">
    {{ site.data.strings.no_translation }}
</div>
site-root$ cat _data/en/strings.yml
rss_subscribe: 'subscribe <a href="$url">via RSS</a>'
no_translation: "Sorry, this page is not available in English."
site-root$ cat _data/zh/strings.yml
rss_subscribe: '<a href="$url">通过 RSS</a> 订阅'
no_translation: "抱歉，此页面无中文版。"
```

接着，我们需要做的就是在内容没有翻译的页面上插入 `{% include no-translation.html %}`，以添加这条提示信息。在网页主体的最顶端放置信息是个不错的选择。对于 Minima 主题，可以覆写 `_layouts/default.html`：

```diff
--- minima-x.y.z/_layouts/default.html
+++ site-root/_layouts/default.html

     <main class="page-content" aria-label="Content">
       <div class="wrapper">
+        {%- if page.lang != site.active_lang -%}
+          {%- include no-translation.html -%}
+        {%- endif -%}
+
         {{ content }}
       </div>
     </main>
```

现在，在内容没有被本地化的页面上，这条提示信息就会被显示了。

![中文“无翻译”提示信息]({{< static-path img message-added-zh.png >}})

## 给提示信息应用样式

您可以选择给提示信息添加一些样式，让其看起来更美观。例如，可将下面的代码添加到您网站根目录下的 `_sass/main.scss` 文件下。如果使用的主题不同，修改网站的样式表的步骤也可能不同；如果遇到不确定的地方，请参阅您使用的主题的相关文档。Minima 2.5.1 的有关自定义样式的说明可以在[此处](https://github.com/jekyll/minima/blob/v2.5.1/README.md#customization)访问。

```scss
.message-box {
    background-color: #eef;
    border: 1px solid #e8e8e8;
    border-radius: 3px;
    margin-bottom: 30px;
    text-align: center;
}
```

应用完样式之后，您可以再多创建几个翻译不完全的测试帖，预览它们的网页，看对样式是否满意。

![应用样式后的中文提示信息]({{< static-path img style-applied-zh.png >}})

![应用样式后的英文提示信息]({{< static-path img style-applied-en.png >}})
