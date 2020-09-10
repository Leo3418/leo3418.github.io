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

To separate the source files and generated static files for the site, these two
sets of files are placed under different branches of this repository. The
source files are stored in the `jekyll` branch. The workflow for automated
builds and deployment will pull the source files from the `jekyll` branch and
upload the static files to the `gh-pages` branch.

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
  - `js/`: Scripts for this site
  - `res/`: Other types of resources
    - `collections/<collection-name>/<doc-name>/`: Resources for a document in
      a collection
    - `drafts/<post-name>/`: Resources for a draft
    - `posts/<year>-<month>-<day>-<post-name>/`: Resources for a post
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
should run `bundle` under the this repository's root directory to install this
site's dependency gems. Also, you'd better run `bundle` again to update those
dependencies if the `Gemfile.lock` file has been changed since your last run of
the command.

To generate the static files, run `bundle exec jekyll build`. By default, the
static files are in the `_site/` directory under this repository's root.

To generate the files and view the site in a web browser, run `bundle exec
jekyll serve`. By default, the site is accessible from
`http://localhost:4000/`.

If the default Jekyll version in your environment matches the version used for
this site specified in `Gemfile.lock`, then you can build and serve with
`jekyll build` and `jekyll serve` respectively for shorter commands. You can
compare those versions with the following commands:

1. In a directory that is **not** the root of any Jekyll site, run this command
   to retrieve the default Jekyll version:

   ```console
   $ jekyll -v
   jekyll x.y.z
   ```

2. In the root of this repository, run this command to get the Jekyll version
   used for this site:

   ```console
   $ grep -o "jekyll ([0-9]\+.[0-9]\+.[0-9])" Gemfile.lock
   jekyll (x.y.z)
   ```

If the version numbers in the output of those commands are identical, then you
can omit `bundle exec` in all `jekyll` commands you run for this site.

## Reusing Contents in This Repository

Feel free to reuse any files in this repository to build your own Jekyll site.

Please also keep in mind that some contents used in the pages of this site,
such as text and images, are provided under a certain license. Those contents
are usually placed under the `assets/img/` and `collections/` directories. The
licensing information for a content is indicated on the generated webpage. If
you want to reuse any of those contents, please comply with the terms of the
license.
