---
title: "在 GitHub Pages 上托管网站"
ordinal: 60
lang: zh
toc: true
---
{% include img-path.liquid %}
完成上述改进后，您的网站从内容到网页元素都支持了本地化，可以准备发布了。对于 Jekyll 网站而言，许多人都喜欢使用 [GitHub
Pages](https://pages.github.com/) 来托管，但是我们的多语言 Jekyll 网站如果想在 GitHub Pages 上托管的话需要一些特殊的步骤。这部分将要介绍的就是如何解决您在 GitHub Pages 上托管您的网站时可能遇到的一些问题。

## 不支持的 Jekyll 插件

如果您想让 GitHub Pages 直接自动构建并托管您的 Jekyll 网站，那么该网站不能使用不在[此列表](https://pages.github.com/versions/)上的插件。此篇文章被撰写之时，Polyglot 是不在该列表上的，意味着其不受 GitHub Pages 支持。这种情况下，GitHub Pages 的[帮助文章](https://help.github.com/en/github/working-with-github-pages/about-github-pages-and-jekyll#plugins)推荐先在本地构建网站的静态文件，然后直接将静态文件——而不是 Jekyll 源文件——上传到 GitHub。

尽管如此，“本地”并不一定必须是您自己的电脑。GitHub 上有许多持续集成（CI）服务的支持，所以您可以选择一个 CI 服务作为“本地”来构建您的 Jekyll 网站。CI 都支持在您向 GitHub 推送了新的提交后自动运行 Jekyll 网站的构建，并且在构建结束后，可以将生成的静态文件发布到您指定的位置。

您的工作流程不会因为使用 CI 受到太大的影响。假设您不需要使用 GitHub Pages 不支持的插件，您的 Jekyll 网站就可以直接被 GitHub Pages 构建。当您修改完您的网站的源文件后，会创建新的提交推送给 GitHub，然后 GitHub Pages 就会构建并发布您的网站。如果使用 CI 的话，您还是可以正常地提交和推送更改。此时 CI 检测到您推送了新的提交，在配置正确的情况下也是可以构建并发布您的网站的。换言之，除了网站的构建者发生了变化外，其它的流程都是一样的。

如果是以前的话，我可能会用 [Travis CI](https://travis-ci.org/) 来完成这一任务；现在 GitHub 有了 [Actions](https://github.com/features/actions)，同样有一定的 CI 功能。因为是 GitHub 本身自带的工具，所以我就选用了它。

## 配置 GitHub Actions 流程

一个 GitHub Actions 流程会指定完成一系列任务的具体步骤。如果要用 GitHub Actions 的话，我们要做的就是写一个构建 Jekyll 网站并将生成的静态文件发布到 GitHub 的流程。创建流程的第一件事是在您网站的 Git 仓库下的根目录创建一个 `.github/workflows` 文件夹。每个流程对应该文件夹下的一个 YAML 文件，在该文件中定义有关的规则、环境、步骤、以及要运行的命令。

### 创建流程

您可以从[此处](https://github.com/actions/starter-workflows/blob/abf7f258d1d84c79ad067c704e069c8cf7d8d2d0/ci/jekyll.yml)的文件入手创建一个构建 Jekyll 网站的 GitHub Actions 流程。将该文件的内容复制到 `.github/workflows` 下的一个 YAML 文件中，然后进行自定义。

{% raw %}
```yml
name: Jekyll site CI

on:
  push:
    branches: [ $default-branch ]
  pull_request:
    branches: [ $default-branch ]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - name: Build the site in the jekyll/builder container
      run: |
        docker run \
        -v ${{ github.workspace }}:/srv/jekyll -v ${{ github.workspace }}/_site:/srv/jekyll/_site \
        jekyll/builder:latest /bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"
```
{% endraw %}

这里有几个比较重要的选项：

- `on`：定义此流程在什么条件下会被触发。

- `jobs`: 此流程的一项任务。要了解更多信息的话可以参阅[此处](https://help.github.com/en/actions/getting-started-with-github-actions/core-concepts-for-github-actions#job)。需要注意的一点是，每项任务都是独立隔离执行的，任务之间不能互相访问彼此的文件。

- `steps`: 一项任务中的一个具体步骤。这里总共使用了两种不同的步骤：

  1. 用 `uses` 属性指定的现成的动作。这类步骤的代码和脚本都是其他人写完包装好后在 GitHub Actions 上发布的。比如，此处使用的 `actions/checkout@v2` 就是在[这里](https://github.com/marketplace/actions/checkout)发布的动作，可供所有人使用。它的作用是将您的 Git 仓库下载到运行此流程的虚拟机实例中。

  2. 用 `run` 属性指定的用户自定义的命令。这类步骤会直接在虚拟机实例中运行。

如果不作任何修改、直接使用的话，上面的流程会下载您 GitHub 上的仓库，从 [`jekyll/builder` Docker 映像](https://hub.docker.com/r/jekyll/builder) 创建一个 Docker 容器，然后在该容器中使用下载的文件构建您的网站。因为我们还想将构建好的网站发布，所以需要再加一个将生成的静态文件推送到 GitHub 的**步骤**。这里加的必须是一个步骤 `step` 而不是任务 `job`，因为任务之间是彼此隔离的，`build` 任务构建好的文件是没法被其它任务访问的。新加的步骤要做的就是把生成的静态文件发布到 GitHub 上。

### 输入默认分支的名称

在上面的配置文件中，您应该将所有 `$default-branch` 都替换为您的 Git 仓库的默认分支的名字。分支想叫什么名字都可以；在下面的示例中，我将使用 `jekyll` 作为默认分支的名称。

```diff
  on:
    push:
-     branches: [ $default-branch ]
+     branches: [ jekyll ]
    pull_request:
-     branches: [ $default-branch ]
+     branches: [ jekyll ]
```

### 添加上传网站的步骤

假如您没有使用不受支持的 Jekyll 插件，因此可以直接将您网站的静态文件上传到 GitHub，然后让 GitHub Pages 构建网站的话，您是永远不会直接看到您的网站的静态文件的。如果想用 GitHub Actions 达到同样的效果的话，我们应该避免将 GitHub Actions 流程构建的静态文件上传到 Git 仓库的默认分支，这样默认分支里就只有源文件了。

如果想达到这样的效果的话，最直接的方式就是新建一个 `gh-pages` 分支，在里面存放构建过程中生成的静态文件，然后让 GitHub Pages 从该分支发布网站。您的网站的源文件依旧在默认分支中，因此有人下载您的 Git 仓库时，默认签出的就是只存放源文件的分支。只要不在本地签出 `gh-pages` 分支，就看不到生成的静态文件。

如果您熟悉 Docker 和它的命令行的话，您可以注意到上面的流程中的 `docker` 命令会将 `github.workspace` 变量对应的路径（也就是您的 Git 仓库的根目录）中的 `_site` 文件夹挂载到网站构建过程中 Docker 容器内的 `_site` 文件夹。这就意味着在构建完成后，可以在 {% raw %}`${{ github.workspace }}/_site`{% endraw %} 下找到构建过程中创建的网站静态文件。因此，理论上来说，使用下列的一系列命令就可以将构建完成后 `_site` 文件夹中的内容发布到 `gh-pages` 分支中：

{% raw %}
```sh
cd ${{ github.workspace }}/_site
git init -b gh-pages
git remote add origin https://github.com/${{ github.repository }}.git
git add .
git commit -m "Deploy site built from commit ${{ github.sha }}"
git push -u origin gh-pages
```
{% endraw %}

然而，这些命令存在着如下问题：

- `_site` 文件夹是在 Docker 容器内创建的，而 Docker 容器中的 Linux 用户的用户 ID 和运行 GitHub Actions 流程的虚拟机实例的用户 ID 可能不同，因此可能会出现文件权限问题。所以，我们需要获取该文件夹的权限。下面的例子中，我们将通过使用 `chown` 修改文件拥有者的方式来获取权限，这样可以维持生成的静态文件原有的权限设置。

- 运行 GitHub Actions 流程的虚拟机实例中的 Git 用户名和邮箱默认是没有被设置的，将会影响 `git commit` 的运行。

- 因为要发布文件到 GitHub 上，所以需要设置 GitHub 登录凭据。

- 如果直接在 `_site` 文件夹下创建新的 Git 仓库的话，新创建的仓库是没有提交历史的，所以我们在虚拟机实例中创建的提交会和 GitHub 上已有的提交历史无关，影响网站的发布。解决的方法就是添加 `-f` 选项，强制推送新的提交。

要解决上述的问题的话，我们需要添加一些额外的命令，并对一些现有的命令进行调整：

{% raw %}
```diff
+ sudo chown $( whoami ):$( whoami ) ${{ github.workspace }}/_site
  cd ${{ github.workspace }}/_site
  git init -b gh-pages
+ git config user.name ${{ github.actor }}
+ git config user.email ${{ github.actor }}@users.noreply.github.com
- git remote add origin https://github.com/${{ github.repository }}.git
+ git remote add origin https://x-access-token:${{ github.token }}@github.com/${{ github.repository }}.git
  git add .
  git commit -m "Deploy site built from commit ${{ github.sha }}"
- git push -u origin gh-pages
+ git push -f -u origin gh-pages
```
{% endraw %}

通过在 GitHub 的域名前添加 {% raw %}`x-access-token:${{ github.token }}`{% endraw %}，我们可以使用令牌来验证 Git 操作。`github.token` 可用于获取一个 GitHub Actions 在运行流程前临时创建的令牌，使用该令牌进行验证即可拥有对 GitHub 上的仓库的控制权限。它和 `GITHUB_TOKEN` 差不多，后者的信息可以在[此处](https://help.github.com/en/actions/configuring-and-managing-workflows/authenticating-with-the-github_token)查看。

写好所有发布网站所需要的命令后，我们就可以把它们添加到流程配置文件中了：

{% raw %}
```yml
    steps:
    - uses: actions/checkout@v2
    - name: Build the site in the jekyll/builder container
      run: |
        docker run \
        -v ${{ github.workspace }}:/srv/jekyll -v ${{ github.workspace }}/_site:/srv/jekyll/_site \
        jekyll/builder:latest /bin/bash -c "chmod 777 /srv/jekyll && jekyll build --future"
    - name: Push the site to the gh-pages branch
      run: |
        sudo chown $( whoami ):$( whoami ) ${{ github.workspace }}/_site
        cd ${{ github.workspace }}/_site
        git init -b gh-pages
        git config user.name ${{ github.actor }}
        git config user.email ${{ github.actor }}@users.noreply.github.com
        git remote add origin https://x-access-token:${{ github.token }}@github.com/${{ github.repository }}.git
        git add .
        git commit -m "Deploy site built from commit ${{ github.sha }}"
        git push -f -u origin gh-pages
```
{% endraw %}

## 防止您的网站被未经授权地修改

这个流程仍然有一处致命的缺陷。它可以被 pull request 触发，而由于只要构建成功，它就会无条件地将构建好的网站发布，其他人就可以仅凭一个 pull request 修改并覆写您的网站。

首先，所有人都可以 fork 一份您的网站的仓库，在他们自己的 fork 中修改您网站的内容，然后向您发一个 pull request，同时触发 GitHub Actions 流程。该流程会使用他们修改过的网站源文件来生成静态文件，然后只要构建成功，还未等到您接受他们的 pull request，包含他们所做的修改的静态文件就会被发布到您的网站上。这样的最好结果是别人替您修正了一处录入错误，不需要等您接受他们的 pull request 就可以修正您网站上的内容，但最坏的后果则是别人写一些有害的内容，然后给您发了 pull request。

为防止这类修改，我们可以给将网站上传到 `gh-pages` 的步骤添加条件，只有因 `jekyll` 分支有新的提交触发此流程时才运行该步骤。

{% raw %}
```diff
      - name: Push the site to the gh-pages branch
+       if: ${{ github.event_name == 'push' }}
        run: |
          sudo chown $( whoami ):$( whoami ) ${{ github.workspace }}/_site
          cd ${{ github.workspace }}/_site
          git init -b gh-pages
```
{% endraw %}

对于任何其它类型的事件，包括 pull request，这一步骤就会被跳过，构建好的网站也就不会被发布到 `gh-pages` 分支上。

![将网站发布到 gh-pages 分支的步骤被略过]({{ img_path }}/push-not-performed.png)

到此，您就做好了一个类似于[我使用的流程](https://github.com/Leo3418/leo3418.github.io/blob/702a9f5325504606b405ac02086cc2b7940e84d4/.github/workflows/jekyll.yml)的配置文件。有了可以自动构建并发布 Jekyll 网站的 GitHub Actions 流程后，您就可以在您的网站上使用不支持的插件了。

## 选择 GitHub Pages 的发布源

整套操作的最后一部是告诉 GitHub Pages 使用您的 Git 仓库的 `gh-pages` 分支中的文件来发布网站。首先，提交您的 GitHub Actions 流程配置文件，将其推送至 GitHub，然后让该流程运行一次，以构建您的网站并上传到 `gh-pages` 分支。

接着，在 GitHub 网站上，打开您的仓库的设置，然后向下找到名为“GitHub Pages”的部分，在“Source”的“Branch”中选择 `gh-pages`，然后点击“Save”保存。

![选择 GitHub Pages 的发布源]({{ img_path }}/gh-pages-source.png)
