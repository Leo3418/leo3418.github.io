---
title: "避免创建纯 `-9999` Gentoo 软件包"
tags:
  - Gentoo
categories:
  - 教程
toc: true
---

有些 Gentoo 软件包会提供一个特殊的 `9999` 版本：按照惯例，如果一个 ebuild 的版本是 `9999`，那么它就是一个*实时 ebuild*，构建软件包时使用的是该软件项目的版本控制系统仓库（例如 Git 仓库）中的最新“实时”源码，而非来自 `.zip` 或 `.tar.*` 压缩包的“非实时”源码。版本控制系统仓库中的项目源码经常会被修改，故被称作“实时”源码。

当一个软件包只有一个实时 ebuild、没有任何非实时 ebuild 的时候，我会称之为“纯 `-9999` 软件包”，因为该软件包唯一的 ebuild 的版本一般是 `9999`。**请避免创建纯 `-9999` 软件包**。换言之，**一个实时 ebuild 不应成为某个软件包的唯一 ebuild**。

有些软件包的上游压根就不发布版本，给这种软件包编写非实时 ebuild 看起来是办不到的。然而，事实通常并非如此：即使上游没有发行任何版本，通常也仍然可以写出从固定的“非实时”源码编译该软件包的 ebuild。本文将讨论一种此情况下可以采取的应对方法。

本文中的“软件包维护者”指的是为软件包编写并管理 ebuild 的人员。对于编写并管理软件包本身的源码的人员，本文将使用“软件包上游”的称谓。
{.notice--info}

## 纯 `-9999` 软件包的主要问题

用户需要在 `/etc/portage/package.accept_keywords` 中多输入两个星号（`**`），才能安装纯 `-9999` 软件包[^live-keywords]——但这还只是纯 `-9999` 软件包的一个小问题。纯 `-9999` 软件包不仅会给用户造成更多的不便，还可能反伤维护者，导致双输的局面。

[^live-keywords]:
    一般情况下，用户想安装某个实时 ebuild 的话，必须向 `/etc/portage/package.accept_keywords` 中添加下列内容：

    ```
    games-emulation/dosbox-x **
    ```

    而只想安装某个软件包的不稳定版本（和 `9999` 版本有区别）的用户，只需要添加下列内容，即省去结尾的两个星号：

    ```
    games-emulation/dosbox-x
    ```

    这两个星号在安装 `KEYWORDS` 为空的 ebuild 时是必需的，而实时 ebuild 的 `KEYWORDS` 都是空的（<https://devmanual.gentoo.org/ebuild-writing/functions/src_unpack/vcs-sources/>）。

### 软件包易受源码仓库中的改动的影响

软件包上游随时都可能更新版本控制系统仓库中的源码，而任何的改动都可能导致新问题的出现：昨天某样东西还能正常工作，但今天可能就不能用了。遗憾的是，“昨天还能用、今天就不能用了”也可能发生在实时 ebuild 上。

- 如果上游对软件包的构建系统作出了不兼容的修改，那么软件包维护者就需要相应地更新实时 ebuild。如果实时 ebuild 未能被及时更新，那么用户在一段时间内都无法安装该软件包。

- 上游的代码修改还可能导致新的编译错误。此类错误可能无法通过更新 ebuild 解决，所以软件包维护者可能就需要依赖上游来解决问题。在上游修复问题前，软件包也会在一段时间内处于无法安装的状态。

从用户的角度而言，纯 `-9999` 软件包的可靠性往往不好。如果实时 ebuild 因为上述原因无法安装了，那么用户因为没有其它的 ebuild 可以试，所以压根没法安装该软件包。如果一个软件包经常无法安装，那么它很难称得上可靠。

从维护者的角度而言，保证纯 `-9999` 软件包的高可用性[^pkg-availability]就算可行，也需要更多的维护精力：当上游的修改引入了新问题时，维护者必须立刻更新实时 ebuild 才能保持整个软件包的可用性。

给软件包加一个非实时 ebuild 就可以解决上述所有问题，从而同时造福用户和维护人员。非实时 ebuild 实际上本身对于上述问题就是免疫的，因为它总是从同样的源码构建软件包。

[^pkg-availability]:
    可用性的概念通常只应用在可运行的系统上，毕竟它是通过系统正常运行时长和系统不可用的时长定义的；据我了解，这一概念一般并不会应用在软件发行流程中的软件包上。不过，我愿将软件包的可用性定义为：软件包可被安装的时长除以软件包在软件仓库中被提供的时长。

