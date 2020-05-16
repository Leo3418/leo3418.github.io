---
title: "Localize Strings"
ordinal: 53
level: 2
lang: en
---
{% include img-path.liquid %}

A Jekyll theme is likely to have non-content strings on certain webpages. These
strings are usually hard-coded in the theme's files so you cannot modify them
without overriding the theme. For instance, Minima puts "Posts" above the list
of posts on the home page and adds a "subscribe via RSS" link under it. When a
language other than English is chosen, those strings are still presented in
English:

![Strings not being translated]({{ img_path }}/not-translated.png)

We will localize those strings so that they will show up in the active
language. In this example, we will first deal with the "subscribe via RSS"
string because it is a good general example. Again, go back to Minima's
installation path, and search for any occurrence of the string. Here, notice
that the last two words in the string are part of a hyperlink, so if you search
for "subscribe via RSS", there might be no results. Instead, we search for
"subscribe":

{% raw %}
```sh
minima-x.y.z$ grep -nr "subscribe"
_layouts/home.html:31:    <p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | relative_url }}">via RSS</a></p>
```
{% endraw %}

We do see that "via RSS" is wrapped in an `<a>` tag, which is why there is no
occurrence of "subscribe via RSS".

Now that the file containing the string is found, we just copy it back into our
own site and modify it. Now, we should think about where the translated strings
should be put. We can make a copy of `_layouts/home.html` for every language
and translate the string directly in the layout file. But, unless we are
planning to define different layouts for different languages, this is not a
good practice. If we want to change the layout for all languages later, we will
have to modify all of the copies rather than just one file. 

My solution is to maintain a file which stores all translated strings for each
language, similar to how we manage localized site titles. In each directory
under `_data`, create a file named `strings.yml`: 

```sh
site-root/_data$ ls *
en:
l10n.yml  strings.yml

zh:
l10n.yml  strings.yml
```

Then, in each `strings.yml`, define key-value pairs for translated strings in
YAML syntax. It is recommended to assign short but meaningful key names to the
values so that they are neither difficult to type in nor likely to duplicate
any keys you might want to add in the future.

{% raw %}
```sh
site-root/_data$ cat en/strings.yml
rss_subscribe: 'subscribe <a href="$url">via RSS</a>'
site-root/_data$ cat zh/strings.yml
rss_subscribe: '<a href="$url">通过 RSS</a> 订阅'
```
{% endraw %}

Here, a placeholder `$url` is used instead of the actual URL, so we can change
the URL later without modifying `strings.yml`.

Next, modify `_layouts/home.html` under site root to use the string and fill in
the URL:

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

You should now see the string being translated when you change the language.
Click on the link to verify that the URL is correct.

!["subscribe via RSS" is now translated]({{ img_path }}/rss-subscribe-translated.png)

We've still got to change the "Posts" string. Let's do another search in
Minima's installation path to find it:

{% raw %}
```sh
minima-x.y.z$ grep -nr "Posts"
_layouts/home.html:13:    <h2 class="post-list-heading">{{ page.list_title | default: "Posts" }}</h2>
_sass/minima/_layout.scss:213: * Posts
README.md:79:From Minima v2.2 onwards, the *home* layout will inject all content from your `index.md` / `index.html` **before** the **`Posts`** heading. This will allow you to include non-posts related content to be published on the landing page under a dedicated heading. *We recommended that you title this section with a Heading2 (`##`)*.
README.md:88:The title for this section is `Posts` by default and rendered with an `<h2>` tag. You can customize this heading by defining a `list_title` variable in the document's front matter.
```
{% endraw %}

The results show something interesting. First, look at the last entry from
`README.md:88`. It says,

> You can customize this heading by defining a `list_title` variable in the
> document's front matter.

It is describing what `_layouts/home/html:13` is doing: it will first try to
read `page.list_title` and use any value in it for the heading of the posts
list; if no value is defined, the heading defaults to "Posts". It happens that
the string is not hard-coded since we can override it in the front matter.
Let's do that now.

Before localizing the string, let's see how to define it in the front matter
and the effect of changing it:

```sh
site-root$ cat index.md
---
layout: home
list_title: "List of Posts"
---
```

![List title changed to new value]({{ img_path }}/list-title-changed.png)

It's working! We just need to create more localized versions of the home page.
Make a copy of `index.md` for every language your site supports and define
localized titles. Don't forget to also define permalink and the content's
language as [Polyglot needs
them](https://github.com/untra/polyglot/blob/1.3.2/README.md#how-to-use-it).
Optionally, you can remove the `list_title` definition for the English home
page to use the default value, and you may remove the original `index.md` if
you have a separate copy for your site's default language.

```sh
site-root$ cat index-en.md 
---
layout: home
permalink: "/"
lang: en
---
site-root$ cat index-zh.md 
---
layout: home
list_title: "帖子列表"
permalink: "/"
lang: zh
---
```

![Localized list title]({{ img_path }}/list-title-localized.png)

By now, the only untranslated content on the webpage is the description in the
bottom-right corner. Localizing it is similar to localizing the site title,
which has been covered in a [previous section](localize-site-title).
