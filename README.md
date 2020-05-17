# `leo3418.github.io`

This is the repository for [my personal site](https://leo3418.github.io/).

## Technical Overview

This site is based on [Jekyll](https://jekyllrb.com/).

Although GitHub Pages offers direct Jekyll support, it does not allow use of
unsupported plugins. Because this site uses unsupported plugins, it cannot be
built automatically by GitHub Pages. Instead, the site must be built somewhere
else, then the generated static files of the site can be uploaded to this
repository. The process of building and uploading the site is automated by a
[GitHub Actions
workflow](https://github.com/Leo3418/leo3418.github.io/actions).

Because the GitHub Pages site for a user must be published from the `master`
branch, and we don't want to publish the source files for the site, the source
files are stored in a dedicated branch named `jekyll`. The workflow for
automated builds and deployment will pull the source files from the `jekyll`
branch and upload the static files to the `master` branch.

## Directory Structure of Source Files

The source files for this site are generally structured like a [basic Jekyll
site](https://jekyllrb.com/docs/structure/) with a few variations.

- `assets/`: Assets
  - `css/`: SCSS files used to generate this site's stylesheets
  - `img/`: Images
    - `collections/<collection-name>/<doc-name>/`: Images for a document in a
      collection
      - `<lang>/`: Localized images for the document
    - `drafts/<post-name>/`: Images for a draft
      - `<lang>/`: Localized images for the draft
    - `posts/<year>-<month>-<day>-<post-name>/`: Images for a post
      - `<lang>/`: Localized images for the post
- `collections/`: Pages for collections, posts, and drafts
  - `_drafts/<lang>/`: Drafts written in a language
  - `_posts/<lang>/`: Posts written in a language
  - `_<collection-name>/<lang>/`: Documents in a collection, in the specified
    language
  - `<collection-name>-<lang>.md`: Home page for a collection, in the specified 
    language
- `_data/`: Data files
  - `<lang>/`: Localized data files for a language
    - `l10n.yml`: Properties for the language and localized site variables
    - `strings.yml`: Translated strings
- `_includes/`: Partials that can be included in other files, usually layouts
- `_layouts/`: Templates that wrap posts
- `_sass/`: Sass partials to be included by the SCSS files
- `_config.yml`: Jekyll configuration file
- `<page-name>-<lang>.md`: Top level page written in the specified language

## Generating Static Files

Before building the site, make sure you have [installed Jekyll and
Bundler](https://jekyllrb.com/docs/installation/) in your environment.

If this is the first time you build this site in your environment, then you
should run `bundle` under the this repository's root directory. Also, you'd
better run `bundle` again if the `Gemfile.lock` file has been changed since
your last run of the command.

To generate the static files, run `bundle exec jekyll build`. By default, the
static files are in the `_site/` directory under this repository's root.

To generate the files and view the site in a web browser, run `bundle exec
jekyll serve`. By default, the site is accessible from
`http://localhost:4000/`.

If the default Jekyll version in your environment matches the version specified
in `Gemfile.lock`, then you can build and serve with `jekyll build` and `jekyll
serve` respectively for shorter commands. You can compare those versions with
the following commands:

```sh
$ jekyll -v
jekyll x.y.z
$ grep "jekyll ([0-9]\+.[0-9]\+.[0-9])" Gemfile.lock
    jekyll (x.y.z)
```

## Reusing Contents in This Repository

Feel free to reuse any files in this repository to build your own Jekyll site.

Please also keep in mind that some contents used in the pages of this site,
such as text and images, are provided under a certain license. Those contents
are usually placed under the `assets/img/` and `collections/` directories. The
licensing information for a content is indicated on the generated webpage. If
you want to reuse any of those contents, please comply with the terms of the
license.
