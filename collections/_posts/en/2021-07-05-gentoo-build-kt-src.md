---
title: "Introducing ebuilds That Build Kotlin Core Libraries from Source"
lang: en
tags:
  - Kotlin
  - Java
  - Gentoo
categories:
  - Blog
  - GSoC 2021
toc: true
asciinema-player: true
excerpt: "An initial and successful attempt to create source-based Kotlin
  packages on Gentoo"
header:
  overlay_image: /assets/img/posts/2021-07-05-gentoo-build-kt-src/kotlin-emerge.png
  overlay_filter: 0.375
  image_description: "Installing ebuilds to build Kotlin libraries from source"
---
{% include img-path.liquid %}
{% include res-path.liquid %}
Since the last blog post regarding my GSoC project was posted, I moved on to
the next part of the project: improvements on the Kotlin ebuilds in the [Spark
overlay][spark-overlay-upstream] created during last year's GSoC, namely
`dev-java/kotlin-common-bin` and `dev-lang/kotlin-bin`.  As shown by the `-bin`
suffix in the packages' names, these are packages that simply install the
Kotlin library and compiler binary JARs pre-built by the upstream instead of
build those artifacts from source like how the vast majority of Gentoo packages
do and how [Gentoo's guidelines][gentoo-java-build-from-src] propose.  At
first, I thought it would be hard to build Kotlin from source *on Gentoo with
Portage*, so I did not make any plan to create separate versions of those
packages without the `-bin` suffix.  Coincidentally, I discovered a possible
way to work around Portage's limitations that would prevent Kotlin from being
built from source, so I immediately started to conduct experiments on building
Kotlin libraries from source within Portage.  The experiment results were
promising, therefore I decided to spend some time working on this and
eventually created ebuilds that can build [Kotlin core
libraries][kotlin-libs-upstream-def] from source with a success.  In this post,
I will cover possible challenges in building a project like the Kotlin
programming language on Gentoo, how my method of building it on Gentoo was
accidentally discovered, and how the final ebuilds were produced.

{% include asciinema-player.html name="kotlin-emerge.cast"
    poster="data:text/plain,Kotlin library ebuilds installation process" %}

[spark-overlay-upstream]: https://github.com/6-6-6/spark-overlay
[gentoo-java-build-from-src]: https://wiki.gentoo.org/wiki/Gentoo_Java_Packing_Policy#Build_from_Source
[kotlin-libs-upstream-def]: https://github.com/JetBrains/kotlin/tree/v1.5.20/libraries#kotlin-libraries

## Difficulty in Building Kotlin from Portage

The [Kotlin programming language project][kotlin-proj] uses Gradle as the build
system, which is not a [Java build system supported by
Portage][portage-java-build-sys] as of now.  At this point, the only supported
Java build system is Apache Ant, which might look like an unpopular legacy
tool.  Then why does it have the privilege to be the only supported Java build
system?  In my personal opinion, the reason is that it is a simple tool which
does only one thing and does it well: it merely compiles the source code and
does not implement the concept of external project dependencies.  Like all
common system package managers, Portage itself can already resolve package
dependency relationships, and Ant handles compilation of Java sources, so there
is a clear separation of concerns here, and the two components complement each
other well.  However, more sophisticated build systems like Maven and Gradle
take over both the duties and do not borrow or lend any dependency with the
outside world.  If Gradle pulls Guava as a dependency, there is not an
effective method for Portage to reuse that copy of Guava yet; if
`dev-java/guava` has been installed via Portage, Gradle does not honor it
either and still pulls a copy of Guava for its own.  Therefore, Portage and
Gradle cannot play together merrily yet, so building Kotlin -- a Gradle project
-- from Portage is not a straightforward task.

Why not just invoke the `gradle` or the Gradle Wrapper `./gradlew` within the
ebuild instead, because after all, a software package on a common GNU/Linux
distribution, including Gentoo, is mostly defined by the set of commands
required to build and install it?  If Kotlin can be built just from a shell
with a series of Gradle commands, what is the point of not doing it?  Well,
here are the reasons against this I can think of.

- Whenever possible, Portage enables the network sandbox when a package is
  being compiled, so no network access can be successfully made during this
  process.  Gradle needs Internet access to pull a project's dependencies, but
  when the network sandbox is enabled, it will just fail.  Although the sandbox
  can be turned off with `FEATURES="-network-sandbox"` as described in
  `make.conf(5)`, requiring the users to disable the sandbox opens up the door
  to attacks.

- Users cannot control the versions of external dependencies used to build
  Kotlin, nor can they use custom versions built with their own patches,
  compromising their freedom.  The Kotlin project depends on some third-party
  libraries like `javax.inject` and JUnit 4, both of which are shipped in the
  Gentoo ebuild repository.  Gentoo users can apply their own patches to those
  libraries just as [what I did once before to fix bugs][portage-user-patches].
  However, if the package is built using Gradle, the copies of those libraries
  used during the compilation would be the ones pulled by Gradle from somewhere
  instead of the ones already installed on the system by Portage.

Therefore, due to the lack of Gradle integration in Portage and suboptimal
effects of invoking Gradle directly from the ebuild, I had not planned to
transform the existing Kotlin ebuilds in the Spark overlay to let them be built
from source in my original project proposal.  But my idea was changed while I
was trying to run the Kotlin project's test suite in those ebuilds...

[kotlin-proj]: https://github.com/JetBrains/kotlin
[portage-java-build-sys]: https://wiki.gentoo.org/wiki/Gentoo_Java_Packing_Policy#Java_build_systems
[portage-user-patches]: /2021/03/01/portage-user-patches.html

## Unraveling Gradle's Secret Recipe for Kotlin Libraries

In my original project proposal, I planned to compile and run the [sample
programs][stdlib-samples] and the [test suite][stdlib-tests] for the Kotlin
Standard Library in the `dev-lang/kotlin-bin` ebuild's `src_test` phase
function to test if the compiler being installed can work properly, but I had
no idea on how the samples and tests should be compiled outside Gradle.  Simple
invocations of `kotlinc` without any custom compiler options did not work, so I
decided to examine how Gradle would compile them.  The first attempt was to run
Gradle with the `--debug` argument in the hope to find the compiler options in
the debug output, and it worked:

```
2021-06-26T10:39:50.067-0700 [DEBUG] [org.gradle.api.Task] [KOTLIN] Kotlin compiler class: org.jetbrains.kotlin.cli.jvm.K2JVMCompiler

2021-06-26T10:39:50.068-0700 [DEBUG] [org.gradle.api.Task] [KOTLIN] Kotlin compiler classpath:
/home/leo/.nobackup/gradle/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-compiler-embeddable/1.4.30-dev-2196/6b72d5881d4cc6f2a9e60317e1d7a4638e1ddd3b/kotlin-compiler-embeddable-1.4.30-dev-2196.jar,
/home/leo/.nobackup/gradle/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-reflect/1.4.30-dev-2196/4675c03eeb4d48d74bd6e6e69802ef6b2884ce1/kotlin-reflect-1.4.30-dev-2196.jar,
... /usr/lib64/openjdk-8/lib/tools.jar

2021-06-26T10:39:50.068-0700 [DEBUG] [org.gradle.api.Task] [KOTLIN] :kotlin-stdlib:compileTestKotlin Kotlin compiler args:
-Xallow-no-source-files
-classpath /home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/classes/java/main:/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/classes/kotlin/main:/home/leo/Projects/forks/kotlin/libraries/stdlib/coroutines-experimental/build/libs/kotlin-coroutines-experimental-compat-1.4.255-SNAPSHOT.jar:...:/home/leo/.nobackup/gradle/.gradle/caches/modules-2/files-2.1/org.hamcrest/hamcrest-core/1.3/42a25dc3219429f0e5d060061f71acb49bf010a0/hamcrest-core-1.3.jar
-d /home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/classes/kotlin/test
-Xfriend-paths=/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/classes/java/main,/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/classes/kotlin/main,/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/libs/kotlin-stdlib-1.4.255-SNAPSHOT.jar
-jdk-home /usr/lib64/openjdk-8 -module-name kotlin-stdlib -no-reflect
-no-stdlib -api-version 1.4
-Xcommon-sources=/home/leo/Projects/forks/kotlin/libraries/stdlib/test/collections/CollectionBehaviors.kt,/home/leo/Projects/forks/kotlin/libraries/stdlib/test/collections/ComparisonDSL.kt,...,/home/leo/Projects/forks/kotlin/libraries/stdlib/common/test/testUtils.kt
-language-version 1.4 -Xmulti-platform -verbose -Xopt-in=kotlin.RequiresOptIn
-Xread-deserialized-contracts -Xjvm-default=compatibility
-Xno-kotlin-nothing-value-exception -Xnormalize-constructor-calls=enable
-Xir-binary-with-stable-abi -Xopt-in=kotlin.RequiresOptIn
-Xopt-in=kotlin.ExperimentalUnsignedTypes -Xopt-in=kotlin.ExperimentalStdlibApi
-Xjvm-default=compatibility
/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/test/collections/CollectionJVMTest.kt
/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/test/collections/IterableJVMTests.kt
...
```

So there were lots of `-X` options used behind the scene, and they are not
documented anywhere, neither in the output of `kotlinc -help` nor in the
official [compiler reference][kotlinc]... good job JetBrains.  But this was a
great discovery: not only could the test suite be successfully compiled with
the additional options shown in the debug output, but the debug log also
contained Kotlin compiler arguments for every Kotlin core library module,
including `kotlin-stdlib` itself.  If what Gradle would use to build the Kotlin
libraries was nothing but the same Kotlin compiler called with the `kotlinc`
command, then it might be possible to build the libraries without using Gradle,
hence they could be built from source on Gentoo with Portage!

```
2021-06-26T10:38:17.046-0700 [DEBUG] [org.gradle.api.Task] [KOTLIN]
:kotlin-stdlib:compileKotlin Kotlin compiler args: -Xallow-no-source-files
-classpath /home/leo/Projects/forks/kotlin/core/builtins/build/libs/builtins-1.4.255-SNAPSHOT.jar:...:/home/leo/Projects/forks/kotlin/libraries/stdlib/common/build/libs/kotlin-stdlib-common-1.4.255-SNAPSHOT.jar:/home/leo/.nobackup/gradle/.gradle/caches/modules-2/files-2.1/org.jetbrains/annotations/13.0/919f0dfe192fb4e063e7dacadee7f8bb9a2672a9/annotations-13.0.jar
-d /home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/classes/kotlin/main
-Xjava-source-roots=/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/src,/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/runtime
-jdk-home /usr/lib64/openjdk-8 -module-name kotlin-stdlib -no-reflect
-no-stdlib -api-version 1.4
-Xcommon-sources=/home/leo/Projects/forks/kotlin/libraries/stdlib/common/src/generated/_Arrays.kt,/home/leo/Projects/forks/kotlin/libraries/stdlib/common/src/generated/_Collections.kt,...,,/home/leo/Projects/forks/kotlin/libraries/stdlib/unsigned/src/kotlin/UnsignedUtils.kt
-language-version 1.4 -Xmulti-platform -verbose -version -Xallow-kotlin-package
-Xallow-result-return-type -Xmultifile-parts-inherit
-Xnormalize-constructor-calls=enable -Xopt-in=kotlin.RequiresOptIn
-Xopt-in=kotlin.ExperimentalMultiplatform
-Xopt-in=kotlin.contracts.ExperimentalContracts -Xinline-classes
-Xuse-14-inline-classes-mangling-scheme -Xjvm-default=compatibility
/home/leo/Projects/forks/kotlin/core/builtins/src/kotlin/ArrayIntrinsics.kt
/home/leo/Projects/forks/kotlin/core/builtins/src/kotlin/Function.kt
/home/leo/Projects/forks/kotlin/core/builtins/src/kotlin/Unit.kt
...
```

After getting the tests to compile in the `dev-lang/kotlin-bin` ebuild, I
immediately started the experiment to build `kotlin-stdlib` from source using
those arguments and was able to get a JAR that [passed
`japi-compliance-checker`][kotlin-stdlib-japi-compliance-checker] and could
[almost pass the `pkgdiff` check][kotlin-stdlib-pkgdiff] with only 7 missing
`kotlin_builtins` files.  I also inspected the compiled JAR myself and it
seemed that most `.class` files were identical to the classes in the JAR
pre-built by the upstream.  This result was really exciting and promising.
Although the compiled JAR was still not perfect, `kotlinc` was able to generate
`.class` files for Kotlin sources that are the same as the ones built by
JetBrains, opening up an opportunity to create the ebuild that compiles
`kotlin-stdlib` from source.

[stdlib-samples]: https://github.com/JetBrains/kotlin/tree/v1.5.20/libraries/stdlib/samples
[stdlib-tests]: https://github.com/JetBrains/kotlin/tree/v1.5.20/libraries/stdlib/test
[kotlinc]: https://kotlinlang.org/docs/compiler-reference.html
[kotlin-stdlib-japi-compliance-checker]: {{ res_path }}/kotlin-stdlib-japi-compliance-checker.html
[kotlin-stdlib-pkgdiff]: {{ res_path }}/kotlin-stdlib-pkgdiff.html

## A Working JAR for Kotlin Standard Library

I was not sure whether or not the `kotlin_builtins` files were really necessary
and was not aware of how they should be built either, so I chose to first test
it by using the JAR created by my ebuild with the Kotlin compiler, a consumer
of the Kotlin Standard Library.  Before I could even compile a Kotlin program,
the following error popped up.

```
$ kotlinc
Exception in thread "main" java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.jetbrains.kotlin.preloading.Preloader.run(Preloader.java:87)
	at org.jetbrains.kotlin.preloading.Preloader.main(Preloader.java:44)
Caused by: java.lang.NoClassDefFoundError: kotlin/jvm/internal/Intrinsics
	at org.jetbrains.kotlin.cli.jvm.K2JVMCompiler$Companion.main(K2JVMCompiler.kt)
	at org.jetbrains.kotlin.cli.jvm.K2JVMCompiler.main(K2JVMCompiler.kt)
	... 6 more
Caused by: java.lang.ClassNotFoundException: kotlin.jvm.internal.Intrinsics
	at java.net.URLClassLoader.findClass(URLClassLoader.java:382)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:418)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:352)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:351)
	at org.jetbrains.kotlin.preloading.MemoryBasedClassLoader.loadClass(MemoryBasedClassLoader.java:75)
	at org.jetbrains.kotlin.preloading.MemoryBasedClassLoader.loadClass(MemoryBasedClassLoader.java:82)
	at org.jetbrains.kotlin.preloading.MemoryBasedClassLoader.loadClass(MemoryBasedClassLoader.java:75)
	at org.jetbrains.kotlin.preloading.MemoryBasedClassLoader.loadClass(MemoryBasedClassLoader.java:82)
	... 8 more
```

So the compiler could not find the class `kotlin.jvm.internal.Intrinsics`.  I
compared the JAR built by my ebuild and the JAR from the upstream again and
could see that the class was missing in my JAR.  This seemed strange until I
searched for the class in the Kotlin project's source tree and found that it
would be compiled to `libraries/stdlib/jvm/build/classes/java/main`, the
compiler output directory for Java sources of the `kotlin-stdlib` module.  The
source file was located at
`libraries/stdlib/jvm/runtime/kotlin/jvm/internal/Intrinsics.java`.

```console
$ find -name 'Intrinsics.class'
./libraries/stdlib/jvm/build/classes/java/main/kotlin/jvm/internal/Intrinsics.class
$ find -name 'Intrinsics.java'
./libraries/stdlib/jvm/runtime/kotlin/jvm/internal/Intrinsics.java
```

This suggested that the Kotlin project also contains some Java source files
which cannot be processed by `kotlinc` but should be compiled with `javac`
instead.  I tried to search for occurrences of the paths mentioned above in the
debug output and was able to find the arguments to `javac` used to build Java
sources including `Intrinsics.java` and was able to find the following log
message in it:

```
2021-06-26T21:01:07.709-0700 [DEBUG]
[org.gradle.api.internal.tasks.compile.NormalizingJavaCompiler] Compiler
arguments: -source 1.6 -target 1.6
-d /home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/classes/java/main
-encoding UTF-8
-h /home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/generated/sources/headers/java/main
-g -sourcepath  -proc:none
-s /home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/generated/sources/annotationProcessor/java/main
-XDuseUnsharedTable=true
-classpath /home/leo/Projects/forks/kotlin/libraries/stdlib/common/build/libs/kotlin-stdlib-common-1.5.255-SNAPSHOT.jar:/home/leo/Projects/forks/kotlin/core/builtins/build/libs/builtins-1.5.255-SNAPSHOT.jar:/home/leo/.nobackup/gradle/.gradle/caches/modules-2/files-2.1/org.jetbrains/annotations/13.0/919f0dfe192fb4e063e7dacadee7f8bb9a2672a9/annotations-13.0.jar:/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/build/classes/kotlin/main
-proc:none -proc:none
/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/runtime/kotlin/jvm/internal/InlineMarker.java
/home/leo/Projects/forks/kotlin/libraries/stdlib/jvm/runtime/kotlin/jvm/internal/MagicApiIntrinsics.java
...
```

Once I added commands to compile those Java sources to my ebuild and built a
new JAR with it, the error was replaced by a different one:

```
$ kotlinc
Exception in thread "main" java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.jetbrains.kotlin.preloading.Preloader.run(Preloader.java:87)
	at org.jetbrains.kotlin.preloading.Preloader.main(Preloader.java:44)
Caused by: java.lang.AssertionError: Built-in class kotlin.Any is not found
	at kotlin.reflect.jvm.internal.impl.builtins.KotlinBuiltIns$3.invoke(KotlinBuiltIns.java:93)
	at kotlin.reflect.jvm.internal.impl.builtins.KotlinBuiltIns$3.invoke(KotlinBuiltIns.java:88)
	...
```

Though I did not fully understand the error message, it mentioned "built-in
class", so I thought it probably had something to do with the `kotlin_builtins`
files.  Again, I looked for files with that file name extension, found where
those files were located, and searched for occurrences of relevant file paths
in the debug log to locate the command used to generate those files.

```console
$ find -name "*.kotlin_builtins"
./core/builtins/build/serialize/kotlin/reflect/reflect.kotlin_builtins
./core/builtins/build/serialize/kotlin/kotlin.kotlin_builtins
./core/builtins/build/serialize/kotlin/collections/collections.kotlin_builtins
./core/builtins/build/serialize/kotlin/coroutines/coroutines.kotlin_builtins
./core/builtins/build/serialize/kotlin/ranges/ranges.kotlin_builtins
./core/builtins/build/serialize/kotlin/annotation/annotation.kotlin_builtins
./core/builtins/build/serialize/kotlin/internal/internal.kotlin_builtins
./idea/testData/decompiler/builtins/test/test.kotlin_builtins
```

```
2021-06-26T20:59:06.995-0700 [DEBUG] [org.gradle.internal.execution.steps.SkipUpToDateStep] Determining if task ':core:builtins:serialize' is up-to-date
2021-06-26T20:59:06.995-0700 [INFO] [org.gradle.internal.execution.steps.SkipUpToDateStep] Task ':core:builtins:serialize' is not up-to-date because:
  No history is available.
2021-06-26T20:59:06.996-0700 [DEBUG] [org.gradle.internal.execution.steps.CreateOutputsStep] Ensuring directory exists for property $1 at /home/leo/Projects/forks/kotlin/core/builtins/build/serialize
2021-06-26T20:59:06.996-0700 [DEBUG] [org.gradle.api.internal.tasks.execution.ExecuteActionsTaskExecuter] Executing actions for task ':core:builtins:serialize'.
2021-06-26T20:59:07.000-0700 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Resolve files of :bootstrapCompilerClasspath' completed
2021-06-26T20:59:07.000-0700 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Resolve files of :bootstrapCompilerClasspath' completed

2021-06-26T20:59:07.004-0700 [INFO]
[org.gradle.process.internal.DefaultExecHandle] Starting process 'command '/usr/lib64/openjdk-8/bin/java''.
Working directory: /home/leo/Projects/forks/kotlin/core/builtins
Command:
/usr/lib64/openjdk-8/bin/java -Didea.io.use.nio2=true -Dfile.encoding=UTF-8
-Duser.country=US -Duser.language=en -Duser.variant
-cp /home/leo/.nobackup/gradle/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-compiler-embeddable/1.5.0-RC-556/a4a87c1d6fc276d05847f573cd4eed855925f890/kotlin-compiler-embeddable-1.5.0-RC-556.jar:...:/home/leo/.nobackup/gradle/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-stdlib-common/1.5.0-RC-556/c559a0e2827828c93165e22edbac2faa1426f5b7/kotlin-stdlib-common-1.5.0-RC-556.jar
org.jetbrains.kotlin.serialization.builtins.RunKt build/serialize src native build/src

2021-06-26T20:59:07.004-0700 [DEBUG] [org.gradle.process.internal.DefaultExecHandle] Changing state to: STARTING
2021-06-26T20:59:07.004-0700 [DEBUG] [org.gradle.process.internal.DefaultExecHandle] Waiting until process started: command '/usr/lib64/openjdk-8/bin/java'.
2021-06-26T20:59:07.007-0700 [DEBUG] [org.gradle.process.internal.DefaultExecHandle] Changing state to: STARTED
2021-06-26T20:59:07.007-0700 [INFO] [org.gradle.process.internal.DefaultExecHandle] Successfully started process 'command '/usr/lib64/openjdk-8/bin/java''
```

Interestingly, the command being called here was `java` instead of `javac`.
`java` was invoked to run the `main` method of class
`org.jetbrains.kotlin.serialization.builtins.RunKt`, which is the class for
"Kotlin built-ins serializer".  The class is compiled into the
`kotlin-compiler.jar` in the Kotlin compiler Zip archive distributed by the
upstream.

```
$ java -classpath /opt/kotlin-bin/lib/kotlin-compiler.jar org.jetbrains.kotlin.serialization.builtins.RunKt
Kotlin built-ins serializer

Usage: ... <destination dir> (<source dir>)+

Analyzes Kotlin sources found in the given source directories and serializes
found top-level declarations to <destination dir> (*.kotlin_builtins files)
```

The classes compiled from Kotlin sources, the classes compiled from Java
sources and the serialized `kotlin_builtins` files are everything needed to
generate a `kotlin-stdlib.jar` that is fully functional and works with the
compiler without obvious issues.

## Kotlin Reflection Library: Dependency Resolution and Package Relocation

The Kotlin JVM compiler depends on just two modules in the Kotlin core
libraries: `kotlin-stdlib` and `kotlin-reflect`.  As the Standard Library could
be built by my ebuilds, I moved on to the reflection library because once the
ebuilds for these two modules were created, I would be able to let the compiler
package `dev-lang/kotlin-bin` depend on them, so users could use the libraries
compiled from source with the compiler.

`kotlin-stdlib.jar` was not hard to build, although doing the build right was
tricky.  As summarized in the previous section, the Kotlin classes, the Java
classes and the serialized built-ins are everything required, and they could be
generated with just three commands.  With the experience of building
`kotlin-stdlib`, I thought `kotlin-reflect` could be built in the same way and
therefore would just be a piece of cake.  As it turned out, building
`kotlin-reflect` was actually not so simple.

For starters, the `kotlin-reflect` module in the Gradle project was not quite
similar to `kotlin-stdlib`.  `kotlin-stdlib` is a self-contained Gradle
subproject which has almost all the source files for `kotlin-stdlib.jar` in it,
whereas `kotlin-reflect` is more like a virtual subproject which does not
contain any source files itself but rather just combines artifacts for [a set
of other subprojects][kotlin-reflect-gradle] together to build
`kotlin-reflect.jar`.  Below is a dependency graph of the `kotlin-reflect`
module I created using IntelliJ IDEA, just to give you a sense of how
complicated `kotlin-reflect` is compared to `kotlin-stdlib`.

![Dependency graph of the 'kotlin-reflect'
module]({{ img_path }}/kotlin-reflect-dep-graph.png)

To deal with such a tangled dependency tree, I created a standalone ebuild for
each of these modules and declared the dependency relationships in the ebuild's
`DEPEND` variable, so the order in which these modules should be built would be
computed by Portage.  ebuild maintainers would not need to worry about that at
all; all they would need to do is to ensure the dependencies are properly
declared in every ebuild.

With a bunch of `dev-java/kotlin-core-*` ebuilds for those `:core:*` Gradle
subprojects, which were created with the help of compiler commands given by the
output of `./gradlew --debug` as well, my `dev-java/kotlin-reflect` ebuild
could complete the compile phase; however, it could not pass the `pkgdiff`
check.  The [`pkgdiff` report][kotlin-reflect-pkgdiff] strangely showed that
many packages that were supposed to be in `kotlin.reflect.jvm.internal.impl`
were "moved" to `org.jetbrains.kotlin` instead of missing.  The Kotlin compiler
complained about the resulting `kotlin-reflect.jar` with an exception too.
This was caused by the package relocation process mentioned at this section's
beginning not being executed.  I looked into the [Gradle build
script][kotlin-reflect-relocate] for the `kotlin-reflect` module again and
found that it would use the [Gradle Shadow Plugin][gradle-shadow-relocate] to
relocate `org.jetbrains.kotlin` to `kotlin.reflect.jvm.internal.impl`:

```
        relocate("org.jetbrains.kotlin", "kotlin.reflect.jvm.internal.impl")
```

This explained the "moved" status in the `pkgdiff` report, so if I could
perform the same package relocation in my ebuilds, `pkgdiff` should shut up
about them.  The question is, how could package relocation be done without any
build system plugin?  I was able to find a [jar-relocator][jar-relocator]
program on GitHub, but there was not a Gentoo package for it, so extra work
would be required if I had chosen to run it from Portage.  At last, I tried to
manually perform package relocation with a simple and primitive method: use
`sed` to replace occurrences of the name of the package being relocated with
the destination package's name in the source files, and change the directory
structure of the source files accordingly.  All of the Gradle subprojects
`kotlin-reflect` depends on would require package relocation, but thankfully,
the Gradle project would relocate them all in the same way, so I wrote a
[`kotlin-core-deps.eclass`][kotlin-core-deps-eclass] to avoid having duplicate
code and put the commands for manual package relocation into the `src_prepare`
phase.

Surprisingly, this dumb way of package relocation worked: the Kotlin compiler
was happy to play with the `kotlin-reflect.jar` produced and could compile
Kotlin programs normally as expected.  `pkgdiff` check almost passed with only
[one extraneous package][kotlin-reflect-pkgdiff-final] listed in the report.  I
tried to remove it from the JAR, but for some reason I still do not know, the
compiler failed to start when that package was absent, which is a discrepancy
between it and the pre-built JAR from the upstream.  Nevertheless, the compiler
seemed to operate normally when `kotlin-reflect.jar` generated by my ebuild was
used, so I did not bother to further investigate this issue, which I did not
have any clue as to any possible solution.

[kotlin-reflect-gradle]: https://github.com/JetBrains/kotlin/blob/v1.5.20/libraries/reflect/build.gradle.kts#L42
[gradle-shadow-relocate]: https://imperceptiblethoughts.com/shadow/configuration/relocation/
[kotlin-reflect-pkgdiff]: {{ res_path }}/kotlin-reflect-pkgdiff.html
[kotlin-reflect-relocate]: https://github.com/JetBrains/kotlin/blob/v1.5.20/libraries/reflect/build.gradle.kts#L108
[jar-relocator]: https://github.com/lucko/jar-relocator
[kotlin-core-deps-eclass]: https://github.com/Leo3418/spark-overlay/blob/07a55d4795e625c0f18ca82901fc3c86905c5941/eclass/kotlin-core-deps.eclass#L128
[kotlin-reflect-pkgdiff-final]: {{ res_path }}/kotlin-reflect-pkgdiff-final.html

## The Final State

The testing on the `kotlin-stdlib.jar` and `kotlin-reflect.jar` created by my
ebuilds did not show any issue.  I ran the Kotlin Standard Library's test suite
against the `kotlin-stdlib.jar` and even built a new `kotlin-stdlib.jar` with
it, and its behavior was the same as the pre-built JAR from the upstream.
Using the `kotlin-stdlib.jar` to build other Kotlin core library members
including `kotlin-stdlib-jdk8` and `kotlin-test-junit` was successful too.
Although the JARs created by the ebuilds were not strictly identical to the
upstream's pre-builts in terms of the list of file contents, I believe the test
results have proved that they are functionally equivalent.

In the end, I successfully created installable and usable ebuilds for version
1.4.32 and 1.5.20 of the following Kotlin core libraries:

- `kotlin-annotations-jvm`
- `kotlin-reflect`
- `kotlin-stdlib`
- `kotlin-stdlib-jdk7`
- `kotlin-stdlib-jdk8`
- `kotlin-stdlib-js`
- `kotlin-test`
- `kotlin-test-annotations-common`
- `kotlin-test-junit`
- `kotlin-test-js`

For each package among `kotlin-annotations-jvm`, all `kotlin-stdlib*` packages
and all `kotlin-test*` packages except those for Kotlin/JS (`kotlin-*-js`), the
JAR created by my ebuild can pass the `pkgdiff` check against the upstream's
pre-built binary JAR run by the
[`java-pkg-simple.eclass`][java-pkg-simple-pkgdiff], and it can pass every test
case in the test suite from the Kotlin project's Git repository that the
pre-built binary JAR can pass.  There are [some test
cases][kotlin-stdlib-failing-test-cases] that will fail for the JARs from my
ebuilds, but the pre-built JARs cannot pass them either, so I am not worried
about them.

`kotlin-reflect`, as stated before in this post, cannot pass the `pkgdiff`
check for unknown reasons.  Maybe it has something to do with the dumb and
simple package relocation method used in my ebuild.  And for the `kotlin-*-js`
packages, `pkgdiff` checks are failing as well because they are essentially
JavaScript libraries instead of Java libraries, and I am not familiar with
building a JavaScript library at all.  I tried my best to reproduce artifacts
identical with the upstream, but ebuilds for those packages still have issues
in source map generation.  I did not choose to invest more time in fixing them
because the main focus of my project is on things pertaining to the JVM, namely
Java libraries and Kotlin/JVM.

`kotlin-test-junit5` and `kotlin-test-testng` are notable libraries provided by
the upstream that are absent from this list because they depend on JUnit 5 and
TestNG 6.13+ respectively, neither of which is included in the Gentoo
repository at this point.

The ebuilds for those Kotlin libraries are not perfect yet.  Though they might
be able to build JARs that are functionally equivalent as the upstream
pre-builts, there are still things that can be improved upon.  For instance,
all upstream pre-built JARs support "multi-release", which means that they
support the Java Platform Module System introduced in Java 9.  There is no such
support in the JARs created by my ebuilds even if a JDK whose version is higher
than 1.8 is used.

Anyway, I believe my work has proved that the Kotlin libraries can be built
from source on Gentoo just like many other programming languages and platforms.
I have to stop here and move on to the other deliverables of my GSoC project,
but to help any other people continue working on Kotlin on Gentoo, I will
provide some documentation with regards to maintaining my ebuilds and expanding
the tree of Kotlin packages.  Maybe we can even build the Kotlin compiler from
source in addition to the Kotlin libraries and submit the ebuilds to the Gentoo
repository in the future, so Gentoo will be the first GNU/Linux distribution
that provides Kotlin in its official software repository.

[java-pkg-simple-pkgdiff]: https://gitweb.gentoo.org/repo/gentoo.git/tree/eclass/java-pkg-simple.eclass#n260
[kotlin-stdlib-failing-test-cases]: https://github.com/Leo3418/spark-overlay/blob/master/dev-java/kotlin-stdlib/kotlin-stdlib-1.5.20.ebuild#L98

## Installing the ebuilds

The ebuilds are currently in [my fork of the Spark
overlay][spark-overlay-fork].  To install them, please first add the Git-based
ebuild repository at `https://github.com/Leo3418/spark-overlay.git` to Portage
and synchronize its contents to the system.  This can be done conveniently with
[`eselect-repository`][eselect-repository]:

```console
# emerge --ask --noreplace app-eselect/eselect-repository dev-vcs/git
# eselect repository add spark-overlay git https://github.com/Leo3418/spark-overlay.git
# emerge --sync spark-overlay
```

Like installation process of many other self-hosted programming languages like
Java and Go on Gentoo, pre-built binaries for the Kotlin libraries must be
installed for bootstrapping before the libraries can be built from source.  To
bootstrap, only `kotlin-stdlib` and `kotlin-reflect` need to be installed
because they are the only two Kotlin core library modules required by the
compiler, as mentioned before.  Then, the Kotlin compiler package
`dev-lang/kotlin-bin` can be installed, completing a binary installation of
Kotlin.  At this point, the Kotlin libraries bootstrapping process has
effectively reached [stage 1][wikipedia-bootstrapping].

```console
# env USE="binary" emerge --ask --oneshot dev-java/kotlin-stdlib dev-java/kotlin-reflect
# emerge --ask dev-lang/kotlin-bin
```

Users who are happy to use a pre-built version of Kotlin can simply stop here.
For those who want to use a version of Kotlin libraries that are built from
source, reinstall `kotlin-stdlib` and `kotlin-reflect` but do not use the
pre-built binaries this time to get to stage 2 of the bootstrapping process.

```console
# emerge --ask --oneshot dev-java/kotlin-stdlib dev-java/kotlin-reflect
```

If other Kotlin library modules like `kotlin-stdlib-jdk8` and
`kotlin-test-junit` are needed, they can also be emerged as long as
`dev-lang/kotlin-bin` has been installed.

```console
# emerge --ask dev-java/kotlin-stdlib-jdk8
```

```console
# emerge --ask dev-java/kotlin-test-junit
```

[spark-overlay-fork]: https://github.com/Leo3418/spark-overlay
[eselect-repository]: https://wiki.gentoo.org/wiki/Eselect/Repository
[wikipedia-bootstrapping]: https://en.wikipedia.org/wiki/Bootstrapping_(compilers)#Process
