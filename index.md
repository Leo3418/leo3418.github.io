---
title: "Home"
permalink: /
lang: en
---

## Posts
{% for post in site.posts %}
[{{ post.title }}]({{ post.url }})
{% endfor %}
