---
title: "Properly Handling Process Output When Using Java's `ProcessBuilder`"
lang: en
tags:
  - Java
  - GNU/Linux
categories:
  - Blog
  - GSoC 2021
toc: true
asciinema-player: true
---
{% include res-path.liquid %}
Another mysterious disappearance of me from my personal website has happened
after the previous one in last November.  The reason is the same: I had been
quite busy.  But unlike last time, I do not think that the things which kept me
busy in the past month were futile.  I spent significant amount of time helping
students in a [software engineering course][cse-403] for which I was a teaching
assistant, and assisting others is always a meaningful activity in my opinion,
regardless of the type of assistance being offered, the context, the recipient
of the assistance, or the form.

Well, I am certainly planning to write a few articles about my TA experience
and some stories in my job if I get time.  But that is not the main topic for
today at least.  After the course wrapped up, I immediately delved into [my
project for Google Summer of Code 2021][gsoc-proj], which basically can be
summarized as "creating, testing and maintaining Java packages that can be used
on Gentoo".  To be honest, I am required to post a blog with respect to my
project at least once per two weeks, but I certainly would make blog posts on
my own even without this requirement, so I think of it more as a guideline on
my posts' frequency, an excuse to take a break from pushing through the
project, a chance to reflect on my progress, and a means to share anything I
have learned from my activities.

That should be enough for an introduction which I would not need to write if I
had not been inactive for about seven consecutive weeks.  Let us move on to the
actual topic of this post, which is a subtle bug related to Java's
[`ProcessBuilder`][proc-builder-doc] that I came across in my project: if the
standard output of the process created by a `ProcessBuilder` is not consumed,
then the process can hang forever when certain conditions are met.

[cse-403]: https://homes.cs.washington.edu/~rjust/courses/2021Spring/CSE403
[gsoc-proj]: https://summerofcode.withgoogle.com/projects/#5063497366372352
[proc-builder-doc]: https://docs.oracle.com/javase/8/docs/api/java/lang/ProcessBuilder.html

## Background

As mentioned in my project description, I would use a tool from the Gentoo Java
Project called [`java-ebuilder`][java-ebuilder] to assist me to create ebuilds
for Java projects distributed on Maven Central.  `java-ebuilder` is capable of
downloading and parsing metadata files for Maven projects, namely
[POM][maven-pom] files, and generating ebuilds according to the information
obtained from parsing.  For example, it can turn a POM file like
[this][jb-trove-pom] into an ebuild like [this][jb-trove-ebuild], which is
installable in most cases.

Usually, `java-ebuilder` could successfully generate ebuilds for requested
Maven project artifacts, which makes it a quite awesome tool for creating
Gentoo packages for Maven artifacts.  However, I noticed that if
`java-ebuilder` was ran in a fresh new environment, it would almost always hang
without making any progress.  I would have to interrupt the program and re-run
it, and usually the hanging would still persist.  But, after this process was
repeated a few times, `java-ebuilder` would no longer be stuck and could
generate the ebuilds and exit normally.  Sometimes, when I created ebuilds for
a new Maven project, the same thing occurred too.

{% include asciinema-player.html name="casts/hanging-java-ebuilder.cast"
    poster="data:text/plain,Hanging java-ebuilder" %}

{% include asciinema-player.html name="casts/interrupt.cast"
    poster="data:text/plain,Interrupting and re-running java-ebuilder" %}

From a programmer's perspective, when I observe a hanging program, I often
first think of an infinite loop, which is also accompanied by 100% utilization
of a CPU thread.  This did not seem to be the cause of the unexpected behavior
of `java-ebuilder`, because there was not any CPU usage, disk I/O or network
activity when `java-ebuilder` was hanging, and I could not locate any
suspicious loop that could run infinitely in the source code neither.

