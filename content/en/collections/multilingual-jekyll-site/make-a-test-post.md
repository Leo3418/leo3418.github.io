---
title: "Make a Test Post"
weight: 40
---

Let's create a test post in more than one language to see if Polyglot is
working. Under the `_posts` directory, create a directory for each of your
site's supported language, whose name is the language's ISO 639-1 code you
added to `_config.yml` before.

```console
site-root$ cd _posts
site-root/_posts$ mkdir en zh
site-root/_posts$ ls
en  zh
```

Then, under each directory, create a file with name format
`YEAR-MONTH-DAY-title.MARKUP`, as explained
[here](https://jekyllrb.com/docs/posts/#creating-posts). For each file, the
front matter should include a variable `lang`, whose value is the language code
for this post.

```console
site-root/_posts$ ls *
en:
2020-04-26-test-post.md

zh:
2020-04-26-test-post.md
site-root/_posts$ cat en/2020-04-26-test-post.md
---
layout: default
title: "Test Post"
lang: en
---

This is a test post.
site-root/_posts$ cat zh/2020-04-26-test-post.md
---
layout: default
title: "测试帖"
lang: zh
---

此为测试帖
```

Now, go back to your site's root directory, and run `bundle exec jekyll build`
to build your site.

```console
site-root/_posts$ cd ..
site-root$ bundle exec jekyll build
Configuration file: site-root/_config.yml
            Source: site-root
       Destination: site-root/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
                    done in 0.055 seconds.
 Auto-regeneration: disabled. Use --watch to enable.
```

Your site is generated under the `_site` directory by default. It should have a
structure similar to this:

```
_site
├── 2020
│   └── 04
│       └── 26
│           └── test-post.html
├── assets
│   └── css
│       └── main.css
├── index.html
└── zh
    ├── 2020
    │   └── 04
    │       └── 26
    │           └── test-post.html
    └── index.html
```

By examing the generated HTML files for the posts, we can see that Polyglot
works! (The actual contents of the generated files depend on your theme)

```console
site-root$ cat _site/2020/04/26/test-post.html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="utf-8">
    <title>Test Post - My Site</title>
    <link rel="stylesheet" href="/assets/css/main.css">
  </head>
  <body>
    <p>This is a test post.</p>

  </body>
</html>
site-root$ cat _site/zh/2020/04/26/test-post.html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="utf-8">
    <title>测试帖 - My Site</title>
    <link rel="stylesheet" href="/assets/css/main.css">
  </head>
  <body>
    <p>此为测试帖</p>

  </body>
</html>
```

You can serve your site with `bundle exec jekyll serve`. By default, it is
accessible from `http://localhost:4000/`. Append the path to one of the HTML
files relative to `_site` after this URL to view the rendered webpage. In my
example, I would visit `http://localhost:4000/2020/04/26/test-post.html` and
`http://localhost:4000/zh/2020/04/26/test-post.html`.

You might have noticed that there is still imperfection in the generated
HTML files. The webpage's title is only partially localized: our site's
title is not translated. We will fix these issues in the upcoming sections.
