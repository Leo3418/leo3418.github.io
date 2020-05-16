---
title: "Localize Site Title"
ordinal: 51
level: 2
lang: en
---
{% include img-path.liquid %}

A Jekyll site's title is usually defined in `_config.yml` with key `title` and
can be accessed via variable `site.title`. This is also where most Jekyll
themes will read the site title from. Unfortunately, the variable can only hold
one value, so we can't assign to it multiple titles in different languages.
Even if we store key-value pairs in it, Polyglot can't get the value with
language code key and mask `site.title` with the localized title.

![The title looks OK on the English site](/assets/img/{{ page.permalink }}/before-en.png)
![On the Chinese site, the title is not translated](/assets/img/{{ page.permalink }}/before-zh.png)

Therefore, we must modify any include and layout files that access `site.title`
to let them read a localized site title in another way. Here, I plan to store
the translated tities in data files because Polyglot
[supports](https://github.com/untra/polyglot/blob/1.3.2/README.md#localized-sitedata)
localized `site.data`. Under the `_data` directory, create a directory for each
language, which will hold localized data files for that language. If your site
does not have a `_data` directory, then just create one before proceeding.

```sh
site-root$ cd _data
site-root$/_data$ mkdir en zh
```

In each directory, create a file `l10n.yml` which will contain localized data
for the corresponding language, then define the translated title in it:

```sh
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

These values are accessible via `site.data.l10n.title`. Polyglot's localized
`site.data` feature intelligently injects the correct translation into that
variable. Great, now we just need to let the theme read our site title from the
variable.

If you used `jekyll new PATH` command to create your site, which should applied
the Minima theme to it, then you might ask where the theme's files are stored.
Under the site root, no file or directory seems to contain anything for the
theme:

```sh
site-root$ ls
404.html        _config.yml  Gemfile       index.markdown  _site
about.markdown  _data        Gemfile.lock  _posts
```

This is explained [on Jekyll's documentation
site](https://jekyllrb.com/docs/themes/#understanding-gem-based-themes): the
theme files are stored somewhere else on your machine. It is still possible to
override them just for the current site by copying them into the respective
directories under the site root and editing the copy; the steps are described
[here](https://jekyllrb.com/docs/themes/#overriding-theme-defaults).

Now, we just need to find out which files are using the `site.title` variable.
If you have `grep` available on your machine, then try to run this command
under the installation path of the theme and you should capture all of them:

{% raw %}
```sh
minima-x.y.z$ grep -nr "site\.title"
_includes/header.html:6:    <a class="site-title" rel="author" href="{{ "/" | relative_url }}">{{ site.title | escape }}</a>
_includes/footer.html:6:    <h2 class="footer-heading">{{ site.title | escape }}</h2>
_includes/footer.html:15:              {{ site.title | escape }}
README.md:81:Usually the `site.title` itself would suffice... (truncated)
```
{% endraw %}

We can ignore `README.md` because it's just Minima's documentation referring to
the variable. So, the files we should override are `_includes/header.html` and
`_includes/footer.html`. Copy them to the `_includes` directory under the site
root to edit them. The `-n` option for `grep` makes it output line numbers, so
you know exactly which lines to edit in those files.

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

If you already have include and layout files under the site root that reads
from `site.title`, then you can run the same `grep` command from the site root,
which should give you a list of files to edit and where to modify as well.

Now, you should see that your site's title is translated for every version on
the page.

![The title on webpage is now translated](/assets/img/{{ page.permalink }}/site-title-after-zh.png)

## For Minima: Change the Title in HTML

When you look carefully in the screenshot above, you may find that the page's
title shown on top of the browser tab, which is determined by the `<title>` tag
in HTML, is still not changed. But the `grep` command we ran before has already
given us all the usages of `site.title`. What's happening here?

It turns out that Minima's theme files don't even use the `<title>` tag! This
can be discovered by running `grep -nr "<title>"` in the theme's installation
path and seeing no reported occurrences. But after all, we can still try to
find where Minima uses the `<head>` tag, in which `<title>` would reside:

```sh
minima-x.y.z$ grep -nr "<head>"
_includes/head.html:1:<head>
README.md:48:  - `head.html` &mdash; Code-block that defines the `<head></head>` in *default* layout.
```

It's used in `_includes/head.html`. Examine the file and we can confirm that
`<title>` is used nowhere:

{% raw %}
```sh
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

There's still something interesting to notice in this file. We can see the
{% raw %}`{%- seo -%}`{% endraw %} Liquid tag, which is for the [jekyll-seo-tag
plugin](https://github.com/jekyll/jekyll-seo-tag). The `<title>` tag is
generated by that plugin when {% raw %}`{%- seo -%}`{% endraw %} is used.
Luckily though, it allows us to [disable `<title>`
output](https://github.com/jekyll/jekyll-seo-tag/blob/v2.6.1/docs/advanced-usage.md#disabling-title-output)
so we can define the title manually.

Like before, copy `_includes/head.html` from Minima installation directory into
your site and edit it:

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

This should do the work. You may see that the HTML title no longer contains a
description after the site title because it was added by the SEO plugin, but
the title can now be translated correctly.

![HTML title for English version](/assets/img/{{ page.permalink }}/html-title-after-en.png)
![HTML title for Chinese version, which is now translated](/assets/img/{{ page.permalink }}/html-title-after-zh.png)