Since the root cause of this issue was too obscure, and the program could
eventually complete after a few restarts, I did not bother to further
investigate it, until the idea of setting up continuous integration to run the
tests I wrote for `java-ebuilder` emerged.  By default, a CI build's
environment is always a fresh one, so `java-ebuilder` would definitely hang
during a CI build, and interrupting `java-ebuilder` and re-running it for a few
times before running the tests would really not be a magnificent solution.
Therefore, I decided to allot some time to further investigation of this issue
in the hope to fix it and hence run it in a CI environment.

[java-ebuilder]: https://github.com/gentoo/java-ebuilder
[maven-pom]: https://maven.apache.org/guides/introduction/introduction-to-the-pom.html
[jb-trove-pom]: https://repo1.maven.org/maven2/org/jetbrains/intellij/deps/trove4j/1.0.20200330/trove4j-1.0.20200330.pom
[jb-trove-ebuild]: {{ res_path }}/files/trove4j-1.0.20200330.ebuild.txt

## The First Clue

After I was almost determined to unravel this issue's root cause, I started
`java-ebuilder` in a new environment and left it running, as an attempt to both
reproduce the hanging behavior and see if it could eventually get rid of the
stasis if it was given hours of time, then left my computer for a break.  When
I returned after about 10 minutes, I saw something that was never shown before:

```
Exception in thread "main" java.lang.IllegalThreadStateException: process hasn't exited
	at java.lang.UNIXProcess.exitValue(UNIXProcess.java:421)
	at org.gentoo.java.ebuilder.maven.MavenParser.getEffectivePom(MavenParser.java:140)
	at org.gentoo.java.ebuilder.maven.MavenParser.lambda$parsePomFiles$0(MavenParser.java:42)
	at java.util.ArrayList$ArrayListSpliterator.forEachRemaining(ArrayList.java:1384)
	at java.util.stream.ReferencePipeline$Head.forEach(ReferencePipeline.java:647)
	at org.gentoo.java.ebuilder.maven.MavenParser.parsePomFiles(MavenParser.java:41)
	at org.gentoo.java.ebuilder.Main.generateEbuild(Main.java:197)
	at org.gentoo.java.ebuilder.Main.main(Main.java:52)
```

This was definitely a good sign because the stack trace pointed out the precise
location where the program got stuck.  It suggests that `MavenParser.java:140`
is the last line of code in `java-ebuilder` executed before the exception.
Below is a section of `MavenParser.java` containing only the code pertaining to
line 140.  The original content of the file can be found
[here][offending-line].

```java
/*107*/ final ProcessBuilder processBuilder = new ProcessBuilder("mvn", "-f",
                pomFile.toString(), "help:effective-pom",
                "-Doutput=" + outputPath);
        processBuilder.directory(config.getWorkdir().toFile());

        ...

/*115*/ final Process process;

        try {
            process = processBuilder.start();
        } catch (final IOException ex) {
            throw new RuntimeException("Failed to run mvn command", ex);
        }

        try {
            process.waitFor(10, TimeUnit.MINUTES);
        } catch (final InterruptedException ex) {
            config.getErrorWriter().println("ERROR: mvn process did not finish "
                    + "within 10 minute, exiting.");
            Runtime.getRuntime().exit(1);
        }

        ...

/*140*/ if (process.exitValue() != 0) {
            config.getErrorWriter().println(
                    "ERROR: Failed to run mvn command:");
            ...
        }
```

Here is an explanation of what this part of the code is supposed to do in human
language:

1. Since line 107: Start a Maven process with command `mvn -f <pomFile>
   help:effective-pom`.  The `-f` option specifies an alternative POM file, and
   [`help:effective-pom`][effective-pom] instructs Maven to generate an XML for
   the POM.

2. Since line 115: Wait for 10 minutes.  If the Maven process times out, report
   the error and exit.

3. Since line 140: Read the exit status of the Maven process.  If it is
   non-zero, report the error and exit.  Otherwise, continue.

