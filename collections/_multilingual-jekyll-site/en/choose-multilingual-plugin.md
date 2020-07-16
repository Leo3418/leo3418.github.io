---
title: "Choose a Multilingual Plugin"
ordinal: 20
lang: en
---

It is better to select the multilingual plugin you want to use before every
other thing because each plugin has different philosophy on how your posts
should be organized and where the metadata for your posts should be put. If you
decide to switch to another plugin later, you might have to move your posts
around and/or change front matters of all your pages.

To choose a plugin, have a rough idea on how your site will look like. In my
case, my site would definitely have pages offered in multiple languages, and it
would be great if visitors can view the page in another language with one
click, like on Wikipedia. Some pages, however, would be only available in a
single language; in this case, my site should either don't show links to other
languages, which is also similar to Wikipedia, or display a message after
visitors click on a language link showing that translation is not provided.

Polyglot serves my purpose well. It ensures that the site map is consistent
among all localized versions of the site, so even if a post is not translated
to all languages, a webpage for it will be generated for every language. By
default, if a translation is not available, then the post will be presented in
the site's default language. What if the post is only available in a
non-default language? Polyglot will just use that version for all other
languages, including the default one. (However, I haven't tested which
translation will be used if a post is provided in all languages but the default
one and the site supports three or more languages.) With this feature, at least
I would be able to allow visitors see a message for untranslated posts.

The only thing I don't like very much about Polyglot is it requires assigning a
permalink to each document (i.e. a non-post item inside a collection) in its
front matter. I want to use the document's file path directly as the permalink.
Fortunately, this can be achieved by setting up [global permalinks for a
collection](https://jekyllrb.com/docs/permalinks/#collections), which [greatly
reduces
redundancy](https://github.com/Leo3418/leo3418.github.io/commit/96102384cda7914052b173b5a83ce56068941218).

I also looked at some other multilingual plugins. The [Octopress
Multilingual](https://github.com/octopress/multilingual) plugin seems to have
very good concepts, but it has been not getting any update since 2015, and
users have been reporting that it is incompatible with Jekyll 3, not to mention
Jekyll 4. The [Jekyll Multiple Languages
Plugin](https://github.com/kurtsson/jekyll-multiple-languages-plugin) supports
Jekyll 4, but if I were to use it, I would need to maintain a dedicated list of
all page titles for a language in a single file, as shown
[here](https://github.com/kurtsson/jekyll-multiple-languages-plugin/blob/v1.6.1/README.md#54-i18n-in-templates).
I hate separating a page's metadata from its contents.
