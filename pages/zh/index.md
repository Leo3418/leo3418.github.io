---
title: "主页"
layout: home
permalink: /
lang: zh
license: false
pagination:
  enabled: true
---

{% capture contents %}
## 系列文章
{: .archive__subtitle}

- [建立多语言 Jekyll 网站](/collections/multilingual-jekyll-site)
- [Windows 10 Mobile 系列文章](/collections/windows-10-mobile)
{% endcapture %}

{{ contents | markdownify }}
