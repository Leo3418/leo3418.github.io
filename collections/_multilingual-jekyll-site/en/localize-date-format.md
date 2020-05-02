---
title: "Localize Date Format"
permalink: /collections/multilingual-jekyll-site/localize-date-format
ordinal: 55
level: 2
lang: en
---
{% include img-path.liquid %}

If you want to make posts on your site or to record when a page is published,
you might also wish to put the date onto the webpage. Not only are your
contents translated into other languages, but you should also take into account
the fact that different locales have different date formats. In this section,
we will look at how to let the date format change together with the language.

For each date format, first figure out its format string. For your convenience,
here is a list of some common date formats I have seen and their corresponding
format strings:

| Format String | Date Format |
| :-----------: | :---------: |
{% assign formats = "%e %B %Y | %A, %B %e, %Y | %a %b %d, %Y | %F | %m/%d/%Y | %d/%m/%y" | split: " | " %}
{%- for format in formats -%}
| `{{ format }}` | {{ "2020-09-01" | date: format }} |
{% endfor %}

If you need something else, you can find a comprehensive list of date format
specifiers
[here](http://man7.org/linux/man-pages/man3/strftime.3.html#DESCRIPTION).

After the format strings are determined, add each of them to the file
`l10n.yml` for the corresponding language.

```sh
site-root$ cat _data/en/l10n.yml
lang_name: "English"
title: "My Site"
date_format: "%b %e, %Y"
site-root$ cat _data/zh/l10n.yml
lang_name: "中文"
title: "本人的网站"
date_format: "%F"
```

The format string for the current active language can then be accessed via
`site.data.l10n.date_format`. To apply it to a date, you can use the [`date`
Liquid filter](https://shopify.github.io/liquid/filters/date/). For instance,
to format the current page's date, use the following:

{% raw %}
```liquid
{{ page.date | date: site.data.l10n.date_format }}
```
{% endraw %}

## Replacing Date Format Strings in Minima

You might have noticed that Minima automatically puts a post's date for both
its entry on the home page and its webpage. Minima supports [customizing the
date
format](https://github.com/jekyll/minima/blob/v2.5.1/README.md#change-default-date-format)
via `site.minima.date_format`, but we can only specify one format rather than
many, similar to the situation we faced for the [site
title](localize-site-title).

Like how we localize site title, we need to modify the files where Minima reads
in the date and applies the format to it.

{% raw %}
```sh
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

After making the modifications above, visit some posts in every localized
version of your site, and you should see your new date formats being applied.

![Localized date in Chinese version]({{ img_path }}/after-zh.png)
