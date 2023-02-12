---
title: "Avoid Creating `-9999`-only Gentoo Packages"
tags:
  - Gentoo
categories:
  - Tutorial
toc: true
---

Some Gentoo packages provide a special `9999` version; by convention, the
ebuild that bears the `9999` version is a *live ebuild*, which builds the
package from its "live" sources in the project's version control system (VCS)
repository -- e.g. a Git repository -- instead of "non-live" sources in a
`.zip` or a `.tar.*` archive.  The project's sources in the VCS repository are
usually subject to frequent changes due to development activities, hence they
are "live".

When a package has only a live ebuild and no non-live ebuilds, I would call it
a "`-9999`-only package" since the only version available for this package
would usually be `9999`.  **Please avoid creating `-9999`-only packages**.  In
other words, **a live ebuild should not be the only ebuild for a package**.

For packages whose upstream does not make releases, adding a non-live ebuild
seems impossible.  This is usually not true: even though the package has no
releases, it is usually still feasible to create an ebuild that builds it from
fixed, "non-live" sources.  This article will discuss one way to do this.

In this article, a package's *maintainers* are the people who write and manage
ebuilds for the package.  For people who write and manage the source code of
the package itself, this article refers to them as the package's *upstream*.
{.notice--info}

## Major Issues with `-9999`-only Packages

Requiring users to type two extra asterisks (`**`) in
`/etc/portage/package.accept_keywords`[^live-keywords] is only a relatively
minor issue of a `-9999`-only package.  A `-9999`-only package causes more
inconvenience than this to its users and may also backfire on its maintainers,
leading to a lose-lose situation.

