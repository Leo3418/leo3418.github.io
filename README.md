# `leo3418.github.io`

This is the repository for [my personal site][site].

[site]: https://leo3418.github.io/

## Technical Overview

This site is based on [Hugo][hugo].  The theme it uses is a custom port of the
[Minimal Mistakes][minimal-mistakes] Jekyll theme to Hugo.  Changes to the site
are deployed to GitHub Pages automatically by a [GitHub Actions
workflow][gh-actions].

[hugo]: https://gohugo.io/
[minimal-mistakes]: https://mmistakes.github.io/minimal-mistakes/
[gh-actions]: https://github.com/Leo3418/leo3418.github.io/actions

## Directory Structure of Source Files

The source files for this site are organized in compliance with [Hugo's default
directory structure for sites][dir-struct].  The custom Hugo templates this
site uses (all of which are under the `layouts/` directory) also respect some
special paths:

- `assets/js/plugins/`: JavaScript plugins and libraries used by this site's
  scripts
- `static/css/syntax.css`: The [syntax highlighter stylesheet][syntax-hl-css]
- `static/img/`, `static/res/`: Images and miscellaneous resource files for
  this site
  - For details about how these directories' contents are organized, please
    read the comment at the top of file `layouts/shortcodes/static-path.html`
    in this repository.

[dir-struct]: https://gohugo.io/getting-started/directory-structure/#directory-structure-explained
[syntax-hl-css]: https://gohugo.io/content-management/syntax-highlighting/#generate-syntax-highlighter-css

## Generating the Site

First, ensure the **extended version** of Hugo is installed.  The extended
version is required because this site has SCSS files, which only the extended
version can handle.  The installation instructions are available
[here][hugo-install].

To start a local development server for previewing, change the working
directory to this repository's root, and run command `hugo server`.  By
default, the site is accessible via `http://localhost:1313/`.

To write the site's files to disk, run command `hugo`.  By default, the files
are written to the `public/` directory under this repository's root.

[hugo-install]: https://gohugo.io/getting-started/installing/

## Reusing Contents in This Repository

Feel free to reuse any files under the these directories in this repository to
build your own Hugo site:
- `archetypes/`
- `assets/`
- `config/`
- `i18n/`
- `layouts/`
- `static/css/`
- `static/js/`

Note that some of these files come from other projects and are covered by
certain license terms.  More details are given in the *License Information*
section below.

The majority of the content on this site's pages, such as text and images, is
provided under a certain license. The content is usually placed under the
`content/` and `static/img/` directories. The licensing information for a piece
of content is indicated on the generated webpage.  If you want to reuse any
content of such kind, please comply with the terms of the license.

## Licensing Information

This site uses SCSS files, JavaScript snippets, Hugo templates translated from
Liquid snippets, HTML DOM definitions, and UI strings from Minimal Mistakes,
which is copyright (C) 2013-2020 Michael Rose and contributors.  Its license
can be found [here][mmistakes-license].

This site uses templates derived from Hugo's built-in shortcodes.  Hugo is
copyright (C) 2022 The Hugo Authors.  Its license can be found
[here][hugo-license].

This site uses [asciinema player][asciinema-player], which is copyright (C)
2011-2022 Marcin Kulik.  Its license can be found
[here][asciinema-player-license].

This site uses [Breakpoint][breakpoint], which is copyright (C) 2012-2022 Sam
Richard and others and is stored at
`assets/sass/minimal-mistakes/vendor/breakpoint/` in this repository.  Its
license can be found [here][breakpoint-license].

This site uses [Font Awesome Free][font-awesome], which is copyright (C) 2022
Fonticons, Inc.  Its license can be found [here][font-awesome-license].

This site uses [Gumshoe][gumshoe], which is copyright (C) Go Make Things, LLC
and is stored at `assets/js/plugins/gumshoe.js` in this repository.  Its
license can be found [here][gumshoe-license].

This site uses [jQuery][jquery], which is copyright (C) OpenJS Foundation and
other contributors.  Its license can be found [here][jquery-license].

This site uses [Susy][susy], which is copyright (C) 2017, Miriam Eric Suzanne
and is stored at `assets/sass/minimal-mistakes/vendor/susy/` in this
repository.  Its license can be found [here][susy-license].

[asciinema-player]: https://github.com/asciinema/asciinema-player
[asciinema-player-license]: https://github.com/asciinema/asciinema-player/blob/v3.0.1/LICENSE
[breakpoint]: https://github.com/at-import/breakpoint
[breakpoint-license]: https://github.com/at-import/breakpoint/blob/main/LICENSE
[font-awesome]: https://fontawesome.com/
[font-awesome-license]: https://github.com/FortAwesome/Font-Awesome/blob/5.x/LICENSE.txt
[gumshoe]: https://github.com/cferdinandi/gumshoe
[gumshoe-license]: https://github.com/cferdinandi/gumshoe/blob/v5.1.1/LICENSE.md
[hugo-license]: https://github.com/gohugoio/hugo/blob/v0.101.0/LICENSE
[jquery]: https://jquery.com/
[jquery-license]: https://github.com/jquery/jquery/blob/3.6.0/LICENSE.txt
[mmistakes-license]: https://github.com/mmistakes/minimal-mistakes/blob/4.24.0/LICENSE
[susy]: https://www.oddbird.net/susy/
[susy-license]: https://github.com/oddbird/susy/blob/main/LICENSE.txt
