---
title: "主页"
permalink: /
lang: zh
---

## 帖子列表
{% for post in site.posts %}
[{{ post.title }}]({{ post.url }})
{% endfor %}