### 用户不一定能轻松降级软件包

当某个软件包的新版本无法正常工作或出现回退时，用户可能会选择暂时回滚到上一个版本。而纯 `-9999` 软件包并不一定支持降级，故可能导致用户被困在有问题的版本上。

假设有一实时 ebuild，从 Git 仓库下载软件包的源码，故继承 `git-r3.eclass`。该软件包的上游并不遵循软件开发的最佳实践：他们的提交经常都很大、没有原子性、一次改很多文件，而他们最近的一个提交就同时作出了以下改动：
- 将软件包的构建系统从 GNU Autotools 换成了 Meson
- 对软件包的源码进行了数项优化，但不巧的是，这些优化存在问题，会导致新的运行时 bug

为了响应这些改动，该软件包的维护者更新了实时 ebuild，让其继承 `meson.eclass` 而非 `autotools.eclass`。

该软件包的用户听说了关于最新的优化的消息，决定体验一下最新的版本，于是他们同步了 ebuild 仓库，重新构建了该软件包。很快，他们就留意到了新的运行时 bug，并失望地发现这些 bug 导致该软件包基本上无法使用。于是，他们选择暂时回滚到上个版本，直到上游修复这些 bug。

有经验的用户可能知道有一个 `EGIT_OVERRIDE_COMMIT_*` 变量，是 `git-r3.eclass` 提供的，在构建输出中有提示，看起来可以派上用场：

```plain {hl_lines=6}
>>> Unpacking source...
 * Repository id: joncampbell123_dosbox-x.git
 * To override fetched repository properties, use:
 *   EGIT_OVERRIDE_REPO_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_BRANCH_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_COMMIT_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_COMMIT_DATE_JONCAMPBELL123_DOSBOX_X
```

于是，他们在该软件包的 Git 仓库中找到了上述的大型提交的前一个提交的 SHA-1 散列值，然后相应设定了 `EGIT_OVERRIDE_COMMIT_*` 的值，以尝试安装不受新出现的 bug 影响的旧版本。

不幸的是，这番操作并不会管用。用来构建并安装旧版本的 ebuild 仍然是新的 ebuild，而新的 ebuild 已经适配 Meson 了，不再支持 GNU Autotools。然而，旧版本的构建系统仍然是 GNU Autotools。因此，旧版本的构建会直接失败。用户也就被困在了存在问题的最新版本上。他们如果想通过此方法成功降级的话，就必须手动将旧的 ebuild 复原到本地的 ebuild 仓库副本下，但是手动复原 ebuild 的操作也是比较麻烦的。

如果该软件包有上一个版本的非实时 ebuild 的话，用户就可以直接安装该 ebuild，轻松完成回滚。回滚操作只需要使用 `emerge` 即可完成，不需要在本地的 ebuild 仓库副本下进行任何修改。

### 默认情况下无法离线重新构建软件包

用户可能遇到恰巧需要在离线状态下重新构建一个纯 `-9999` 软件包的情况，然而他们在真正遇到这种情况时可能会发现自己束手无策。离线重新构建实时 ebuild 需要额外的配置，而并非所有用户都能够在离线时找出具体需要什么配置。

强制离线重新构建实时 ebuild 的方法是：在 Portage 配置文件或环境中，将 `EVCS_OFFLINE` 变量的值设为非空字符串。例如：

```console
# EVCS_OFFLINE=1 emerge --ask --oneshot ~games-emulation/dosbox-x-9999
```

因为这个解决方法很简单、很直接，所以这个问题看起来可能是小菜一碟、不足挂齿。但是，这个解决方法对于用户来说不一定能那么容易发现，尤其是在上不了网的情况下。假设用户需要在离线时重新构建一个继承了 `git-r3.eclass` 的 ebuild。当系统处于离线状态时，`git-r3.eclass` 的错误信息里并不会提及 `EVCS_OFFLINE`，因此用户无法通过错误信息知晓该解决方法。然而，该错误信息可能是用户在无法上网搜索解决方法时唯一的救命稻草。所以，用户到最后可能仍不知道该怎么做，只能干瞪着错误信息、一筹莫展。

