---
title: "GSoC 2021 Final Work Products"
tags:
  - Gentoo
categories:
  - Blog
  - GSoC 2021
toc: true
lastmod: 2021-08-22
---

As this year's GSoC has come and gone, it is time to compile a retrospective of
all the work I have done for my GSoC project.  In a nutshell, the bulk of my
project was executed as I had planned in my original project proposal; some
additional deliverables and enhancements not outlined in the original plan were
made, while a few planned and relatively trivial deliverables were cut due to
time constraints.

## java-ebuilder

java-ebuilder is the tool maintained and used by the Gentoo Java team to create
ebuilds for Java packages available on Maven Central, and I have used it very
often in my GSoC project too.  To improve the quality of java-ebuilder, I made
some improvements that would be helpful to both its developers and its users to
it.

### System Testing Framework and Test Suite

- Status: Awaiting review
- Location: [The `tests` directory in my fork][java-ebuilder-tests]

Automated and systematic testing can help improve software quality.  With a
canonical, specific and well-defined test suite that can be triggered easily,
developers are more likely to run tests often.  Regression testing, which
assists developers to capture bugs introduced by changes to the source code,
also needs a test suite as its foundation.  For these reasons, I wrote a system
testing framework for java-ebuilder in Bash and added some test cases to verify
the correctness of the entire program.  The testing framework also allowed me
to apply test-driven development when I was implementing new features of
java-ebuilder.

[java-ebuilder-tests]: https://github.com/Leo3418/java-ebuilder/tree/master/tests

### Multi-line `MAVEN_PROVIDES` Definition

