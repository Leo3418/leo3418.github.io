---
title: "Using New Feature While Maintaining Backward Compatibility in Hugo
  Templates"
categories:
  - Blog
---

In the recent [v0.109.0 release][hugo-v0.109.0] of Hugo, a new `.Ancestors`
page variable was added to make it easier to implement a [breadcrumb
navigation][wikipedia-breadcrumb-navigation] [template][hugo-docs-breadcrumb].
The new variable's usefulness is clearly shown by how the example breadcrumb
template in Hugo documentation has been simplified and become easier to
understand, as presented below (code modified for readability).  It is no
longer necessary to create a helper inline partial (i.e. `breadcrumbnav` in the
following example) and call it recursively.

<!--more-->

```html
<!-- Example breadcrumb template for Hugo 0.108.0 -->

<ol class="nav navbar-nav">
  {{ template "breadcrumbnav" (dict "p1" . "p2" .) }}
</ol>

{{ define "breadcrumbnav" }}
  {{ if .p1.Parent }}
    {{ template "breadcrumbnav" (dict "p1" .p1.Parent "p2" .p2 )  }}
  {{ else if not .p1.IsHome }}
    {{ template "breadcrumbnav" (dict "p1" .p1.Site.Home "p2" .p2 )  }}
  {{ end }}
  <li{{ if eq .p1 .p2 }} class="active" aria-current="page" {{ end }}>
    <a href="{{ .p1.Permalink }}">{{ .p1.Title }}</a>
  </li>
{{ end }}
```

```html
<!-- Example breadcrumb template for Hugo 0.109.0 -->

<ol class="nav navbar-nav">
  {{- range .Ancestors.Reverse }}
    <li><a href="{{ .Permalink }}">{{ .Title }}</a></li>
  {{- end }}
  <li class="active" aria-current="page">
    <a href="{{ .Permalink }}">{{ .Title }}</a>
  </li>
</ol>
```

By using `.Ancestors`, a breadcrumb template can be not only cleaner and
simpler, but also faster.  I benchmarked the speed of these two example
templates by using each of them to generate breadcrumbs for all the 174 pages
on this website as of writing, and the template which uses `.Ancestors` was
about two times faster than the one which does not.  (More details about the
benchmark are available in the [appendix][appendix-benchmark].)

| Breadcrumb Template       | Mean Total Execution Time |
| :------------------------ | ------------------------: |
| Does Not Use `.Ancestors` |             21.8588862 ms |
| Uses `.Ancestors`         |              11.252103 ms |

Because I had been writing and maintaining Hugo templates used by this website
myself, I immediately contemplated incorporating the new `.Ancestors` variable
into [my breadcrumb template][my-tmpl-breadcrumb-old] after seeing it in the
example.  The old template would still work on future Hugo releases, so I did
not *have to* update it, and perhaps I *shouldn't* either according to the "[if
it ain't broke, don't fix it][wiktionary-iiab-dfi]" principle.  But the
benefits of using `.Ancestors` -- namely more beautiful code with better
performance -- rejected all those potential counterarguments for me.

There was one factual thing I could not ignore though: I was still using Hugo
0.108.0 on my local work machine running Gentoo and had not upgraded to 0.109.0
yet, which means that using `.Ancestors` would cause local site build errors.
Nothing was preventing me from running 0.109.0 locally; I just wanted to wait
until the Hugo package on Gentoo updates to 0.109.0 because I had been
preferring to install software through a system package manager.  I could have
also postponed updating the template until Gentoo catches up with the latest
Hugo version, but I wanted to do the task immediately while it was on my mind.

The best obvious choice to me at this point was to download an official
pre-built Hugo 0.109.0 binary, save it to `/tmp` so I could use it temporarily
to develop a new version of the breadcrumb template, and keep the new template
somewhere else until Gentoo updates Hugo to 0.109.0, which is when the old
template could be replaced.  Because everything in `/tmp` would be gone after a
system reboot, I would not need to worry about leaving a binary not installed
by the system package manager on the system for too long.

Once the new template was complete, I thought about where to save it.  In a
local file?  In my synced notes?  Or in a comment block inside the breadcrumb
template file, which could be uncommented later after I upgrade Hugo to
0.109.0?  The last option prompted an idea.  I could still include the new code
in the template file, but not as comments, and even without breaking the
template's compatibility with 0.108.0.  This could be done using a conditional
clause that would run different version of the template for different Hugo
release.  The pseudocode for this idea is like:

```
if Hugo version is at least 0.109.0:
    run code that uses '.Ancestors'
else:
    run code that does not use '.Ancestors'
```