```
>>> Unpacking source...
 * Repository id: joncampbell123_dosbox-x.git
 * To override fetched repository properties, use:
 *   EGIT_OVERRIDE_REPO_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_BRANCH_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_COMMIT_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_COMMIT_DATE_JONCAMPBELL123_DOSBOX_X
 *
 * Fetching https://github.com/joncampbell123/dosbox-x.git ...
git fetch https://github.com/joncampbell123/dosbox-x.git +HEAD:refs/git-r3/HEAD
fatal: unable to access 'https://github.com/joncampbell123/dosbox-x.git/': Could not resolve host: github.com
 * ERROR: games-emulation/dosbox-x-9999::guru failed (unpack phase):
 *   Unable to fetch from any of EGIT_REPO_URI
 *
 * Call stack:
 *     ebuild.sh, line  136:  Called src_unpack
 *   environment, line 2396:  Called git-r3_src_unpack
 *   environment, line 1941:  Called git-r3_src_fetch
 *   environment, line 1935:  Called git-r3_fetch
 *   environment, line 1857:  Called die
 * The specific snippet of code:
 *       [[ -n ${success} ]] || die "Unable to fetch from any of EGIT_REPO_URI";
 *
 * If you need support, post the output of `emerge --info '=games-emulation/dosbox-x-9999::guru'`,
 * the complete build log and the output of `emerge -pqv '=games-emulation/dosbox-x-9999::guru'`.
 * The complete build log is located at '/var/tmp/portage/games-emulation/dosbox-x-9999/temp/build.log'.
 * The ebuild environment file is located at '/var/tmp/portage/games-emulation/dosbox-x-9999/temp/environment'.
 * Working directory: '/var/tmp/portage/games-emulation/dosbox-x-9999/work'
 * S: '/var/tmp/portage/games-emulation/dosbox-x-9999/work/dosbox-x-9999'
```

虽然确实有在离线的系统上找出有关 `EVCS_OFFLINE` 变量的信息的方法，但是并不能安全地假设所有人都能有效利用这些方法。比如，用户可以通过阅读 `/var/db/repos/gentoo/eclass` 下的版本控制系统 eclass 的源代码来发现 `EVCS_OFFLINE`。然而，并非所有人都有解读 eclass 源代码的能力。有些用户可能甚至都不知道 eclass 是什么。

非实时 ebuild 的离线重新构建就不需要用户进行任何特殊操作：在默认 Portage 配置下，只要软件包的 USE 标志不变，用户就可以直接离线重新构建非实时 ebuild，不需要任何特殊的设置。该 ebuild 首次被构建安装时，它所使用的源文件会被下载并保存到 Portage 的 *DISTDIR* 目录下（默认为 `/var/cache/distfiles`）。在重新构建该 ebuild 时，之前保存的源文件*默认*就能被重新利用，而只要 USE 标志不变，就没有新文件需要下载，因此用户不需要任何额外配置就可以离线重新构建非实时 ebuild。实时 ebuild 虽然*可以*重新利用之前下载的源文件，但正如上所述，默认情况下并不会重新利用它们，导致纯 `-9999` 软件包会在离线情况下给经验不足的用户造成困扰。

### `eclean-dist` 无法清理软件包的无用文件

[`eclean-dist`] 是 `app-portage/gentoolkit` 中的清理 *DISTDIR* 下无用的软件包源文件的工具。当用户卸载了某个软件包、或一次系统更新清除了某个软件包的旧版本后，`eclean-dist` 可将被清除的软件包版本的源文件从 *DISTDIR* 中删除，从而节省空间。

但是，`eclean-dist` 无法清理由实时 ebuild 下载的无用源文件。`eclean-dist` 只能清理 *DISTDIR* 下的普通文件，无法清理子目录。然而，给实时 ebuild 使用的版本控制系统 eclass 都会将源文件下载到 *DISTDIR* 下的子目录中：

- `bzr.eclass`: [`${DISTDIR}/bzr-src/`]
- `cvs.eclass`: [`${DISTDIR}/cvs-src/`]
- `git-r3.eclass`: [`${DISTDIR}/git3-src/`]
- `golang-vcs.eclass`: [`${DISTDIR}/go-src/`]
- `mercurial.eclass`: [`${DISTDIR}/hg-src/`]
- `subversion.eclass`: [`${DISTDIR}/svn-src/`]

因此，用户在卸载了一个纯 `-9999` 软件包后，需要手动删除上列目录下的软件包源文件，才能清理出额外空间。`eclean-dist` 无法为用户自动清理纯 `-9999` 软件包残留的文件。