It seems that if the Maven process timed out, Java would signal it with an
`InterruptedException` thrown from the `waitFor` method, so the process was not
supposed to time out if line 140 was ever executed.  However, why did the
message of the exception emitted from the call to the `exitValue` method at
line 140 say that the process still had not exited?  It was because the
`waitFor` method [is specified to][waitfor-javadoc] signal whether the process
has timed out or not with its `boolean` return value.  The
`InterruptedException` is thrown only if the current thread was requested to
stop while it was waiting (more technically, while the `waitFor` call was
blocking), which is a completely different situation.  More information about
the design intention of `InterruptedException` can be found in [this
article][int-ex].  Thus, this part of the code can be rewritten as follows so
it can handle all sorts of exceptional conditions better.

```java
        try {
            final boolean exited = process.waitFor(10, TimeUnit.MINUTES);
            if (!exited) {
                config.getErrorWriter().println("ERROR: mvn process did not "
                    + "finish within 10 minutes, exiting.");
                Runtime.getRuntime().exit(1);
            }
        } catch (final InterruptedException ex) {
            config.getErrorWriter().println("ERROR: mvn process had not "
                    + "finished when the thread waiting for it was "
                    + "interrupted, exiting.");
            Runtime.getRuntime().exit(1);
        }
```

This rewrite only improves error reporting; it still cannot prevent the Maven
process from timing out.  Nevertheless, at least the cause of this issue was
pinpointed to be the hanging Maven process instead of an infinite loop, which
set the direction for subsequent investigation.

[offending-line]: https://github.com/gentoo/java-ebuilder/blob/0.5.1/src/main/java/org/gentoo/java/ebuilder/maven/MavenParser.java#L107
[effective-pom]: https://maven.apache.org/plugins/maven-help-plugin/effective-pom-mojo.html
[waitfor-javadoc]: https://docs.oracle.com/javase/8/docs/api/java/lang/Process.html#waitFor-long-java.util.concurrent.TimeUnit-
[int-ex]: https://www.yegor256.com/2015/10/20/interrupted-exception.html

## A Surprising Discovery

To understand why the Maven process hung, I modified the `MavenParser` class so
it would redirect the Maven process's output to standard output, in the hope
that Maven's output would give me a clue about why and how it would get stuck.
I had not used `ProcessBuilder` before, so I searched for the way to print the
output of a process started by `ProcessBuilder`to standard output, and the most
elegant is to call its [`inheritIO` method][inherit-io].

```diff
         final ProcessBuilder processBuilder = new ProcessBuilder("mvn", "-f",
                 pomFile.toString(), "help:effective-pom",
                 "-Doutput=" + outputPath);
         processBuilder.directory(config.getWorkdir().toFile());
+        processBuilder.inheritIO();
```

With this change applied, Maven's output was printed to standard output as
expected, but `java-ebuilder` could finish normally, even in a new environment!
I swear this line of method call was the only modification I made to
`java-ebuilder` 0.5.1, which was the latest version available from the Gentoo
repository.  What was happening here?

{% include asciinema-player.html name="casts/inherit-io.cast"
    poster="data:text/plain,java-ebuilder running normally when Maven output is redirected" %}

I tried to search on Google with queries like "Java `ProcessBuilder` call
Maven", "Maven called from Java hangs", and "Java `ProcessBuilder` process
hangs", then I finally came across [this Stack Overflow question][so-question],
which had multiple answers all saying that if the output of the created process
is not handled at all, the process might block.  This explained it: adding the
`inheritIO` method call inherently handled the output of the Maven process, so
even it was such a trivial change to `java-ebuilder`, it prevented the Maven
process from hanging.

[inherit-io]: https://docs.oracle.com/javase/8/docs/api/java/lang/ProcessBuilder.html#inheritIO--
[so-question]: https://stackoverflow.com/questions/3285408/java-processbuilder-resultant-process-hangs

## Fixes for the Issue

At this point, it was obvious that fixing this issue only required handling
Maven's output in some way.  Here are a few approaches to output handling:

- Redirect Maven's output to the Java process's output with
  `ProcessBuilder.inheritIO`, as demonstrated above.  Although this could solve
  the issue, it would significantly alter the behavior of `java-ebuilder`
  because originally `java-ebuilder` would not print Maven's output to standard
  output.

- Redirect Maven's output to `/dev/null`, which simulates the common practice
  of discarding a program's output on Unix with a command such as `mvn
  help:effective-pom > /dev/null`.  This can be done with the
  [`ProcessBuilder.redirectOutput` method][redirect-out]:

  ```java
          processBuilder.redirectOutput(new File("/dev/null");
  ```

  This is a fair solution that is OS-dependent.  It would definitely work well
  on Linux-based systems, and it should work fine on systems that implement
  `/dev/null` too.  However, if someone would run `java-ebuilder` on Windows,
  an exception might be thrown because `/dev/null` is not even a valid path on
  Windows.

- Read and discard Maven's output with Java code, like:

  ```java
              process = processBuilder.start();
              final InputStream stdoutInputStream = process.getInputStream();
              final BufferedReader stdoutReader =
                      new BufferedReader(new InputStreamReader(stdoutInputStream));
              while (stdoutReader.readLine() != null) {
                  // Discard the output
              }
  ```

  This solution is guaranteed to be OS-independent but does not look very
  beautiful, as it creates several new objects and uses a `while` loop with an
  empty body for nothing productive.

- Prevent Maven from generating output in the first place.  The `mvn` command
  has a [`-q` flag for quiet output][maven-cli], which will let Maven print
  nothing unless an error occurs.  This would only require changing the command
  used to create the Maven process, which does not alter the expected behavior
  of `java-ebuilder`, is OS-independent (unless the `-q` option of Maven is not
  supported on some systems), and does not need to be implemented with messy
  code.  This is the approach I used in [the patch I submitted to the
  upstream][patch] that fixed this issue.

  ```diff
           final ProcessBuilder processBuilder = new ProcessBuilder("mvn", "-f",
                 pomFile.toString(), "help:effective-pom",
  +              "-q",
                 "-Doutput=" + outputPath);
  ```

[redirect-out]: https://docs.oracle.com/javase/8/docs/api/java/lang/ProcessBuilder.html#redirectOutput-java.io.File-
[maven-cli]: https://maven.apache.org/ref/3.8.1/maven-embedder/cli.html
[patch]: https://github.com/gentoo/java-ebuilder/commit/61ac9154ef648de0dacbc8f1977d093c1374cca4

## Issue Analysis from a Low Level

The issue was successfully fixed, but there were still some unanswered
questions.  Why could `java-ebuilder` complete after being interrupted and
restarted for a few times, even if Maven's output was not handled?  Why does
the last approach in the previous section, which is suppressing Maven's output
with its `-q` flag, work, even though it still does not handle the command's
output at all?

To answer these questions, I decided to look at how the output of a process
created by `ProcessBuilder` is handled by default if the Java client code does
not handle the output at all.  Remember the `UNIXProcess` class appeared in the
first line of the stack trace?  It is what Java uses to represent a Linux
process.  I perused its [source code][unix-proc] and found the following
fields:

```java
final class UNIXProcess extends Process {
    ...

    private /* final */ OutputStream stdin;
    private /* final */ InputStream  stdout;
    private /* final */ InputStream  stderr;

    ...
}
```

The fact that the standard input stream `stdin` has type `OutputStream`, and
the standard output stream `stdout` and the standard error stream `stderr` both
have type `InputStream` might seem counter-intuitive, but it is a sensible
design.  The `UNIXProcess` class can be used by a Java program to interact with
a Unix process, and the Java program might want to pipe data into the Unix
process's standard input and/or read its output.  The
[`write`][ostream-write] methods of `OutputStream` allow the Java program to
write data to the pipe whose output end is connected to the Unix process.
Similarly, the [`read`][istream-read] methods of `InputStream` enable the
Java program to read data from the pipe whose input end is connected to the
Unix process.

I fired up a debugger to inspect the instance of this class for the Maven
process when `java-ebuilder` was being run, and the actual implementation of
`InputStream` used for `stdout` was
[`ProcessPipeInputStream`][proc-pipe-istream], which is a subclass of
[`BufferedInputStream`][buffered-istream] using the default buffer size of 8192
bytes.

Based on these facts, I developed a hypothesis for why the Maven process would
hang from a low level: Maven can generate a lot of output whose size exceeds
the buffer size of `BufferedInputStream`.  After Maven prints some output, the
output string is put into the input stream's buffer and wait for the Java
program to read it, which will also remove it from the buffer at the same time.
However, the Java program never consumes the output, so the string stays in the
buffer forever.  Maven keeps producing output that goes into the buffer, and
eventually the buffer becomes full.  At this point, the buffer no longer
accepts any more incoming strings.  The Maven process is not supposed to
discard its output when the buffer is full because otherwise the program output
would be corrupt.  So, the Maven process must wait until some space in the
buffer is freed up.  This will never happen because the Java program does not
read from the buffer at all, hence the Maven process hangs.

This kind of waiting and hanging is called *blocking*.  When the Maven process
uses blocking to wait for free space in the buffer, it asks the operating
system's process scheduler to wake it up when space is available, then it
suspends, and no CPU resource will be consumed afterwards.  In this particular
case, blocking is more efficient than a loop that does not break until the
buffer is no longer full.  When such a loop runs, it is like the process keeps
asking the operating system if any space has become available in the buffer,
which can be quite noisy and use the CPU a lot as a result.  This explains why
the Maven process did not have CPU usage when it was hanging.

How does Maven's output look like?  Maven has the notion of a [local
repository][maven-repos] which can act as a local cache of remote repositories
like Maven Central.  The local repository is stored at `~/.m2/repository` by
default.  (If you are like me, who is more familiar with Gradle but is still
new to Maven, you may think of this as Maven's version of `~/.gradle`.)  When
Maven needs some files from Maven Central that are not cached locally yet, it
will download them and generate messages like these:

```
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/2.5/maven-clean-plugin-2.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/2.5/maven-clean-plugin-2.5.pom (3.9 kB at 7.8 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/22/maven-plugins-22.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/22/maven-plugins-22.pom (13 kB at 543 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/21/maven-parent-21.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/21/maven-parent-21.pom (26 kB at 732 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/apache/10/apache-10.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/apache/10/apache-10.pom (15 kB at 779 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/2.5/maven-clean-plugin-2.5.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/2.5/maven-clean-plugin-2.5.jar (25 kB at 1.2 MB/s)
```

This can make Maven's output quite verbose, but fortunately, Maven will only
flood the output once when it uses those files for the first time.  After that,
Maven will use the local cached copy of those files and no longer emit those
messages.  This means that the size of Maven's output will shrink after it has
been successfully run once, as long as it does not need to download new files.

How verbose can Maven's output be?  For the 5 Maven files shown in the above
code snippet alone, the output size has already exceeded 1300 bytes.  It is
quite normal for Maven to download hundreds of files in a single execution, so
the buffer is definitely going to be fully occupied in such situation.

With this information, it should be possible to answer those two questions.
Before the buffer was full, `java-ebuilder` was still able to download and
cache a few files, so when it was interrupted and restarted, it could resume
the progress instead of start over.  After a few restarts, it would eventually
complete caching all the required files, from which point `java-ebuilder` would
no longer hang until more files are requested to be downloaded.  When Maven's
`-q` option is set, there was no way for the buffer to get full because no
output string was added to it at all.  Even if Maven would print something with
`-q` enabled due to errors, the error message's size is small enough to fit
into the buffer.

[unix-proc]: https://github.com/openjdk/jdk8u/blob/jdk8u292-b01/jdk/src/solaris/classes/java/lang/UNIXProcess.java
[ostream-write]: https://docs.oracle.com/javase/8/docs/api/java/io/OutputStream.html#write-byte:A-
[istream-read]: https://docs.oracle.com/javase/8/docs/api/java/io/InputStream.html#read--
[proc-pipe-istream]: https://github.com/openjdk/jdk8u/blob/jdk8u292-b01/jdk/src/solaris/classes/java/lang/UNIXProcess.java#L496
[buffered-istream]: https://github.com/openjdk/jdk8u/blob/master/jdk/src/share/classes/java/io/BufferedInputStream.java#L50
[maven-repos]: https://maven.apache.org/guides/introduction/introduction-to-repositories.html

## Another Surprising Discovery

I used the hypothesis introduced in the section above to explain the patch I
submitted to the upstream `java-ebuilder` project in the commit message of the
patch, and there was not any evidence that could reject it until I did an
experiment to verify the correctness of information in this article.  I made a
mistake in that hypothesis, and there was something I was not aware of.

If the claim that a full `BufferedInputStream` caused the Maven process to hang
is true, then running any arbitrary process whose output size exceeds 8192
bytes will make the process hang too.  To check this, I wrote a simple Bash
script that would print a specified number of characters to standard output and
a Java program which would start a process that runs the script with
`ProcessBuilder`.

```bash
#!/usr/bin/env bash

# bytes.sh

if [[ -z "$1" ]]; then
    echo "Usage: $0 NUM"
    echo "Print NUM bytes of characters to standard output."
    exit 1
fi

for (( i=1; i<="$1"; i++ )); do
    echo -n $(( i % 10 ))
done
```

```java
import java.io.IOException;
import java.util.Arrays;
import java.util.concurrent.TimeUnit;

/*
 * Usage:
 * 1. javac BufferSize.java
 * 2. java BufferSize <number of bytes>
 */
public class BufferSize {
    public static void main(String[] args)
            throws IOException, InterruptedException {
        ProcessBuilder procBuilder = new ProcessBuilder("./bytes.sh");
        procBuilder.command().addAll(Arrays.asList(args));
        Process proc = procBuilder.start();
        System.out.println(proc.waitFor(5, TimeUnit.SECONDS));
    }
}
```

The Java program prints `true` if the process it creates has exited before the
5-second timeout, or `false` otherwise.  The expected result was that 8192 is
the largest argument to the program that would cause it to print `true`.
Surprisingly, the program could print `true` for all arguments up to 65,536.
This experiment result suggests that the underlying buffer's capacity is 65,536
bytes instead of 8192, so the underlying buffer used as the default standard
output buffer of a process created by `ProcessBuilder` is not Java's
`BufferedInputStream`.

{% include asciinema-player.html name="casts/experiment.cast"
    poster="data:text/plain,Running the experiment" %}

Instead, the buffer is a pipe allocated by the operating system. The pipe works
in the same way as any pipe created for a Bash command with the `|` operator,
like `find -type f *.java -print0 | xargs -0 javac`.  According to the
[`pipe(7)` manual page][pipe.7], the default pipe capacity in Linux is 65,536
bytes, which is consistent with the result.

This is the only part of the original hypothesis rejected by the experiment
result; other parts of it, especially the consequences after the buffer becomes
full, are still applicable to a pipe.

[pipe.7]: https://man.archlinux.org/man/pipe.7

## Conclusion

If a Java program starts a new process with `ProcessBuilder`, it needs to
either ensure the process's output will not use up the buffer allocated for
standard output, or handle the output in time.  Otherwise, the process will
wait for free space in the buffer after it is full and just hang there if the
buffer's contents are never consumed.

On Linux-based systems, a pipe that allows data to flow from the created
process to the Java program is used as this buffer.  This means that the buffer
size is 65,536 bytes, which is equal to Linux kernel's default pipe capacity.
