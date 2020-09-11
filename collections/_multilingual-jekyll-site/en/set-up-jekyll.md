---
title: "Set Up Jekyll"
ordinal: 10
lang: en
asciinema-player: true
---

First, install Jekyll on your system. You may follow the [installation
guide](https://jekyllrb.com/docs/installation/) on Jekyll's documentation site.

A note on installation if you are using Fedora: even if you follow the steps in
the guide correctly, you might still get this error when running `gem install
jekyll bundler`:

```
current directory: /usr/local/share/gems/gems/http_parser.rb-0.6.0/ext/ruby_http_parser
make "DESTDIR="
gcc -I. -I/usr/include -I/usr/include/ruby/backward -I/usr/include -I.   -fPIC -O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -fPIC -I/usr/local/share/gems/gems/http_parser.rb-0.6.0/ext/ruby_http_parser -m64 -o ruby_http_parser.o -c ruby_http_parser.c
gcc: fatal error: cannot read spec file ‘/usr/lib/rpm/redhat/redhat-hardened-cc1’: No such file or directory
compilation terminated.
make: *** [Makefile:245: ruby_http_parser.o] Error 1
```

In this case, just run `dnf install /usr/lib/rpm/redhat/redhat-hardened-cc1` as
root user, install the packages, and you should be able to continue Jekyll
installation. In addition, when installing dependencies, you can replace
`@development-tools` with `gcc gcc-c++ make` to reduce the number of packages
being installed.

{% include asciinema-player.html name="install-on-fedora.cast"
    poster="data:text/plain,Demo of Installing Jekyll on Fedora" %}

Once you've installed Jekyll, you are ready to initialize your site. There are
two initialization options:

1. Run `jekyll new PATH`, where `PATH` is where you want to store your site's
   source files. This creates a site with pre-applied
   [Minima](https://github.com/jekyll/minima/) theme (the theme this site uses
   as of this collection is composed, in a modified variant), and is a more
   complete starting point for your own site.

2. Run `jekyll new PATH --blank`; then, go to `PATH`, run `bundle init`, and
   add the following to `Gemfile`:

   ```ruby
   gem "jekyll"
   ```

   This just creates a minimal site, which is better for in-depth
   customization.

It's your call, and we will try to cover both methods in this collection.