- Status: Awaiting review
- Location: [Git
  commit](https://github.com/Leo3418/java-ebuilder/commit/f135f23)

On rare occasions, an ebuild may provide more than one Maven artifact if it
builds multiple JARs or is associated with a virtual artifact on Maven Central.
Such an ebuild can define a `MAVEN_PROVIDES` variable, which is picked up by
java-ebuilder for obtaining the list of all Maven artifacts provided by the
ebuild.  But, java-ebuilder had not been able to recognize `MAVEN_PROVIDES`
values that span across multiple lines.  This java-ebuilder improvement enables
ebuilds to define the value of `MAVEN_PROVIDES` in more than one line, like
this:

```bash
MAVEN_PROVIDES="
    org.jetbrains.kotlin:kotlin-stdlib:1.5.21
    org.jetbrains.kotlin:kotlin-stdlib-common:1.5.21
"
```

### Utilization of ebuild Metadata Cache

- Status: Awaiting review
- Location: [Multiple Git
  commits](https://github.com/Leo3418/java-ebuilder/compare/45e6...d06a)

In addition to Maven artifacts provided by an ebuild, java-ebuilder also
fetches other information from the ebuild, like its `SLOT` variable's value.
However, `SLOT` can be defined using not only a string but also an expression,
which means that all of these `SLOT` definitions are valid:

```bash
SLOT="1.5" # Plain string literal
SLOT="${PV%.*}" # Bash string manipulation
SLOT="$(ver_cut 1-2)" # Version manipulation function for ebuilds
```

This would make it hard for java-ebuilder to get the evaluated value of the
`SLOT` variable.  The original implementation of `SLOT` value reading in
java-ebuilder had failed to cover every possible variant of `SLOT` definition
for this reason.  Thankfully, [fordfrog][gentoo-wiki-fordfrog], a Gentoo Java
team guru and the initial author of java-ebuilder, suggested reading the
evaluated value of `SLOT` from ebuild metadata cache created by
[`egencache`][egencache.1].  fordfrog offered the idea, and I wrote the code
for this enhancement.  In the end, java-ebuilder can use ebuild metadata cache
as a reliable means to get the actual final value of ebuilds' `SLOT` values.

[gentoo-wiki-fordfrog]: https://wiki.gentoo.org/wiki/User:Fordfrog
[egencache.1]: https://dev.gentoo.org/~zmedico/portage/doc/man/egencache.1.html

## Kotlin on Gentoo

The new Kotlin ecosystem on Gentoo is the part of the project I am most proud
of.  The packages and utilities involved comply with existing Gentoo standards
and conventions to the greatest possible extent, and if they can become a part
of Gentoo officially, then Gentoo will be the first GNU/Linux distribution that
ships Kotlin to its users.

### Kotlin Core Library ebuilds That Support Building from Source

- Status:
  - Added to the [Spark overlay][spark-overlay]
  - Awaiting review for official Gentoo adoption
- Information and Documentation: [On Gentoo Wiki][gentoo-wiki-kotlin]

As introduced in [the related blog post][gentoo-build-kt-src], there had not
been any plan to make those ebuilds at all initially because I had not believed
that it would be possible to create them.  The feasibility was discovered by
chance.  Benda, my mentor, said that the fact that packages using Gradle --
like the Kotlin core libraries -- can be built from source within Portage on
Gentoo without invoking Gradle has very significant implications: in the near
future, we might be able to ship many other packages that are supposed to be
built with Gradle, including Android-related packages, to Gentoo users.

[spark-overlay]: https://github.com/6-6-6/spark-overlay
[gentoo-build-kt-src]: /2021/07/05/gentoo-build-kt-src.html
[gentoo-wiki-kotlin]: https://wiki.gentoo.org/wiki/User:Leo3418/Kotlin

### Kotlin eselect Module

- Status:
  - Initial release published
  - [ebuilds][ebuild-eselect-kotlin] added to the Spark overlay
  - Awaiting review for official Gentoo adoption
- Location: [GitHub repository][github-eselect-kotlin]

[ebuild-eselect-kotlin]: https://github.com/6-6-6/spark-overlay/tree/master/app-eselect/eselect-kotlin
[github-eselect-kotlin]: https://github.com/Leo3418/eselect-kotlin

This is an eselect module that allows users to choose a default Kotlin compiler
to use when multiple compiler packages are installed on the system.  For many
programming languages available on Gentoo, multiple versions are provided, and
the users have the ability to choose a default version to use when no version
is explicitly specified.  To follow this convention and offer a better user
experience, the Kotlin eselect module was created to allow users to install
multiple Kotlin versions at once and manage them easily.

### Other Kotlin Library ebuilds

- Status: Added to the Spark overlay
- Locations:
  - [`dev-java/okhttp`][ebuild-okhttp]
  - [`dev-java/okio`][ebuild-okio]
  - [`dev-java/reactor-core`][ebuild-reactor-core]
  - [`kotlin.eclass`][eclass-kotlin]

After creating the new Kotlin core library ebuilds that can be built from
source, I retrofitted existing ebuilds for Kotlin packages in the Spark
overlay, like OkHttp and Okio, to let them depend on those new core library
ebuilds.  To facilitate ebuild writing, a `kotlin.eclass` was added to the
Spark overlay to allow consumer ebuilds of the Kotlin compiler to invoke
`kotlinc` easily.  This eclass can also be used by any new ebuilds that need to
use the Kotlin compiler, which will help the Kotlin ecosystem on Gentoo to
expand quickly in the future.

[ebuild-okhttp]: https://github.com/6-6-6/spark-overlay/blob/master/dev-java/okhttp/okhttp-4.7.2-r2.ebuild
[ebuild-okio]: https://github.com/6-6-6/spark-overlay/blob/master/dev-java/okio/okio-2.6.0-r2.ebuild
[ebuild-reactor-core]: https://github.com/6-6-6/spark-overlay/blob/master/dev-java/reactor-core/reactor-core-3.1.4-r2.ebuild
[eclass-kotlin]: https://github.com/6-6-6/spark-overlay/blob/master/eclass/kotlin.eclass

## Package Testing Solution for the Spark Overlay

Similar to programs themselves, the packages for programs should be tested
thoroughly too.  Even if a program is perfect and bug-free, a problematic
package for the program provided by distributors that cannot properly install
the program on users' systems would still prevent the users from running the
program smoothly.  For the Spark overlay, there is another important purpose of
regular package testing: to detect changes to the official Gentoo software
repository that render packages in the Spark overlay not installable, like
removal of dependencies for example.

In the bulk of the second half of my GSoC project, I worked on various parts
that constitute an automated testing solution which checks packages in the
Spark overlay once a day to detect any issues blocking them from being
installed.  My [previous blog post][ebuild-repos-testing-solution] has already
depicted the high-level design and major components of the testing solution, so
I will not repeat too many details here.

[ebuild-repos-testing-solution]: /2021/08/01/ebuild-repos-testing-solution.html

### ebuild-commander

- Status: Being used in production
- Location: [GitHub repository][github-ebuild-commander]

ebuild-commander is a simple utility that facilitates ebuild testing in Docker
containers.  It allows users to run any shell command for testing ebuilds,
hence the name "ebuild-commander".  More details about ebuild-commander can be
found in my previous blog post, which is linked above.

[github-ebuild-commander]: https://github.com/Leo3418/ebuild-commander

### Gentoo stage3 Docker Image with Java

- Status: Being used in production
- Location: [GitHub repository][github-gentoo-java-image]

This is something I rarely mentioned before because it is too trivial; I did
not even hesitate to put it into the public domain by applying the CC0 license
to it.  It is merely a Docker image based on the `gentoo/stage3` image with a
JDK and some testing utilities for Java packages pre-installed.  Its purpose is
to save the runtime of the tests for the Spark overlay.

[github-gentoo-java-image]: https://github.com/Leo3418/gentoo-java-image

## H2O on Gentoo

- Status: Added to the Spark overlay
- Location: [Multiple Git
  commits](https://github.com/6-6-6/spark-overlay/compare/e89a0fb...18d67d4)

The [H2O machine learning platform][h2o] is mentioned in the original [project
idea][project-idea] description written by Benda and in the title of my [weekly
report][weekly-report-9] emails that I arbitrarily determined when I was
writing the report for the first week, so when I had only one week that I could
work full-time on GSoC left but still had three planned deliverables to create,
I chose to work on H2O first.  Similar to Kotlin, H2O also uses Gradle as the
build system; fortunately, it does not use any fancy Gradle plugin that would
prevent me from successfully compiling the sources with just `javac` in
Portage, and as a result, all H2O ebuilds I created can be compiled from
source.

The H2O components created by me include the Target Encoder plugin, the H2O
Flow web interface, and the H2O Python module.  Due to time constraints, some
extra vital components, such as the XGBoost plugin, are yet to be created.
However, the existing components should be able to support an H2O installation
with basic functionalities.

[h2o]: https://github.com/h2oai/h2o-3/
[project-idea]: https://wiki.gentoo.org/wiki/Google_Summer_of_Code/2021/Ideas/Big_Data_Infrastructure_by_Gentoo
[weekly-report-9]: https://archives.gentoo.org/gentoo-soc/message/31a53bb42366474da4a460b0287a6455

## Fixes for Existing ebuilds in the Spark Overlay

- Status: Added to the Spark overlay
- Location: [Multiple Git
  commits](https://github.com/6-6-6/spark-overlay/compare/be1c8c8...81a5987)

Due to updates and removals of packages in the Gentoo repository, dependencies
of many ebuilds in the Spark overlay had been broken.  To bring the packages in
the Spark overlay back to a working state, I fixed the broken dependencies by
either migrating them to newer versions of updated dependencies or adding
removed dependencies back to the Spark overlay.

Some existing ebuilds in the Spark overlay had been conditionally installable:
they had not been buildable from source due to compiler errors, but users could
have manually enabled the `binary` USE flag for them to install the pre-built
JARs available on Maven Central.  For those packages, I first tried to fix the
compiler errors; if fixing those errors was beyond my ken, then I would enable
the `binary` USE flag for the ebuild by default, so users would not need to
enable it themselves.  The final result is that every package in the Spark
overlay can be installed without any errors with the default package manager
configuration.  The automated daily tests for the Spark overlay will
continuously verify this and emit a notification when new issue emerges.

## Cuts

### Kotlin for Apache Spark

Because the Kotlin core library ebuilds that can be built from source were not
in the original project proposal and took me some time to create and polish, I
fell behind the planned time schedule for about one week and therefore decided
to skip some deliverables in the final part of my project that were relatively
less important and seemed harder to create.  [Kotlin for Apache
Spark][kotlin-spark-api] was one of the dropped deliverables.  Although this
would really be a nice addition to the existing Spark packages in the Spark
overlay, my GSoC project's focus is more on the new H2O packages than the
existing Spark ecosystem in the overlay.  Furthermore, Kotlin for Apache Spark
contained some Scala code, which I thought would be difficult to compile
without errors within Portage because I failed to make any existing package
that used Scala in the Spark overlay buildable from source.  Thus, I cut this
deliverable to ensure sufficient time for other more important deliverables.

[kotlin-spark-api]: https://github.com/JetBrains/kotlin-spark-api

### Sparkling Water

[Sparkling Water][sparkling-water] helps users integrate Spark with H2O.
Because in my original project proposal, the Spark overlay would contain
packages for both Spark and H2O at the end of the project, I had included a
plan to add ebuilds for Sparkling Water to the Spark overlay in the proposal
too.  Sparkling Water also uses Scala, which later led me to consider the
possibility of successful creation of Sparkling Water ebuilds that can be built
from source to be very low.  So, I abandoned the plan on Sparkling Water and
added the Python module for H2O instead as the substitute.

[sparkling-water]: https://github.com/h2oai/sparkling-water

## Acknowledgements and Conclusion

Finally, I would like to take this opportunity to express again my gratitude
towards Benda and fordfrog for their assistance, encouragement and
understanding throughout the project.  I am also grateful to Zongyu, who had
started the Spark overlay in last year's GSoC and set up a robust foundation of
an ebuild repository full of Java packages for Gentoo.

I am thankful for having such a unique opportunity to help improve Gentoo with
clear objectives and plans in mind, in a very systematic manner, and by working
full-time on my GSoC project.  Otherwise, I might have been still a wannabe
Gentoo contributor who submits no more than some small patches.  Because I will
get busy with other non-Gentoo things soon, I expect a transition from a
full-time Gentoo sub-developer back to an occasional contributor again in the
following months, but I am glad to keep maintaining the Spark overlay whenever
time permits.  When I get plenty of free time, I might work on the things I did
not have time to implement during GSoC too.  Or, perhaps it might be better for
me to leave them to the next person who wants to continue improving the Spark
overlay in future GSoC activities, so Benda can still have project ideas for
the next year.  If you happen to be that person and you are reading this,
please feel free to [contact me][gentoo-wiki-Leo3418]!  I am more than happy to
help.

[gentoo-wiki-Leo3418]: https://wiki.gentoo.org/wiki/User:Leo3418
