---
title: "Home"
layout: home
permalink: /
lang: en
license: false
pagination:
  enabled: true
---

{% capture contents %}
## Collections
{: .archive__subtitle}

- [Build a Multilingual Jekyll Site](/collections/multilingual-jekyll-site)
- [GTA Online Guides](/collections/gta-online-guides)
{% endcapture %}

{{ contents | markdownify }}
