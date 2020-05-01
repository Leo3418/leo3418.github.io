---
title: "Set Up Polyglot"
permalink: /collections/multilingual-jekyll-site/set-up-polyglot
ordinal: 30
lang: en
---

Just install Polyglot like a normal Jekyll plugin. Its gem name is
`jekyll-polyglot`.

There are several common ways to install a Jekyll plugin:

1. Directly add the plugin's gem name to the `Gemfile` for your site:

   ```ruby
   gem "jekyll-polyglot"
   ```

   Then, enable the plugin in `_config.yml`:

   ```yml
   plugins:
     - jekyll-polyglot
   ```

   Finally, run `bundle install`.

   I recommend this method if you plan to work on your site on different
   machines, e.g. multiple computers, your computer and a server, or your
   computer and a CI environment.

2. Create a Bundle group called `:jekyll_plugins` in the `Gemfile`, and add the
   plugin's gem name to it:

   ```ruby
   group :jekyll_plugins do
       gem "jekyll-polyglot"
   end
   ```

   With this method, you don't need to modify `_config.yml`, so just run
   `bundle install` directly.

   Keep in mind, the plugins you install in this way will always load even if
   you run Jekyll in `--safe` mode.

3. Register the plugin in only `_config.yml`:

   ```yml
   plugins:
     - jekyll-polyglot
   ```

   Then install it with `gem install jekyll-polyglot`.

   A drawback of this method is your plugins won't be automatically installed
   if you set up your site from another machine with `bundle`: you should run
   the `gem` command again for plugins.

After plugin installation, add configuration options for Polyglot to
`_config.yml`:

```yml
languages: ["en", "zh"]
default_lang: "en"
exclude_from_localization: ["assets/css", "assets/img"]
parallel_localization: true

sass:
  sourcemap: never
```

The first four lines are just normal Polyglot preferences:

- `languages` is an array of [ISO 639-1
  codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) for the
  languages your site supports.
- `default_lang` is the code for your site's default language.
- `exclude_from_localization` is an array of directories where the files should
  be commonly shared for all languages. I suggest you at least add the
  directory for your site's images here, so the images will not be copied for
  every localized version of your site during site generation, saving disk
  spaces.
- `parallel_localization` indicates whether localization is run parallel during
  site generation. According to [Polyglot's
  documentation](https://github.com/untra/polyglot#compatibility), if you are
  building your site on Windows, you might need to set this to `false`.

The `sass.sourcemap` option is a
[workaround](https://github.com/untra/polyglot/issues/107#issuecomment-598274075)
for Polyglot's issue with Jekyll 4.0. To be honest, I don't really understand
what that issue is, but including that option in my configuration has not
caused any problems yet.
