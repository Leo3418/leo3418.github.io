---
title: 'Add a "No Translation" Message'
ordinal: 54
level: 2
lang: en
---
{% include img-path.liquid %}

If you expect that some of your posts will not be translated to every language
supported by your site, then you might want to tell those post's viewers that a
translation is not available for their language.

Let's first create some stub pages or test posts that are available in only one
language and see what will happen when it is accessed from another localized
version of your site.

```console
site-root$ cat _posts/en/2020-04-29-special-post.md 
---
layout: post
title: "Special Post"
lang: en
---

Heads up! This post is available in English only.
```

You will still be able to access the post in another language because Polyglot
ensures that all localized versions of your site have the same site map. All
localizations and customizations we did earlier persist, including site title
and language switcher; the post's content is presented as-is.

![The post accessed in another language]({{ img_path }}/view-post-in-another-lang.png)

Now let's work on showing the message to help the visitors know what's going
on. First, create an HTML element for the message:

```html
<div class="message-box" id="no-translation-msg">
    Sorry, this page is not available in this language.
</div>
```

Because we want to reuse it on probably multiple pages, it's better to put it
into a file under the `_includes` directory. Also, we definitely want the
message to be localized, so we will define translated strings for it. After
these works, you might have something like this:

{% raw %}
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
{% endraw %}

Now, we just need to let `no-translation.html` to be
{% raw %}`{% include %}`{% endraw %}d in the webpage when a translation is
unavailable. One good place to put the message is right before the page's main
content. For Minima, this can be done by overriding `_layouts/default.html`:

{% raw %}
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
{% endraw %}

The message should now show up on pages where the content is not localized:

!["No Translation" message in Chinese]({{ img_path }}/message-added-zh.png)

## Apply Styles to the Message

Optionally, you can touch up the message's appearance by applying some styles
to it. The following snippet contains some SCSS styles that can be put in file
`_sass/main.scss` under the site root. Depending on the theme you use, the
steps to modify stylesheets for your site might vary, so be sure to read the
theme's documentation when in doubt. For Minima 2.5.1, details on how to define
your own styles can be found
[here](https://github.com/jekyll/minima/blob/v2.5.1/README.md#customization).

```scss
.message-box {
    background-color: #eef;
    border: 1px solid $grey-color-light;
    border-radius: 3px;
    margin-bottom: $spacing-unit;
    text-align: center;
}
```

After applying some styles, you can add more test posts not translated to every
supported language and see if the message looks satisfying.

![Message in Chinese with style applied]({{ img_path }}/style-applied-zh.png)
![Message in English with style applied]({{ img_path }}/style-applied-en.png)