[^live-keywords]:
    Typically, a user has to add a line similar to the following to
    `/etc/portage/package.accept_keywords` to install a live ebuild:

    ```
    games-emulation/dosbox-x **
    ```

    Whereas if the user just wants to install an unstable version of the
    package (note that this is not the same as the `9999` version), they only
    need to add this, without the two asterisks:

    ```
    games-emulation/dosbox-x
    ```

    The two asterisks are required to install an unkeyworded ebuild, and a live
    ebuild must be unkeyworded
    (<https://devmanual.gentoo.org/ebuild-writing/functions/src_unpack/vcs-sources/>).

### Package Is Prone to Changes in the VCS Repository

The upstream may update the sources in the VCS repository at any time, and
changes may break things: what worked yesterday may be broken today.
Unfortunately, the live ebuild is also one of the things that can be broken.

- An update may introduce an incompatible change to the package's build system,
  which requires the package's maintainers to update the live ebuild
  accordingly.  Unless the live ebuild is updated in time, the users cannot
  install the package for a while.

- A change to the package's source code may trigger new compiler errors.  It
  might be impossible to fix those errors simply with an ebuild update, so the
  package's maintainers might need to rely on the package's upstream to correct
  the issues.  Before the upstream actions, the package is also effectively not
  installable for a while.

From the users' perspective, a `-9999`-only package tends to be unreliable.
When the live ebuild is not installable due to the reasons above, the users
have no other ebuilds to try, so they cannot install the package at all.  A
package that is often not installable is hardly reliable.

From the maintainers' perspective, ensuring a `-9999`-only package's high
availability[^pkg-availability] requires more maintenance effort, if it is
possible at all: the maintainers must update the live ebuild immediately for
any breaking changes from the upstream to achieve this goal.

Adding a non-live ebuild resolves all these issues and thus benefits both users
and maintainers.  In fact, a non-live ebuild is inherently immune from these
issues because it always builds the package from the same sources.

[^pkg-availability]:
    The concept of availability is usually applied only to runnable systems as
    it is defined using uptime and downtime; as far as I know, it is not
    commonly applied to a software distribution's packages.  But here, I would
    define a package's availability as the amount of time it is installable
    divided by the total amount of time it is provided in its software
    repository.

### Users Cannot Always Easily Downgrade the Package

When a new version of a package is not working properly or has a regression, it
is customary for users to temporarily roll back to the previous version.  For a
`-9999`-only package, roll-back is not always possible, which may leave the
users with a broken installation of the package.

Suppose the live ebuild downloads the package's sources from a Git repository,
so it inherits `git-r3.eclass`.  The package's upstream does not follow the
best development practices: they like pushing big, non-atomic commits, each of
which changes a lot of files, and one recently-pushed commit made these changes
at once:
- A switch of the package's build system from GNU Autotools to Meson
- Optimizations on the package's source code proper, which, unfortunately, were
  not done properly and would trigger new runtime bugs

In response to this commit, the package's maintainers have updated the live
ebuild, so it uses `meson.eclass` instead of `autotools.eclass`.

The package's users hear the words about the optimization and decide to try out
the new version, so they sync their ebuild repositories and rebuild the
package.  Soon, they discover the new runtime bugs and frustratingly find out
that the bugs render the package barely usable.  They want to temporarily go
back to the previous version until the upstream fixes the bugs.

Experienced users might know the `EGIT_OVERRIDE_COMMIT_*` variable, which
`git-r3.eclass` provides and prompts in the build log, and seems useful in this
situation:

```plain {hl_lines=6}
>>> Unpacking source...
 * Repository id: joncampbell123_dosbox-x.git
 * To override fetched repository properties, use:
 *   EGIT_OVERRIDE_REPO_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_BRANCH_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_COMMIT_JONCAMPBELL123_DOSBOX_X
 *   EGIT_OVERRIDE_COMMIT_DATE_JONCAMPBELL123_DOSBOX_X
```

So, they find out the SHA-1 hash of the last commit before the aforementioned
big commit in the package's Git repository, and they set the
`EGIT_OVERRIDE_COMMIT_*` variable's value to the hash in an attempt to install
an unaffected version.

Unfortunately, this will not work.  The ebuild that builds and installs the
older version is still the same new ebuild, which has been adapted for Meson
and no longer works with GNU Autotools.  Yet the older version still uses GNU
Autotools as the build system.  The old version's build will fail.  The users
are stuck with the broken latest version.  They have to manually restore the
old live ebuild into the local copy of the ebuild repository to succeed with
this method, but the manual restoration creates more hassles.

If a non-live ebuild for a previous version is available for this package, then
the users can simply install that ebuild to roll back.  They just need to use
`emerge` and do not need to modify files in their local copy of the ebuild
repository.

### Offline Rebuilds Are Impossible by Default

When a user needs to rebuild a `-9999`-only package while they are disconnected
from the Internet by chance, they might find themselves being unable to rebuild
it.  Rebuilding the live ebuild offline requires extra configuration, and not
all users are well versed in figuring out what configuration is required when
they are offline.

The way to force an offline rebuild of a live ebuild is to set the
`EVCS_OFFLINE` variable's value to a non-empty string in Portage configuration
or the environment.  For example:

```console
# EVCS_OFFLINE=1 emerge --ask --oneshot ~games-emulation/dosbox-x-9999
```

The solution is simple and straightforward, thus the problem may seem trivial!
However, the solution is not obvious to the users, especially when they are
offline.  Take an ebuild that inherits `git-r3.eclass` as an example.  When the
system is offline, `git-r3.eclass` does not mention `EVCS_OFFLINE` in its error
message, so the user is not informed of the solution.  Yet this error message
may be the only clue the user can exploit because they cannot search for a
solution online.  So, the user might not know what to do and could only
cluelessly stare at the error message.

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

Methods to find out about the `EVCS_OFFLINE` variable on an offline system do
exist, but it is not safe to assume that everyone can use one of those methods.
For instance, users can read the VCS eclass's source code under
`/var/db/repos/gentoo/eclass` to discover `EVCS_OFFLINE`.  However, not
everyone is capable of interpreting an eclass's source code.  Some users might
not even know what an eclass is.

A non-live ebuild does not require users to do anything special to rebuild it
offline: with the default Portage configuration, users can directly rebuild it
offline with the same USE flags -- no special setting is needed.  When the
ebuild was built and installed the first time, the source files it would use
were downloaded and saved to Portage's *DISTDIR* directory
(`/var/cache/distfiles` by default).  These files are reused in rebuilds *by
default*, and no new files need to be downloaded as long as the USE flags are
not changed, thus users can rebuild the non-live ebuild offline without any
extra configuration.  A live ebuild *can* reuse downloaded files too, but as
discussed above, it does not reuse them by default, hence `-9999`-only packages
may trouble unexperienced users in offline circumstances.

### `eclean-dist` Cannot Clean the Package's Obsolete Files

[`eclean-dist`] is a utility from `app-portage/gentoolkit` that cleans up
obsolete package sources under *DISTDIR*.  After a user uninstalls a package,
or a system update replaces a package's old version, `eclean-dist` can clean up
the removed package version's source files under *DISTDIR* to save space.

However, `eclean-dist` cannot clean up obsolete source files downloaded by a
live ebuild.  `eclean-dist` can only clean up regular files under *DISTDIR*
itself, not subdirectories under it.  Yet the VCS eclasses designed for live
ebuilds download source files to a subdirectory under *DISTDIR*:

- `bzr.eclass`: [`${DISTDIR}/bzr-src/`]
- `cvs.eclass`: [`${DISTDIR}/cvs-src/`]
- `git-r3.eclass`: [`${DISTDIR}/git3-src/`]
- `golang-vcs.eclass`: [`${DISTDIR}/go-src/`]
- `mercurial.eclass`: [`${DISTDIR}/hg-src/`]
- `subversion.eclass`: [`${DISTDIR}/svn-src/`]

Therefore, after a user uninstalls a `-9999`-only package, they need to
manually delete the package's source files under one of those directories to
clean up space.  The user cannot rely on `eclean-dist` to automatically delete
those files for them.

Although this problem also applies to any package's live ebuild, for packages
that provide at least one non-live ebuild, users can install a non-live ebuild
and still enjoy the package, and `eclean-dist` can clean up the package's
obsolete source files for them.  With `-9999`-only packages, users are forced
to install a live ebuild and cannot benefit from `eclean-dist`.

[`eclean-dist`]: https://wiki.gentoo.org/wiki/Knowledge_Base:Remove_obsoleted_distfiles#Resolution
[`${DISTDIR}/bzr-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/bzr.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n33
[`${DISTDIR}/cvs-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/cvs.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n97
[`${DISTDIR}/git3-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/git-r3.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n85
[`${DISTDIR}/go-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/golang-vcs.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n45
[`${DISTDIR}/hg-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/mercurial.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n50
[`${DISTDIR}/svn-src/`]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/subversion.eclass?id=68aa812e63a6ed4e31ec6ad3050c4adfae710671#n31

### In GURU: Package Is Not Covered by Tinderbox's Automated Tests

[GURU] is Gentoo's official ebuild repository for user-submitted ebuilds.  GURU
packages are tested automatically by the [tinderbox] system set up by Agostino,
a Gentoo developer.  (The same tinderbox system also tests packages in the
Gentoo repository.)  When tinderbox detects an issue in a package, like a build
failure, a test failure, or a QA notice, it automatically reports the issue to
the package's maintainers on Gentoo Bugzilla.

However, tinderbox cannot report issues for `-9999`-only packages.  Tinderbox
does not test live ebuilds, which is understandable: as already discussed, a
live ebuild may become broken at any time -- even before tinderbox tests it.
`-9999`-only packages do not have any non-live ebuilds for tinderbox to test,
thus they are not covered by tinderbox at all.

Tinderbox can help package maintainers discover package issues that would not
exhibit in the maintainers' own test environments.  For instance, below are
some issue reports I have received from tinderbox for GURU packages I have been
maintaining.  Without these reports, I would not have been aware of those
issues at all because my own test environments would not trigger them.

- [Bug 833823][#833823]: Missing test dependency `gui-libs/gtk:4` in
  `DEPEND`.  I tested this ebuild in an environment where `gui-libs/gtk:4` was
  pre-installed, so the tests passed locally despite that the test dependency
  was not explicitly declared in the ebuild.  However, when tinderbox tested it
  in an environment where `gui-libs/gtk:4` was not pre-installed, the tests
  failed due to the missing dependency.

- [Bug 859973][#859973]: Package failed LTO-enabled builds.  It would trigger
  compiler errors when LTO compiler flags were used.  I had never tried to
  build this package with LTO compiler flags, so I had been unaware of this
  issue until tinderbox reported it to me.

To gain the benefit of tinderbox's automated package tests, GURU contributors
are advised to consider adding at least one non-live ebuild to each of their
`-9999`-only packages.

[GURU]: https://wiki.gentoo.org/wiki/Project:GURU
[tinderbox]: https://blogs.gentoo.org/ago/2020/07/04/gentoo-tinderbox/
[#833823]: https://bugs.gentoo.org/833823
[#859973]: https://bugs.gentoo.org/859973

## Fix a `-9999`-only Package

Fixing a `-9999`-only package -- so it is no longer a `-9999`-only package --
is simple: just add at least one non-live ebuild for the package.  Even if the
package's upstream does not make releases, adding a non-live ebuild is usually
still possible.

### Create a Non-live ebuild

Typically, when creating the non-live ebuild, the existing live ebuild can be
used as the starting point -- a working non-live ebuild can be obtained simply
by making a few modifications to the live ebuild.

Suppose the live ebuild inherits `git-r3.eclass`.  It would usually contain
lines like these ones:

```bash
inherit git-r3
EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
```

Some package maintainer's instinct might instruct them to remove those lines
and add definitions of `SRC_URI`, `KEYWORDS`, and maybe `S` for the non-live
ebuild:

{{% live-to-non-live.inline %}}
```diff
-inherit git-r3
-EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
+SRC_URI="https://github.com/joncampbell123/dosbox-x/archive/dosbox-x-v${PV}.tar.gz"
+S="${WORKDIR}/${PN}-${PN}-v${PV}"
+KEYWORDS="~amd64"
```
{{% /live-to-non-live.inline %}}

However, **this is not the best resolution**.  The suggested modification is:

1. Retain those lines from the live ebuild, and add them to an `if` block,
   which will be demonstrated in the next code snippet.

2. Add the variable definitions for the non-live ebuild to the `else` block
   that follows the `if` block.

3. Put the resulting code into **both** the existing live ebuild and the new
   non-live ebuild.

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

Why this `if [[ ${PV} == 9999 ]]; then ...` block?  Why is it added to both the
live ebuild and the non-live ebuild?  This article will address these questions
in [a later section][if-pv-eq-9999-then-reason].

[if-pv-eq-9999-then-reason]: {{<relref "#to-maintainers">}}

### If Upstream Makes Releases

For a package whose upstream makes releases, adding a non-live ebuild is
straightforward: just create an ebuild for the latest tagged release.

- Use the value of `PV` in `SRC_URI`, either directly or indirectly, to compile
  the URI to the package's sources.

- If necessary, also use the value of `PV` to set `S`, either directly or
  indirectly.

- If the live ebuild was created when the upstream had made substantial changes
  to the project since the latest tagged release, then the non-live ebuild
  might require additional modifications to be functional.

  For instance, if the upstream has switched the package's build system from
  GNU Autotools to Meson since the last release, and the live ebuild was
  created after the switch so it uses `meson.eclass`, then the non-live ebuild
  would need to inherit `autotools.eclass` instead of `meson.eclass` since it
  is for an older version of the package that still uses GNU Autotools.

### If Upstream Does Not Make Releases

If the upstream has never made releases for the package, or the upstream had
issued releases long before but has stopped doing it, then creating a non-live
ebuild for the package becomes tricky: the appropriate `SRC_URI` and `PV` for
the non-live ebuild are not obvious.

Usually, the non-live ebuild can still be created using a snapshot archive of
the project's VCS repository, instead of a tagged release archive.  The
snapshot archive contains the repository's files at a specific revision, which
does not need to carry a tag.  The `SRC_URI` variable can thus use the URI to
the snapshot archive.  The `PV` variable uses the date of the snapshot's
revision as an identifier.

#### Find Out Snapshot Archives' URI Format

First and foremost, check if the website that hosts the package's VCS
repository provides the functionality to download an arbitrary revision's
snapshot archive.  Then, confirm that the download URI meets these criteria:
- The URI includes the revision.
- After changing the revision in the URI to another revision, the new URI
  downloads the latter revision's snapshot archive accordingly.

All websites listed below satisfy these requirements.  The URI's format for
each website is also given for readers' convenience.

- Codeberg: `https://codeberg.org/${OWNER}/${REPO}/archive/${COMMIT}.tar.gz`
- SourceHut, Git repositories (git.sr.ht): `https://git.sr.ht/~${OWNER}/${REPO}/archive/${COMMIT}.tar.gz`
- GitLab.com: `https://gitlab.com/${OWNER}/${REPO}/-/archive/${COMMIT}/${REPO}-${COMMIT}.tar.bz2`
- GitHub: `https://github.com/${OWNER}/${REPO}/archive/${COMMIT}.tar.gz`
- Bitbucket: `https://bitbucket.org/${OWNER}/${REPO}/get/${COMMIT}.zip`
- A self-hosted Gitea instance: `${BASE_URI}/${OWNER}/${REPO}/archive/${COMMIT}.tar.gz`
- A self-hosted GitLab instance: `${BASE_URI}/${OWNER}/${REPO}/-/archive/${COMMIT}/${REPO}-${COMMIT}.tar.bz2`

Please replace each of these parts of the given URIs with the appropriate
value:
- `${OWNER}`: The name of the user/group/organization/etc. who owns the
  repository
- `${REPO}`: The repository's name
- `${COMMIT}`: The full 40-character SHA-1 hash of the snapshot's revision
  commit
- `${BASE_URI}` (for a self-hosted VCS service only): The service's base URI
  (e.g. `https://gitlab.gnome.org` for GNOME GitLab)

#### Define `SRC_URI`

Next, the snapshot archive's URI can be added to the non-live ebuild's
`SRC_URI`.  The package maintainers have the full discretion to select the
revision at which the snapshot is taken, though the shortest path is to use the
revision against which the existing live ebuild has been tested: no additional
change to the live ebuild is needed to transform it into a working non-live
ebuild in this case.

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

This example defines a `GIT_COMMIT` variable to store the snapshot's revision,
which has these benefits:
- It makes the ebuild's code more readable.
- It helps avoid unnecessary repetition of the revision in `SRC_URI` and `S`.
- It makes future package version bumps easier by extracting the changeable
  part of `SRC_URI` and `S` into a standalone variable; a standalone variable
  is more convenient to edit.

This example also renames the snapshot archive to `${P}.tar.gz` by appending `
-> ${P}.tar.gz` to the archive's URI in `SRC_URI`.  The snapshot archive's
original file name is usually something like
`982c44176e7619ae2a40b5c5d8df31f2911384da.tar.gz`, which has these potential
issues:

- This kind of file name tells neither the package name associated with the
  archive nor `PV` of ebuilds that use the archive, which hinders manual access
  and management of package sources under *DISTDIR*.  For instance, someone
  might want to run a `tar` command to unpack the snapshot archive directly to
  explore the package's sources, so they can avoid a Git clone and save
  bandwidth.  If the snapshot archive is not renamed, the person cannot easily
  locate it in *DISTDIR*.

- Two different packages' snapshot archives may have conflicting original file
  names when those snapshots are coincidentally taken at revisions with the
  same identifier.  Between Git repository snapshots, this is rare but still
  theoretically possible.  This may occur more often to Subversion repository
  snapshots because Subversion uses integers to identify revisions, not SHA-1
  hashes.

#### Determine `PV`

The `PV` of the non-live ebuild should contain the date of the snapshot's
revision in `YYYYMMDD` format, so an ebuild that uses a newer snapshot also has
a `PV` that sorts higher.  Depending on how the package's upstream assigns
versions to the package's releases, `PV` should include the date in one of
these styles:

- If the upstream has not created any releases for the package at all: Use
  `0_preYYYYMMDD`, e.g. `0_pre20230130`.

  This way, if the upstream starts to make releases for the package later, they
  would typically choose version strings that are higher than
  `0_preYYYYMMDD`[^fedora-pkg-no-ver], so the package's users would be able to
  receive upgrades to versioned releases.  As per Gentoo's [Package Manager
  Specification (PMS)][pms-ver-cmp], these values of `PV` all sort higher than
  `0_preYYYYMMDD`:
  - `0`
  - `0.0_alpha`
  - `0.0`
  - `0.0.0_alpha`
  - `0.0.0`

  One example `PV` that would cause issues is `0_alpha` because it sorts lower
  than `0_preYYYYMMDD`.  For this kind of version string, it is suggested that
  package maintainers use `0.0_alpha` as `PV` instead and manipulate the `PV`
  value in the ebuild itself to match the upstream's version string:

  ```bash {hl_lines="5-6"}
  if [[ ${PV} == 9999 ]]; then
  	inherit git-r3
  	EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
  else
  	MY_PV="${PV/.0/}" # Removes '.0' from PV, so MY_PV="0_alpha"
  	MY_P="${PN}-${MY_PV}"

  	SRC_URI="https://github.com/joncampbell123/dosbox-x/archive/${MY_P}.tar.gz"
  	S="${WORKDIR}/${PN}-${MY_P}"
  	KEYWORDS="~amd64"
  fi
  ```

- If the upstream has stopped making releases, and after the last release, the
  upstream has bumped the package version in the package's source files: Use
  the version after the bump with `_preYYYYMMDD` suffix as
  `PV`[^devmanual-snapshots].

  For instance, a lot of Java packages' upstreams like to bump the package
  version immediately after a release, like [bumping to
  `1.4-SNAPSHOT`][sqlj-maven-plugin-1.4-SNAPSHOT] right after [releasing
  `1.3`][sqlj-maven-plugin-1.3].  The `PV` for the package's latest snapshot
  could then be `1.4_pre20170907` as the upstream has never released version
  1.4.

- If the upstream has stopped making releases, nor has the upstream bumped the
  package version in the package's source files after the last release: Use the
  last release's version with `_pYYYYMMDD` suffix as
  `PV`[^devmanual-snapshots].

  One infamous example project is LuaJIT, which has had no new releases for
  more than 5 years despite continuous development activities.  As of writing
  (and maybe for ever), the last [tagged release of LuaJIT][luajit-tags] is
  `v2.1.0-beta3`, and the Makefile in the Git repository still also [defines
  the package's version][luajit-makefile-ver] as `2.1.0-beta3`.  The `PV` for
  the package's latest snapshot could then be `2.1.0_beta3_p20230104`.  This
  `PV` format is indeed used by [`dev-lang/luajit` ebuilds][gentoo-repo-luajit]
  in the Gentoo repository.

[^fedora-pkg-no-ver]:
    https://docs.fedoraproject.org/en-US/packaging-guidelines/Versioning/#_upstream_has_never_chosen_a_version

[^devmanual-snapshots]:
    https://devmanual.gentoo.org/ebuild-writing/file-format/#snapshots-and-live-ebuilds

[pms-ver-cmp]: https://projects.gentoo.org/pms/8/pms.html#x1-260003.3
[sqlj-maven-plugin-1.3]: https://github.com/mojohaus/sqlj-maven-plugin/commit/0c61613e43645d39607b7091172a2f0a28d677c6
[sqlj-maven-plugin-1.4-SNAPSHOT]: https://github.com/mojohaus/sqlj-maven-plugin/commit/4946ad9d0cdb68fe9a7bfe9c21d93e04f20a8b36
[luajit-tags]: https://github.com/LuaJIT/LuaJIT/tags
[luajit-makefile-ver]: https://github.com/LuaJIT/LuaJIT/blob/d0e88930ddde28ff662503f9f20facf34f7265aa/Makefile#L16-L20
[gentoo-repo-luajit]: https://gitweb.gentoo.org/repo/gentoo.git/tree/dev-lang/luajit?id=e82c891da0b880d06d8d4ff4cc42477bcbcf22a2

## Live ebuilds' Usefulness

**Do not delete the live ebuild without thinking twice after adding a non-live
ebuild**!  The live ebuild is often still useful to both the package's
maintainers and perhaps some users as well, even when a non-live ebuild exists
for the same package.  Live ebuilds per se are fine -- after all, this
article's title is not "Avoid Creating Live ebuilds"; this article only
discourages packages with *only* a live ebuild.

Live ebuilds and non-live ebuilds complement each other rather than replace
each other.  I have observed some GURU contributors replacing a package's live
ebuild with a non-live ebuild.  Although the replacement was not absolutely
wrong, it was not the best action: the live ebuild could have been kept for its
usefulness.

### To Maintainers

A live ebuild of a package helps the package's maintainers prepare to release
the next non-live ebuild earlier, easier, and better.

The live ebuild is a place where the maintainers can stage ebuild changes that
are necessary for the next upstream release of the package, like declaration of
new dependencies.  Then, when the next release becomes available, the
maintainers usually just need to make a copy of the live ebuild, turn the copy
into a non-live ebuild for the new release, hence complete the version bump.
[A Gentoo Wiki page][gentoo-wiki-reviewers-issues] mentions the same idea:

> If a package has a live ebuild, you can split a version bump into a series of
> commits applying different changes to the live ebuild, and they *[sic]* a
> final version bump commit that copies the live ebuild into release.

The `if [[ ${PV} == 9999 ]]; then ...` block that this article suggested
[earlier][if-pv-eq-9999-then-code] comes in useful here: in the best case, it
allows the maintainers to create a new non-live ebuild from the live ebuild
without changing the ebuild itself at all.  Otherwise, they would need to make
the following edit in the non-live ebuild every time, which is cumbersome.

{{% live-to-non-live.inline /%}}

The live ebuild allows the package's maintainers to work on the ebuild for the
next release early, incrementally, and continuously.  The maintainers can
periodically build the package's latest development version using the live
ebuild; when a build fails due to the upstream's recent changes, they
investigate the failure and fix the live ebuild, so the build can succeed.
Should they do this at a reasonable interval, they usually only need to fix one
or two problems each time, if a problem arises at all.

On the other hand, if the maintainers do not start working on the ebuild for a
new upstream release until the release is available, they might run into a lot
of problems to fix at once and need to make and test a lot of changes to the
ebuild together.  This could be harder and less manageable than individually
making and testing smaller, incremental, and continuous ebuild updates over a
longer time span.

[gentoo-wiki-reviewers-issues]: https://wiki.gentoo.org/wiki/Project:Reviewers/Common_issues
[if-pv-eq-9999-then-code]: {{<relref "#if-pv-eq-9999-then-code">}}

### To Users

Adding a live ebuild to a package also has a side effect meaningful to users:
any users who like to be on the bleeding edge may try and use the live ebuild
to install the package's latest development version.

However, note that this is only a *side effect* instead of a live ebuild's main
purpose.  The live ebuild is not guaranteed to work and be reliable: an
upstream change to the package may break the live ebuild at any time, as
already discussed in the first part of this article.  It is great if the live
ebuild happens to work, but it should not be surprising if the build fails.

## Rare Case Where a `-9999`-only Package Is Justified

One case in which it is OK to create a `-9999`-only package exists: the package
is for a testbed project that is never intended for normal users' production
workloads and has frequent releases.  An example is the
[`sys-kernel/linux-next`] package in the Gentoo repository, which is for the
Linux kernel's [*linux-next*] tree.  *linux-next* is an area for staging kernel
patches that still need to be tested, not a kernel sources repository suitable
for most users.  New [tags in the *linux-next* Git repository][linux-next-tags]
come out several times a week.  Having only a live ebuild for *linux-next*
makes sense due to this project's unstable nature and fast release cadence.

Nevertheless, this case is rare.  For most projects, creating a `-9999`-only
package for it should be avoided.

[`sys-kernel/linux-next`]: https://packages.gentoo.org/packages/sys-kernel/linux-next
[*linux-next*]: https://www.kernel.org/doc/man-pages/linux-next.html
[linux-next-tags]: https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/refs/