This technique would work because in a Hugo template, code in a conditional
branch that is not hit would not be evaluated at all, so undefined variables
used in the unhit branch would not be accessed, hence it would not trigger an
error.

{{<div class="notice--success">}}
This is similar to conditional compilation in programming languages like C and
some dynamic programming languages and scripting languages' behavior.  For
example, all these code snippets can be compiled and/or executed without
errors:

```c
int main() {
#if 0
    nonexistent_function();
#endif
    return 0;
}
```

```bash
#!/usr/bin/env bash

if false; then
    nonexistent_command
fi
exit 0
```

```python
#!/usr/bin/env python

import sys

if False:
    nonexistent_function()
sys.exit(0)
```
{{</div>}}

The only problem to be solved at this point was how Hugo's version could be
checked from a template.  There is a [`hugo` function][hugo-docs-hugo] that
templates can use to query information about the running Hugo instance, and the
version string is available via `hugo.Version`.  Next, this string would need
to be compared to `0.109.0`, which is the first Hugo version to provide the
`.Ancestors` variable.  There did not seem to be a version string comparison
function in Hugo; generic comparison functions would fail some edge cases of
version comparison, such as `ge "0.99.0" "0.109.0"`, which would return `true`.
What I came up with was to extract the second component of the version string,
convert it to an integer, then test whether it is numerically greater than or
equal to 109.  This would work as long as Hugo would not forsake [0-based
Versioning][zer0ver] by releasing v1.0 in the near future; otherwise, the
version string's second component would be 0, which is smaller than 109.

```html
<!-- Breadcrumb template which both utilizes the new '.Ancestors' page
     variable available since Hugo 0.109.0 and is backward-compatible
     with older Hugo versions that do not support '.Ancestors' -->

{{ if ge (index (split hugo.Version ".") 1 | int) 109 }}
    <ol class="nav navbar-nav">
      {{- range .Ancestors.Reverse }}
        <li><a href="{{ .Permalink }}">{{ .Title }}</a></li>
      {{- end }}
      <li class="active" aria-current="page">
        <a href="{{ .Permalink }}">{{ .Title }}</a>
      </li>
    </ol>
{{ else }}
    <ol class="nav navbar-nav">
      {{ template "breadcrumbnav" (dict "p1" . "p2" .) }}
    </ol>
{{ end }}

{{ define "breadcrumbnav" }}
  {{ if .p1.Parent }}
    {{ template "breadcrumbnav" (dict "p1" .p1.Parent "p2" .p2 )  }}
  {{ else if not .p1.IsHome }}
    {{ template "breadcrumbnav" (dict "p1" .p1.Site.Home "p2" .p2 )  }}
  {{ end }}
  <li{{ if eq .p1 .p2 }} class="active" aria-current="page" {{ end }}>
    <a href="{{ .p1.Permalink }}">{{ .p1.Title }}</a>
  </li>
{{ end }}
```

Note that inline partial definition cannot happen inside another block clause,
which is why the `define` block must be moved to the outermost level.
{.notice--warning}

For those who are interested to see the updated version of my breadcrumb
template, it is available [here][my-tmpl-breadcrumb-new].

Since my breadcrumb template was just for my personal website, which did not
have other collaborators or contributors, I could have avoided all the hassle
by updating all Hugo setups I used (including one on my local work machine and
one for the [GitHub Actions workflow][my-gh-actions-workflow] that had been
automating builds and deployments of this website) to 0.109.0.  But if it were
used in a collaborative Hugo site project or a published Hugo theme, then the
effort would have been definitely worth it.  When a lot of authors work on the
same Hugo site, it might not be feasible to require everyone to immediately
upgrade to the latest Hugo version.  Let alone when a Hugo theme is used by
hundreds of sites, hundreds of the theme's users would be forced to either
update Hugo or stick with an older version of the theme, if not thousands.
These are where a template's support for as many Hugo versions as possible
shines.  Users on newer Hugo versions can benefit from better template
performance thanks to new Hugo features, whereas users on older Hugo versions
need not worry about becoming unsupported or losing functionality at the same
time.

