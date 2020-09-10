---
title: "Use 'grep' as a Substitute for 'cat'"
lang: en
asciinema-player: true
---

I came across a fascinating and educative article, [Unix Recovery
Legend](https://www.ee.ryerson.ca/~elf/hack/recovery.html), when someone posted
a link to it on Reddit. The article presents a story of the writer, Mario
Wolczko, and some other colleagues attempting to recover a system partially
destructed by `rm -rf /`.

The `rm` command was interrupted before it scraped off directories like `/usr`,
but it was too late to save `/bin`, `/dev` and `/etc`, which were respectively
the directory for basic executable programs, device files, and system
configuration files. Commands like `ls` and `ps` were now on strike since their
executables were in `/bin`, the backup tape could not be mounted because the
tape deck's device entries were gone with `/dev`, and absence of network
configuration files in `/etc` denied any possibility to rescue the system
through the network.

Fortunately, those people still had access to some vital utility programs on
the system. The writer had an instance of GNU Emacs running on his terminal;
even though the executable might have been deleted, the binary had already been
loaded into memory so the program could still run. Therefore, they had a text
editor available. In addition, because the destructive command was interrupted
before it could touch `/usr`, `/usr/bin` was saved. There were a few additional
programs installed to that location instead of `/bin`, and the team of people
rescuing the system was able to use some of them to complete the recovery.

At the end of the article, there was one thing that intrigued me: the writer
suggested using `/usr/bin/grep` as a substitute for `/bin/cat` in case of
deletion of the `cat` program. How could this be done?

`grep` searches for occurrences of strings matching a regular expression in
some text and prints lines that contain any of those occurrences. `cat`, on the
other hand, prints all lines from the sources of input specified in the
command. The major difference between output of `grep` and `cat` is that `grep`
only gives a subset of the lines, whereas `cat` prints all lines
unconditionally. If we can prevent `grep` from filtering out lines so it prints
all of them, then it works effectively the same as `cat`.

The most elegant way to let `grep` give every line of the input is to specify
the empty string as the pattern to be searched for. **The empty string regular
expression matches everything**, so every line is matched, hence be in the
output of `grep`.

{% include asciinema-player.html name="grep-read-file.cast" poster="npt:3.2" %}

Mission complete: for the common and simple usage of `cat` where you just need
to view a single file's contents, `grep ""` can do the same job.

## Create and Write Files Using `grep`
 
For the `cat` program, besides the basic usage of viewing a file's contents
from terminal output, it can also be used to write to files straight from the
shell, without using any text editor. If you just run `cat` without any
arguments, it will read from the standard input (in other words, your keyboard)
instead of any file. When you enter something in the terminal, `cat` will just
repeat what you type by copying the input to its output.

{% include asciinema-player.html name="cat-echo.cast" poster="npt:2" %}

Who would like such a program that would only stupidly repeat what you tell it?
The beauty of this behavior of the `cat` program could never have been seen
without Unix shells' **output redirection**: you can let `cat` write its output
to a file rather than the terminal, so now it will transfer the text you enter
from the keyboard to the file on disk.

{% include asciinema-player.html name="cat-write-file.cast" poster="npt:4" %}

**Tip:** When you have entered everything, press Ctrl-D to send the end-of-file
(EOF) character to the input. The EOF character is the common way to tell Unix
programs that you are done, so they can stop listening to your input and know
they can start processing what you have given to them. For `cat`, once it
receives EOF from the input, it will exit after it has transferred everything
to the output.

Can `grep ""` replace `cat` for the purpose of writing files? Surely it can,
because `grep` also has the similar behavior where if you do not specify files,
it will read from the standard input, though command-line options for `grep`,
like `-r`, can override this behavior.

{% include asciinema-player.html name="grep-echo.cast" poster="npt:2.1" %}

{% include asciinema-player.html name="grep-write-file.cast" poster="npt:5" %}

## Searching for Blank Lines With `grep`

If the empty regular expression is defined to match not only empty strings but
everything, then how should we write the regular expression that is just for
real empty strings, and use `grep` to find blank lines in a file?

In regular expression syntax, there are two special characters, `^` and `$`,
for start and end of a line respectively. For example, the regular expression
`^grep$` only matches `grep`; none of `egrep`, `grep -E`, `fgreping` is
matched. Thus, the regular expression `^$` can be used to select empty lines.
To find empty lines with `grep`, use the command `grep "^$"`.

The `grep` program also supports a `-x` option, which implicitly surrounds the
specified regular expression with `^` and `$`. This means `grep -x ""` is
effectively the same as `grep "^$"`. You can use either of them to search for
blank lines.

{% include asciinema-player.html name="grep-empty-line.cast" poster="npt:5" %}
