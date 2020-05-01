---
title: "Building a Multilingual Jekyll Site"
permalink: /collections/multilingual-jekyll-site
lang: en
license: false
---

As I explained in [this post](/2020/04/24/restarting-personal-site), I plan to
share on this site my experience and knowledge about things I play around with,
in more than one language when possible. So, my goal was to build a
multilingual Jekyll site. Thanks to plugin developers, multilingual plugins
make this task easy, but there are still a few things that require extra care
and some enhancements not offered by those plugins which can improve your
site's user experience, and they will be covered by pages in this collection.
We will walk through all the steps needed to set up a multilingual Jekyll site
similar to this one.

The multilingual plugin I will use for this collection is
[Polyglot](https://github.com/untra/polyglot/). Of course, this is also the
plugin that this site uses as of this collection is composed. I will discuss
why I chose this plugin in a section in this collection.

## Contents

<ul>
{% for section in site.multilingual-jekyll-site %}
{%- capture entry -%}<li><p><a href="{{ section.url }}">{{ section.title }}</a></p></li>{%- endcapture -%}
{%- if section.level -%}
    {%- for i in (2..section.level) -%}<ul>{%- endfor -%}
    {{ entry }}
    {%- for i in (2..section.level) -%}</ul>{%- endfor -%}
{%- else -%}
{{ entry }}
{% endif %}
{% endfor %}
</ul>