虽然这个问题在任何软件包的实时 ebuild 上都存在，但对于那些提供至少一个非实时 ebuild 的软件包来说，用户是可以选择安装一个非实时 ebuild 的，同样能使用该软件包，并且 `eclean-dist` 也可以自动为用户清理该软件包的残留文件。如果是纯 `-9999` 软件包，想使用它的用户就只能被迫安装实时 ebuild，也就无法使用 `eclean-dist` 清理该软件包的残留文件。

[`eclean-dist`]: https://wiki.gentoo.org/wiki/Knowledge_Base:Remove_obsoleted_distfiles#Resolution
[`${DISTDIR}/bzr-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/bzr.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n33
[`${DISTDIR}/cvs-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/cvs.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n97
[`${DISTDIR}/git3-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/git-r3.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n85
[`${DISTDIR}/go-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/golang-vcs.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n45
[`${DISTDIR}/hg-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/mercurial.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n50
[`${DISTDIR}/svn-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/subversion.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n31

### GURU 中的软件包：无法受益于 Tinderbox 的自动测试

[GURU] 是具 Gentoo 官方性质、由用户维护的 ebuild 仓库。GURU 中的软件包可被由 Gentoo 开发者 Agostino 配置的 [tinderbox] 系统自动测试。（该 tinderbox 系统同时也测试 Gentoo 仓库中的软件包。）如果 tinderbox 检测到某一软件包中存在诸如构建失败、测试失败、或 QA 警告等问题，它会自动在 Gentoo Bugzilla 上将该问题报告给该软件包的维护者。

但是，tinderbox 并不能报告纯 `-9999` 软件包的问题。Tinderbox 的测试并不涵盖实时 ebuild——确实可以理解，毕竟正如上文中所讨论的，实时 ebuild 随时都可能无法正常构建，甚至可能在 tinderbox 测试它之前就不能构建了。纯 `-9999` 软件包因为没有可供 tinderbox 测试的非实时 ebuild，所以整个软件包都不在 tinderbox 自动测试的覆盖范围内。

Tinderbox 可以让软件包维护者发现在他们自己的测试环境下不会出现的问题。像 tinderbox 曾经给我维护的 GURU 软件包报告的几个问题，当时我在我自己的测试环境下就没有发现。如果没有 tinderbox 的报告，我对这些问题就全然不知。

- [Bug 833823][#833823]：`DEPEND` 中缺少测试依赖 `gui-libs/gtk:4`。在我当时测试这个 ebuild 所使用的环境中，`gui-libs/gtk:4` 是早就安装了的，因此即使该测试依赖没有在 ebuild 中明确声明，测试在本地也通过了。但当 tinderbox 在没有提前安装 `gui-libs/gtk:4` 的环境中测试该 ebuild 时，因为缺少依赖，测试就失败了。

- [Bug 859973][#859973]：LTO 导致软件包构建失败。在使用了 LTO 编译器选项时，该软件包会导致编译错误。我当时还从没试过在启用 LTO 时构建该软件包，因此直到收到 tinderbox 的问题报告前，我对此问题都毫不知情。

为充分享受 tinderbox 的自动软件包测试带来的好处，建议 GURU 贡献者考虑为其维护的所有纯 `-9999` 软件包都添加非实时 ebuild。

[GURU]: https://wiki.gentoo.org/wiki/Project:GURU
[tinderbox]: https://blogs.gentoo.org/ago/2020/07/04/gentoo-tinderbox/
[#833823]: https://bugs.gentoo.org/833823
[#859973]: https://bugs.gentoo.org/859973

## 改进纯 `-9999` 软件包

解决纯 `-9999` 软件包的问题的方法很简单：为其加一个非实时 ebuild，这样它就不再是纯 `-9999` 软件包了。就算软件包的上游从来不发布版本，创建非实时 ebuild 仍然是可行的。

### 创建非实时 ebuild

在创建非实时 ebuild 时，通常可以通过修改已有的实时 ebuild 入手——只需要对实时 ebuild 进行少数改动，就能得到可以使用的非实时 ebuild 了。

假设该实时 ebuild 继承 `git-r3.eclass`，那么它通常会包含类似于以下内容的代码：

```bash
inherit git-r3
EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
```

软件包维护者凭直觉可能会选择在非实时 ebuild 中把这两行代码直接删除，然后再定义 `SRC_URI`、`KEYWORDS`、以及 `S` 等变量：

{{% live-to-non-live.inline %}}
```diff
-inherit git-r3
-EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
+SRC_URI="https://github.com/joncampbell123/dosbox-x/archive/dosbox-x-v${PV}.tar.gz"
+S="${WORKDIR}/${PN}-${PN}-v${PV}"
+KEYWORDS="~amd64"
```
{{% /live-to-non-live.inline %}}

然而，**这样的修改并非最优解**。推荐的修改方案是：

1. 保留这两行来自实时 ebuild 的代码，将其添加到一个 `if` 语句块中（如下列样例所示）。

2. 将定义非实时 ebuild 的变量的代码加到紧跟着该 `if` 语句块的 `else` 语句块。

3. 将以此法得出的新代码**同时**添加到已有的实时 ebuild 和新的非实时 ebuild 中。

{{<div id="if-pv-eq-9999-then-code">}}
```bash
if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
else
	SRC_URI="https://github.com/joncampbell123/dosbox-x/archive/dosbox-x-v${PV}.tar.gz"
	S="${WORKDIR}/${PN}-${PN}-v${PV}"
	KEYWORDS="~amd64"
fi
```
{{</div>}}

为什么要写这么个 `if [[ ${PV} == 9999 ]]; then ...` 代码块？为什么要将这些代码同时添加到实时 ebuild 和非实时 ebuild 中？本文会在[后续章节][if-pv-eq-9999-then-reason]中解答这些问题。

[if-pv-eq-9999-then-reason]: {{<relref "#对于维护者">}}

### 如果上游发布版本

如果软件包的上游为其发布版本，那么创建非实时 ebuild 的流程就很明了：只要为该软件包的最新版本创建 ebuild 即可。

- 在 `SRC_URI` 中直接或间接使用 `PV`，以得出软件包源文件的 URI。

- 如果有必要的话，同样直接或间接使用 `PV` 来定义 `S` 变量的值。

- 如果上游在发布了最新版本后，又对软件包进行了大的改动，而已有的实时 ebuild 也是在这些改动之后才编写的，那么非实时 ebuild 可能还需要其它修改才能正常使用。

  例如，如果上游在发布了上个版本后，将软件包的构建系统从 GNU Autotools 迁移到了 Meson，而实时 ebuild 也是在构建系统迁移之后才做出来的（因此该实时 ebuild 使用 `meson.eclass`），那么非实时 ebuild 就需要继承 `autotools.eclass` 而非 `meson.eclass`，因为上个版本使用的构建系统仍然是 GNU Autotools。

### 如果上游不发布版本

如果软件包的上游从没有为其发布过版本，或者上游曾经发布过版本但已经很久不发新版本了，那么为该软件包编写非实时 ebuild 就会比较棘手：非实时 ebuild 的 `SRC_URI` 和 `PV` 应该是什么呢？这个问题的答案并不是很明显。

在这种情况下，通常仍然可以基于该软件项目的源码仓库快照的压缩包来制作非实时 ebuild。一个快照压缩包里面存储的是该仓库在某个特定的版次（revision）下包含的文件内容；这个版次不必有任何的标签，因此即使上游从来不创建标签、从来不发布版本，也没有任何影响。这样一来，该非实时 ebuild 的 `SRC_URI` 变量就可以使用快照压缩包的 URI。而该 ebuild 的 `PV` 则使用该快照对应的版次的日期来标识上游版本。

#### 确定快照压缩包的 URI 格式

首先，确认托管该软件包的源码仓库的网站支持下载任意版次的快照压缩包。然后，确认压缩包的下载链接 URI 符合以下条件：
- 该 URI 中包含被请求下载的版次。
- 将 URI 中的版次改为另一个版次后，得到的新 URI 也能够相应地下载该版次的快照压缩包。

下列所有网站都满足以上要求。为方便读者，每个网站的 URI 格式也一并列出。

- Codeberg：`https://codeberg.org/${OWNER}/${REPO}/archive/${COMMIT}.tar.gz`
- SourceHut，Git 仓库分站（git.sr.ht）：`https://git.sr.ht/~${OWNER}/${REPO}/archive/${COMMIT}.tar.gz`
- GitLab.com：`https://gitlab.com/${OWNER}/${REPO}/-/archive/${COMMIT}/${REPO}-${COMMIT}.tar.bz2`
- GitHub：`https://github.com/${OWNER}/${REPO}/archive/${COMMIT}.tar.gz`
- Bitbucket：`https://bitbucket.org/${OWNER}/${REPO}/get/${COMMIT}.zip`
- 自托管的 Gitea：`${BASE_URI}/${OWNER}/${REPO}/archive/${COMMIT}.tar.gz`
- 自托管的 GitLab：`${BASE_URI}/${OWNER}/${REPO}/-/archive/${COMMIT}/${REPO}-${COMMIT}.tar.bz2`

请将上列 URI 中的以下部分分别替换为对应的实际值：

- `${OWNER}`：拥有该仓库的用户名、群组名、或组织名等
- `${REPO}`：该仓库的名称
- `${COMMIT}`：该快照的版次的完整 SHA-1 散列值；其长度应为 40 个字符
- `${BASE_URI}`（仅限于自托管的版本控制系统服务）：该服务的根 URI （例：GNOME GitLab 的根 URI 是 `https://gitlab.gnome.org`）

#### 定义 `SRC_URI`

接着，就可以将快照压缩包的 URI 加到非实时 ebuild 的 `SRC_URI` 中了。软件包维护者可自由选择快照的版次，但最省事的选择是使用在当时制作实时 ebuild 时测试过的版次：这样一来，把实时 ebuild 变成可正常使用的非实时 ebuild 就不需要别的改动了。

```bash {hl_lines="5-7"}
if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
else
	GIT_COMMIT="982c44176e7619ae2a40b5c5d8df31f2911384da"
	SRC_URI="https://github.com/joncampbell123/dosbox-x/archive/${GIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${GIT_COMMIT}"
	KEYWORDS="~amd64"
fi
```

本样例中的代码定义了一个 `GIT_COMMIT` 变量，专门用于存储快照的版次。这样做有如下好处：
- ebuild 的代码可读性更好。
- 版次不需要在 `SRC_URI` 和 `S` 中重复。
- 后续的软件包版本更新会更容易，因为 `SRC_URI` 和 `S` 的值中会随版本更新而变动的部分被抽离到单独的变量中了，方便日后修改。

本样例中的代码还通过在 `SRC_URI` 中向快照压缩包的 URI 结尾添加 ` -> ${P}.tar.gz` 的方式，在下载压缩包时将其重命名为 `${P}.tar.gz`。快照压缩包的原始文件名大多都是像 `982c44176e7619ae2a40b5c5d8df31f2911384da.tar.gz` 这样的，会有以下潜在问题：

- 这样的文件名无法显示该压缩包对应的软件包名称或使用该压缩包的 ebuild 的 `PV`，不便于手动访问与管理 *DISTDIR* 下的软件包源文件。例如，有人可能想直接运行 `tar` 命令解压快照压缩包，以浏览软件包的源文件，并避免下载 Git 仓库，从而节省流量。如果快照压缩包没有被重命名，这个人就无法轻松地在 *DISTDIR* 下找到该压缩包。

- 如果两个不同软件包的快照压缩包所对应的版次编号恰巧是一样的，那么这两个压缩包就可能重名。如果它们都是 Git 仓库的快照，这种情况出现的几率很低，但理论上仍然可以发生。如果是两个 Subversion 仓库的快照，这种情况就更容易出现了，因为 Subversion 使用整数作为版次编号，而非 SHA-1 散列值。

#### 决定 `PV`

非实时 ebuild 的 `PV` 应包含其使用的快照版次的日期，且日期的格式应为 `YYYYMMDD`；这样的话，使用更新快照的 ebuild 的 `PV` 也会相应地更高。具体的 `PV` 格式，取决于软件包的上游在发行版本方面采取的具体行为：

- 如果上游从来就没给该软件包发布过任何版本：使用 `0_preYYYYMMDD` 的格式，如 `0_pre20230130`。

  这样一来，如果日后上游开始为该软件包发布版本，他们选择使用的版本号通常都会比 `0_preYYYYMMDD` 高[^fedora-pkg-no-ver]，届时用户也就能接收到上游版本的更新。根据 Gentoo 的[软件包管理器规范（PMS）][pms-ver-cmp]，以下 `PV` 变量的值都被视为比 `0_preYYYYMMDD` 高的版本：
  - `0`
  - `0.0_alpha`
  - `0.0`
  - `0.0.0_alpha`
  - `0.0.0`

  有一个会导致问题的 `PV` 的例子，即 `0_alpha`，因为它会被视为比 `0_preYYYYMMDD` 低的版本。对于这样的版本号，建议软件包维护者改用 `0.0_alpha` 作为 `PV`，然后在 ebuild 的代码中对 `PV` 的值进行操作，使其与上游的版本号吻合：

  ```bash {hl_lines="5-6"}
  if [[ ${PV} == 9999 ]]; then
  	inherit git-r3
  	EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
  else
  	MY_PV="${PV/.0/}" # 从 PV 中去除 '.0'，令 MY_PV="0_alpha"
  	MY_P="${PN}-${MY_PV}"

  	SRC_URI="https://github.com/joncampbell123/dosbox-x/archive/${MY_P}.tar.gz"
  	S="${WORKDIR}/${PN}-${MY_P}"
  	KEYWORDS="~amd64"
  fi
  ```

- 如果上游已经不再发布版本，并且在发布最后一个版本后，上游更新了软件包的源文件中的版本号：向更新后的版本号添加 `_preYYYYMMDD` 后缀，将得到的字符串作为 `PV`[^devmanual-snapshots]。

  例如，许多 Java 软件包的上游都喜欢在发布了一个新版本后马上更新软件包的版本号，比如[发布 `1.3`][sqlj-maven-plugin-1.3] 后立刻[将版本号更新为 `1.4-SNAPSHOT`][sqlj-maven-plugin-1.4-SNAPSHOT]。因为上游从没发布过 1.4 版本，所以可使用 `1.4_pre20170907` 作为该软件包的最新快照的 `PV`。

- 如果上游已经不再发布版本，并且在发布最后一个版本后，上游没有更新软件包的源文件中的版本号：向最后发布的版本号添加 `_pYYYYMMDD` 后缀，将得到的字符串作为 `PV`[^devmanual-snapshots]。

  一个经典的例子是 LuaJIT，虽然一直有开发活动，但已经超过 5 年没有新发布的版本了。在本文被撰写时（多半也是直到永远），[LuaJIT 发布的最后一个版本][luajit-tags]是 `v2.1.0-beta3`，并且其 Git 仓库中的 [Makefile 定义的软件包版本][luajit-makefile-ver]也仍然是 `2.1.0-beta3`。因此，可使用 `2.1.0_beta3_p20230104` 作为该软件包的最新快照的 `PV`。此 `PV` 格式也确实是 Gentoo 仓库中的 [`dev-lang/luajit` ebuild][gentoo-repo-luajit] 使用的格式。

[^fedora-pkg-no-ver]:
    https://docs.fedoraproject.org/zh_Hans/packaging-guidelines/Versioning/#_upstream_has_never_chosen_a_version

[^devmanual-snapshots]:
    https://devmanual.gentoo.org/ebuild-writing/file-format/#snapshots-and-live-ebuilds

[pms-ver-cmp]: https://projects.gentoo.org/pms/8/pms.html#x1-260003.3
[sqlj-maven-plugin-1.3]: https://github.com/mojohaus/sqlj-maven-plugin/commit/0c61613e43645d39607b7091172a2f0a28d677c6
[sqlj-maven-plugin-1.4-SNAPSHOT]: https://github.com/mojohaus/sqlj-maven-plugin/commit/4946ad9d0cdb68fe9a7bfe9c21d93e04f20a8b36
[luajit-tags]: https://github.com/LuaJIT/LuaJIT/tags
[luajit-makefile-ver]: https://github.com/LuaJIT/LuaJIT/blob/d0e88930ddde28ff662503f9f20facf34f7265aa/Makefile#L16-L20
[gentoo-repo-luajit]: https://gitweb.gentoo.org/repo/gentoo.git/tree/dev-lang/luajit?id=e82c891da0b880d06d8d4ff4cc42477bcbcf22a2

## 实时 ebuild 的用处

**制作好非实时 ebuild 后，请不要立马就删除实时 ebuild**！即使已经有了非实时 ebuild，实时 ebuild 对软件包维护者往往仍有价值，对部分用户或许也有用。实时 ebuild 本身是没问题的——毕竟本文的标题不是“避免创建实时 ebuild”；本文只是不鼓励只有一个实时 ebuild 的软件包。

实时 ebuild 和非实时 ebuild 之间是互补关系，而非替代关系。我曾留意到有些 GURU 贡献者会用非实时 ebuild 来替代一个软件包的实时 ebuild。虽然这样的替代操作并不是绝对错误的，但它也并不是最佳的操作：实时 ebuild 完全可以保留下来，因为它仍然具有价值。

### 对于维护者

实时 ebuild 可帮助软件包维护者更早地、更轻松地、更好地准备发布下一个非实时 ebuild。

在实时 ebuild 中，维护者可以暂存软件包的下个新版本所需的 ebuild 修改，例如软件包的新依赖的声明。这样一来，等下个新版本发布之时，维护者基本上只需要直接复制该实时 ebuild，将复制出来的 ebuild 变为该新版本的非实时 ebuild，就完成了软件包版本更新。Gentoo Wiki 上有个[页面][gentoo-wiki-reviewers-issues]就提到了这种操作：

> If a package has a live ebuild, you can split a version bump into a series of
> commits applying different changes to the live ebuild, and they *[sic]* a
> final version bump commit that copies the live ebuild into release.
>
> （译：如果软件包有实时 ebuild 的话，您可以将版本更新拆分成多个小提交，并在每个提交中对该实时 ebuild 进行不同的改动，最后再为新版本创建一个复制该实时 ebuild 的提交，以完成版本更新。）

本文中[之前][if-pv-eq-9999-then-code]建议使用的 `if [[ ${PV} == 9999 ]]; then ...` 代码块在这里就派上用场了：在最理想的情况下，有了这个代码块，维护者在从实时 ebuild 创建新的非实时 ebuild 的时候，根本就不需要对 ebuild 本身进行任何改动。否则，维护者就需要在每次更新时都在非实时 ebuild 中作出以下修改，导致更新流程更繁琐。

{{% live-to-non-live.inline /%}}

实时 ebuild 允许软件包维护者更早地、增量地、持续地开展给软件包的下一个版本开发 ebuild 的工作。维护者可以使用实时 ebuild 定期构建软件包的最新开发版本；当构建因为上游最新的改动而失败时，维护者研究失败的原因，并更新实时 ebuild 以解决问题，让构建能够完成。只要维护者以合理的间隔重复这一流程，他们就算遇到了问题，每次一般也只有一两个问题需要解决。

而如果维护者直到上游发布了新版本才开始为其开发 ebuild 的话，他们就可能一次性遇到许多问题、并且需要对 ebuild 同时作出并测试多项修改。这样的开发工作好比临时抱佛脚，往往难度更高、更不容易管理；不如化整为零，让每项修改都能被独立完成并测试、减小每项修改的体量、让 ebuild 的修改工作能增量地、持续地进行。

[gentoo-wiki-reviewers-issues]: https://wiki.gentoo.org/wiki/Project:Reviewers/Common_issues
[if-pv-eq-9999-then-code]: {{<relref "#if-pv-eq-9999-then-code">}}

### 对于用户

给软件包添加实时 ebuild 还有一个对用户有意义的副作用：任何喜欢尝鲜的用户都可以尝试使用该实时 ebuild 来安装该软件包的最新开发版本。

不过，需要注意的是，这只是实时 ebuild 的一个*副作用*，而非主要目的。实时 ebuild 无论在能正常使用方面还是可靠性方面都没有保证：正如本文最开头的部分所讨论的，上游的改动随时都可能导致实时 ebuild 无法使用。如果实时 ebuild 恰好能使用的话是最好，但如果构建失败了，也是意料之中。

## 少有的纯 `-9999` 软件包是正解的情况

有一种情况下，创建纯 `-9999` 软件包是合理选项：软件包对应的软件项目是一个测试平台，并非用于满足普通用户的生产需求，且频繁发布新版本。譬如 Gentoo 仓库中的 [`sys-kernel/linux-next`] 软件包，对应的就是 Linux 内核的 [*linux-next*] 源码树。*linux-next* 是一个暂存还需要测试的内核补丁的地方，并不是适合大部分用户使用的内核源码仓库。每个星期，*linux-next* 的 Git 仓库都会有好几个新的[标签][linux-next-tags]。由于 *linux-next* 项目的不稳定性质和极快的新版本发布速度，只给它做一个实时 ebuild 是个合理的选择。

但无论如何，这种情况还是很少的。对于大部分的软件项目而言，创建纯 `-9999` 软件包都是应该避免的。

[`sys-kernel/linux-next`]: https://packages.gentoo.org/packages/sys-kernel/linux-next
[*linux-next*]: https://www.kernel.org/doc/man-pages/linux-next.html
[linux-next-tags]: https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/refs/
