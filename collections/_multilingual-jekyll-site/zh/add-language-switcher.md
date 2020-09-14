---
title: "添加语言切换器"
ordinal: 52
level: 2
lang: zh
toc: true
---
{% include img-path.liquid %}

您的网站的各个语言版本可以通过在网址后面添加语言代码的方式来访问，但是如果让每个网站访问者都通过这种方式切换语言的话，实属不方便。一种可行的解决方法是在网站的一个醒目位置加一个语言选择器，不仅方便了语言选择，还可以明确地提醒访问者您的网站支持多种语言。

接下来我将展示的是给网站添加语言选择器的方法。也许叫它“语言切换器”会更准确一些，因为它将允许访问者切换到同一页面的不同语言版本，正如在维基百科上点语言链接后跳到的是同一页面的另一语言的翻译一样。

## 创建一个最基础的切换器

一个语言切换器应该提供指向每种语言版本的页面的链接，而网站支持的所有语言可以通过 `site.languages` 变量来获取。我们可以先尝试将网站支持的语言在网站主页上显示出来。在主页文件（一般文件名是 `index.md` 或 `index.markdown` 等）中加入如下内容：

{% raw %}
```liquid
{% for lang in site.languages %}
{{ lang }}
{% endfor %}
```
{% endraw %}

接下来就可以把这些语言的代码转化为超链接了。除了默认语言的版本外，您网站其它所有语言版本的网址里都是有语言代码的。例如，如果一个网站支持 `en`、`es`、`de` 和 `fr` 这几种语言，并且使用 `en` 作为默认语言，那么每种语言下的网页的相对网址的开头就分别是 `/`、`/es`、`/de` 和 `/fr`。作为默认语言，`en` 语言下的网页的网址都是没有语言代码的。因此，我们还需要通过将语言代码和 `site.default_lang` 变量比较的方式来看一个语言是不是默认语言：

{% raw %}
```liquid
{% for lang in site.languages %}
    {% if lang == site.default_lang %}
{{ lang }} (Default)
    {% else %}
{{ lang }}
    {% endif %}
{% endfor %}
```
{% endraw %}

现在我们就可以正式创建超链接了。下面的示例通过 HTML 代码创建超链接，不过因为 Markdown 中可以直接使用 HTML，所以在 Markdown 文件中也可以使用下面的代码。需要特别注意的一点：{% raw %}`href=" {{ page.url }}"`{% endraw %} 当中**有一个空格**，在第一个双引号和第一个左花括号之间。加入这个空格的原因是[阻止 Polyglot 生成相对于当前语言版本网站的链接](https://github.com/untra/polyglot/blob/1.3.2/README.md#relativized-local-urls)：如果没有这个空格的话，Polyglot 就会在网址中加入当前语言的代码，实际生成的就是一个当前语言版本的当前网页的链接，而不是切换到另一种语言的链接。用户点击这样的链接，就还是会回到当前的页面。

{% raw %}
```html
{% for lang in site.languages %}
    {% if lang == site.default_lang %}
<a href=" {{ page.url }}">{{ lang }}</a>
    {% else %}
<a href="/{{ lang }}{{ page.url }}">{{ lang }}</a>
    {% endif %}
{% endfor %}
```
{% endraw %}

## 移除当前语言的链接

语言切换器中，当前语言所对应的链接被点击后还是会回到同样的页面，没有存在的必要，所以可以删掉。

当前语言的代码可以通过 `site.active_lang` 获取，所以我们可以在遍历网站支持的所有语言的代码时，检查每个代码是否和当前语言的代码一致。如果是的话，就不为其生成超链接。

{% raw %}
```liquid
{% for lang in site.languages %}
    {% if lang == site.active_lang %}
{{ lang }}
    {% else %}
        {% if lang == site.default_lang %}
<a href=" {{ page.url }}">{{ lang }}</a>
        {% else %}
<a href="/{{ lang }}{{ page.url }}">{{ lang }}</a>
        {% endif %}
    {% endif %}
{% endfor %}
```
{% endraw %}

## 用语言的名字取代代码

尽管表示语言用的 ISO 639-1 代码有时可以让人们猜出所代表的语言，但是为了让网站看起来更专业一些，最好还是使用语言的名称而不是代码来表示语言。

首先，我们可以在之前本地化网站标题时创建的 `l10n.yml` 中定义语言的名称：

```console
site-root/_data$ cat en/l10n.yml
lang_name: "English"
title: "My Site"
site-root/_data$ cat zh/l10n.yml
lang_name: "中文"
title: "本人的网站"
```

这样一来，如果想获取当前语言的名称，使用 `site.data.l10n.lang_name` 即可；而如果需要某个特定语言的名称的话，可以用 `site.data[lang].l10n.lang_name`，其中 `lang` 是要查询的语言的代码。

这样一来，我们就可以在语言切换器中使用语言的名称，而不是代码了。因为要被用到好几次，所以我们把语言名称保存到一个变量里，方便复用。

{% raw %}
```liquid
{% for lang in site.languages %}
    {% assign lang_name = site.data[lang].l10n.lang_name %}
    {% if lang == site.active_lang %}
{{ lang_name }}
    {% else %}
        {% if lang == site.default_lang %}
<a href=" {{ page.url }}">{{ lang_name }}</a>
        {% else %}
<a href="/{{ lang }}{{ page.url }}">{{ lang_name }}</a>
        {% endif %}
    {% endif %}
{% endfor %}
```
{% endraw %}

## 给每个页面都加上语言切换器

如果想允许网站访问者在每个页面上都能切换语言的话，就需要在每个页面上都加入相关的代码。最好的办法是将语言切换器的代码放入网站根目录下 `_includes` 文件夹中的一个文件内，然后从其它地方 {% raw %}`{% include %}`{% endraw %} 它。

在 `_includes` 文件夹下创建一个 `lang-switcher.html` 文件，然后把语言切换器的代码挪到其中，就可以在其它地方使用 {% raw %}`{% include lang-switcher.html %}`{% endraw %} 来直接插入语言切换器了。

例如，我们可以通过编辑 `_includes/footer.html` 把语言切换器放在页面底部的位置：

{% raw %}
```diff
             {%- if site.email -%}
             <li><a class="u-email" href="mailto:{{ site.email }}">{{ site.email }}</a></li>
             {%- endif -%}
         </ul>
+        <div class="lang-switcher">
+          {%- include lang-switcher.html -%}
+        </div>
       </div>

       <div class="footer-col footer-col-2">
```
{% endraw %}

然后，访问您的网站上任意一个以多种语言提供的网页，点击语言切换器中的链接，就应该能切换到同一页面的另一种语言版本了。

![将语言切换至英文]({{ img_path }}/footer-en.png)

![将语言切换至中文]({{ img_path }}/footer-zh.png)
