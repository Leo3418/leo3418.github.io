---
title: "配置 Polyglot"
ordinal: 30
lang: zh
---

配置 Polyglot 的第一步是安装它，安装操作和普通的 Jekyll 插件是一样的，没有什么特别之处。Polyglot 的 gem 叫做 `jekyll-polyglot`。

以下是几种常见的安装 Jekyll 插件的方法：

1. 直接将插件的 gem 名称加入网站的 `Gemfile` 文件当中：

   ```ruby
   gem "jekyll-polyglot"
   ```

   然后在 `_config.yml` 中启用插件：

   ```yml
   plugins:
     - jekyll-polyglot
   ```

   最后再运行一下 `bundle install` 即可。

   如果您要在不同的机器和环境中编辑、构建和维护您的网站，比如说好几台电脑上，您自己的电脑和一台服务器，或者自己的电脑和 CI 环境这些场景，那么推荐使用这种方法安装插件。

2. 在 `Gemfile` 里新建一个名叫 `:jekyll_plugins` 的 Bundle 组，然后在其中加入插件的名称：

   ```ruby
   group :jekyll_plugins do
       gem "jekyll-polyglot"
   end
   ```

   如果采用这种方法的话，就不需要修改 `_config.yml` 了，直接运行 `bundle install` 就可以完成安装。

   用这种方法需要注意的一点是，即使使用 `--safe` 参数以安全模式启动 Jekyll，以此法安装的插件仍然会被加载。

3. 仅在 `_config.yml` 中注册插件：

   ```yml
   plugins:
     - jekyll-polyglot
   ```

   然后使用 `gem install jekyll-polyglot` 命令安装。

   这种安装方式的缺点是，您在别的机器上运行 `bundle` 的时候不会自动安装插件，必须重新运行 `gem` 命令才能安装。

安装好插件后，在 `_config.yml` 中加入 Polyglot 的配置选项：

```yml
languages: ["en", "zh"]
default_lang: "en"
exclude_from_localization: ["assets/css", "assets/img"]
parallel_localization: true

sass:
  sourcemap: never
```

最开始的四行是 Polyglot 的选项：

- `languages` 是包含您网站支持的语言的数组；语言使用 [ISO 639-1 代码](https://zh.wikipedia.org/wiki/ISO_639-1%E4%BB%A3%E7%A0%81%E8%A1%A8)表示。

- `default_lang` 是您网站的默认语言的语言代码。

- `exclude_from_localization` 是所有不需要本地化的文件路径的数组。建议至少在这里加入您网站存放图片的路径，这样就不需要为每种语言都单独复制一份图片了，节省空间。

- `parallel_localization` 用于设定在生成网站时是否多线程并发生成。根据 [Polyglot 文档](https://github.com/untra/polyglot/blob/1.3.2/README.md#compatibility)的描述，在 Windows 上可能需要把此选项设为 `false`。

至于 `sass.sourcemap` 选项，是 Polyglot 和 Jekyll 4.0 的一处不兼容 bug 的[临时解决方案](https://github.com/untra/polyglot/issues/107#issuecomment-598274075)。虽然我不知道那个 bug 到底是怎么回事，也不清楚添加这么一条设定会起什么效果，但我用这个选项有一段时间了，尚未遇到明显问题。