[hugo-v0.109.0]: https://github.com/gohugoio/hugo/releases/tag/v0.109.0
[wikipedia-breadcrumb-navigation]: https://en.wikipedia.org/wiki/Breadcrumb_navigation
[hugo-docs-breadcrumb]: https://gohugo.io/content-management/sections/#example-breadcrumb-navigation
[appendix-benchmark]: {{<relref "#appendix-breadcrumb-template-benchmark-data">}}
[my-tmpl-breadcrumb-old]: https://github.com/Leo3418/leo3418.github.io/blob/a4696da675372f5d9aa970347628feae4e7b7570/layouts/partials/breadcrumbs.html
[wiktionary-iiab-dfi]: https://en.wiktionary.org/wiki/if_it_ain%27t_broke,_don%27t_fix_it
[hugo-docs-hugo]: https://gohugo.io/functions/hugo/
[zer0ver]: https://0ver.org/
[my-tmpl-breadcrumb-new]: https://github.com/Leo3418/leo3418.github.io/blob/f6b6dd0648b55096695ef1f1b7b4d89ce00e9692/layouts/partials/breadcrumbs.html
[my-gh-actions-workflow]: https://github.com/Leo3418/leo3418.github.io/blob/f6b6dd0648b55096695ef1f1b7b4d89ce00e9692/.github/workflows/hugo.yaml

## Appendix: Breadcrumb Template Benchmark Data

The benchmark was done by running Hugo with its `--templateMetrics` option,
which would let Hugo report the total execution time (a.k.a. cumulative
duration) of each template used by the site.  Hugo documentation contains [more
details][hugo-docs-template-metrics] about the option's output.  For each
template benchmarked, I used the same Hugo 0.109.0 binary to build this website
with it ten times and collected the cumulative duration data:

```console
$ /tmp/hugo version
hugo v0.109.0-47b12b83e636224e5e601813ff3e6790c191e371+extended linux/amd64 BuildDate=2022-12-23T10:38:11Z VendorInfo=gohugoio
$ /tmp/hugo --templateMetrics | head -n 8 | tail -n 4

     cumulative       average       maximum
       duration      duration      duration  count  template
     ----------      --------      --------  -----  --------
$ # Benchmarking the breadcrumb template that does not use '.Ancestors'
$ for i in {1..10}; do
> rm -r /tmp/hugo_cache
> /tmp/hugo --destination /tmp/public --templateMetrics | grep -F 'partials/breadcrumbs.html'
> done
    23.360982ms     134.258µs    3.187397ms    174  partials/breadcrumbs.html
    25.673855ms      147.55µs    2.658119ms    174  partials/breadcrumbs.html
    16.676426ms      95.841µs     589.762µs    174  partials/breadcrumbs.html
    21.724248ms     124.852µs    2.150144ms    174  partials/breadcrumbs.html
    21.823904ms     125.424µs    2.396832ms    174  partials/breadcrumbs.html
    23.215258ms     133.421µs    4.748894ms    174  partials/breadcrumbs.html
    20.530041ms     117.988µs    1.457153ms    174  partials/breadcrumbs.html
    19.765254ms     113.593µs    1.685052ms    174  partials/breadcrumbs.html
    19.293112ms     110.879µs     960.213µs    174  partials/breadcrumbs.html
    26.525782ms     152.447µs    5.964104ms    174  partials/breadcrumbs.html
$ # Benchmarking the breadcrumb template that uses '.Ancestors'
$ for i in {1..10}; do
> rm -r /tmp/hugo_cache
> /tmp/hugo --destination /tmp/public --templateMetrics | grep -F 'partials/breadcrumbs.html'
> done
    11.581039ms      66.557µs     932.621µs    174  partials/breadcrumbs.html
     9.629813ms      55.343µs     281.399µs    174  partials/breadcrumbs.html
    14.392727ms      82.716µs    3.841255ms    174  partials/breadcrumbs.html
     9.619406ms      55.283µs     628.243µs    174  partials/breadcrumbs.html
    10.613697ms      60.998µs     987.308µs    174  partials/breadcrumbs.html
    11.262963ms      64.729µs    1.069025ms    174  partials/breadcrumbs.html
    10.649529ms      61.204µs     485.482µs    174  partials/breadcrumbs.html
    13.811549ms      79.376µs    3.165308ms    174  partials/breadcrumbs.html
     9.685682ms      55.664µs    1.046395ms    174  partials/breadcrumbs.html
    11.274625ms      64.796µs     592.692µs    174  partials/breadcrumbs.html
```

{{<asciicast
    poster="data:text/plain,Terminal output recording during the benchmark">}}
    {{<static-path res breadcrumb-benchmark.cast>}}
{{</asciicast>}}

The following graph models the cumulative duration (*t*) of each template using
a normal distribution.  It shows that the breadcrumb template which uses
`.Ancestors` (represented by the orange curve) is almost always faster than the
one which does not use `.Ancestors` (represented by the blue curve).  The
program used to plot the graph is available [here][benchmark-plot-program].

![Template total execution time modeled using normal distributions](
{{<static-path img exec-time-dist.png>}})

[hugo-docs-template-metrics]: https://gohugo.io/troubleshooting/build-performance/#template-metrics
[benchmark-plot-program]: {{<static-path res plot_exec_time_dist.py>}}
