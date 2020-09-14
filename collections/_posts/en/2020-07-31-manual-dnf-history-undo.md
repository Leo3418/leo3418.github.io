---
title: "Perform Manual 'dnf history undo'"
lang: en
asciinema-player: true
toc: true
---
{% include res-path.liquid %}

My choices of GNU/Linux distributions are Fedora for desktop computers and
CentOS for servers. Both of them feature DNF - Red Hat's package manager
front-end for RPM, which is the primary reason I use these distributions.
Although one might argue that it is slow, DNF is very clear on not only what it
will do for an action but also *what it has done*: it maintains a history of
package installation and removal operations, which are called "transactions".
You can undo a transaction with `dnf history undo` or roll back to a previous
state with `dnf history rollback`. Other common package managers, like APT and
Pacman, also save operation logs, but they generally do not offer a similar
operation reverting functionality.

`dnf history undo` has been helping me keep my system clean. If I have
installed something with DNF but find that it is not what I want, I can
uninstall it, along with *every dependency*, simply with `dnf history undo
last`.

## When `dnf history undo` Fails

`dnf history undo` has been working consistently fine if I run it for a
transaction performed recently, but for transactions ran a while ago, it might
fail.

A month ago, I installed Wine on my laptop so I could play some retro Windows
games on Fedora. After a few weeks, an incompatibility issue of Wine made me go
back to Windows for gaming, so I decided to uninstall Wine.

The first command I ran was `dnf history list wine`, which would give me a list
of all transactions that involved the `wine` package. The output showed that
transaction 217 was the one in which `wine` had been installed.

{% include asciinema-player.html name="view-history.cast" poster="npt:5" %}

Alright, so all I would need to run was `dnf history undo 217`. However, it did
not work as expected...

{% include asciinema-player.html name="failed-history-undo.cast"
    poster="npt:5" %}

I had not removed those Wine packages yet, but why did DNF tell me that no
package was matched? It was because transaction 217
([log]({{ res_path }}/transaction-217.txt)) installed Wine 5.10, but
transaction 229 ([log]({{ res_path }}/transaction-229.txt)), which updated my
system, upgraded Wine to 5.12. `dnf history undo` identifies packages by
combinations of package name, version and architecture instead of merely the
names, so it does not treat `wine-5.10-1.fc32.x86_64` and
`wine-5.12-1.fc32.x86_64` as equivalent packages.

Therefore, **if you have upgraded any package involved in a transaction, then
`dnf history undo` will fail for that transaction**. This is why that command
has been doing its job when I run it for a recent transaction but would emit an
error for a transaction performed a while ago.

## What About `dnf remove`?

The `dnf remove` command is capable of removing unused dependencies along with
the packages requested to be removed, so theoretically, `dnf remove wine` would
do the same thing as `dnf history undo 217` if the packages were not upgraded.
But, when I ran it...

{% include asciinema-player.html name="remove.cast" poster="npt:4" %}

Only 83 packages would be removed by the command. The output of `dnf history
list wine` suggested that 197 packages were installed in transaction 217. If I
had chosen to proceed, 114 unused dependencies would have been left in my
system.

## Manually Undo the Transaction

Although undoing transaction 217 with `dnf history undo` was not possible, the
`dnf history info 217` command could still give the list of packages installed
in that transaction in its [output]({{ res_path }}/transaction-217.txt). I
could gather those packages' names and supply them as arguments to `dnf remove`
in order to perform a complete uninstallation.

Here are some lines in the command output:

```
    ...
    Install pulseaudio-libs-13.99.1-4.fc32.i686                       @updates
    Install samba-common-tools-2:4.12.3-0.fc32.1.x86_64               @updates
    Install samba-libs-2:4.12.3-0.fc32.1.x86_64                       @updates
    Install samba-winbind-2:4.12.3-0.fc32.1.x86_64                    @updates
    Install samba-winbind-clients-2:4.12.3-0.fc32.1.x86_64            @updates
    Install samba-winbind-modules-2:4.12.3-0.fc32.1.x86_64            @updates
    Install sane-backends-drivers-cameras-1.0.30-1.fc32.i686          @updates
    Install sane-backends-drivers-scanners-1.0.30-1.fc32.i686         @updates
    Install sane-backends-libs-1.0.30-1.fc32.i686                     @updates
    Install spirv-tools-libs-2019.5-2.20200421.git67f4838.fc32.i686   @updates
    Install spirv-tools-libs-2019.5-2.20200421.git67f4838.fc32.x86_64 @updates
    ...
```

The packages are listed in their **NEVRA**s - Name, Epoch, Version, Release,
and Architecture - in the form of `name-[epoch:]version-release.arch`. When a
package is upgraded, its `[epoch:]version-release` changes, but `name` and
`arch` will always be constant. Thus, I should convert those NEVRAs from
`name-[epoch:]version-release.arch` to only `name.arch`.

There were 197 packages, and processing all of them by hand would be tedious
and error-prone, so I looked for the way to do the conversion with Unix
programs.

First and foremost, I used `grep` to reduce the command output so it would only
contain lines with a NEVRA. At the beginning of the output were some lines
containing the transaction's metadata, which should be removed. I also saved
the reduced output to a file for subsequent processing.

```console
$ sudo dnf history info 217 | grep 'Install' > /tmp/installed-pkgs.txt
```

{% include asciinema-player.html name="filter-nevras.cast" poster="npt:8" %}

The next thing that should be done was to trim each line so it only contains
the NEVRA itself. This would require me to remove the word "Install", the
repository ID starting with `@`, and any white space. Replacing all occurrences
of a string with another string sounds like a job for `sed`. I used `-i` flag
for in-place modification and `-E` for extended regular expression support.

```console
$ sed -i -E 's/^ *Install *//g' /tmp/installed-pkgs.txt
$ sed -i -E 's/ *@.+$//g' /tmp/installed-pkgs.txt
```

{% include asciinema-player.html name="trim-lines.cast" poster="npt:1.5" %}

At this point, every line in the file contained only the NEVRA in the form of
`name-[epoch:]version-release.arch`. The next step would be further reducing
those lines to the form of `name.arch`. To do this, I needed to come up with a
regular expression for `-[epoch:]version-release`. The following one is the
best I could make:

```
   -([0-9]+:)?[0-9][0-9A-Za-z.-]*\.(el|fc)[0-9]+(_[0-9]+)?(\.[0-9]+)?
1~~^^~~~~2~~~^^~~~~~~~~3~~~~~~~~^^~~~~~~~~~~~4~~~~~~~~~~~^^~~~~5~~~~^
```

As annotated, this regular expression consists of five parts:

1.  The dash `-` is the separator between package name and versioning
    information.

2.  This part is for `epoch`. The purpose of epoch is described
    [here](https://docs.fedoraproject.org/en-US/packaging-guidelines/Versioning/#_upstream_makes_unsortable_changes)
    in Fedora documentation. Not all packages have it, so this part ends with a
    question mark `?`, meaning that it matches 0 or 1 of the preceding group in
    the parentheses.

3.  This section matches `version` and part of `release`. The version should
    start with a digit and may contain multiple digits and dots `.`, but
    chances are it also contains letters, as in `tzdata-2020a`. Letters may
    also exist in release, like `crontabs-1.11-22.20190603git` for example.

4.  This is the value of `%{?dist}` tag in RPM macros, which marks the
    distribution release this package was built for. Example values include
    `.fc32`, `.el8`, and `.el8_2`.

5.  Some packages might have extra minor release bump after `%{?dist}`. Like
    the part for epoch, it also ends with a question mark.

This regular expression should be good for most packages on Fedora and packages
on CentOS and RHEL that stick with Fedora's package versioning guidelines. I
only know one exception, `ntfs-3g-system-compression-1.0-3.fc32.x86_64`,
because it has a digit right after a dash in its package name. Unless you are
dealing with a package whose name meets this criterion, which should be rare,
this issue does not matter.

As a double check, you can first try to see how this regular expression matches
the `-[epoch:]version-release` part of every NEVRA with the following command:

```console
$ grep -E -- '-([0-9]+:)?[0-9][0-9A-Za-z.-]*\.(el|fc)[0-9]+(_[0-9]+)?(\.[0-9]+)?' /tmp/installed-pkgs.txt
```

{% include asciinema-player.html name="check-conversion.cast" poster="npt:7" %}

The matched parts are shown in red. If everything looks good, you can make the
modification with `sed`.

```console
$ sed -i -E 's/-([0-9]+:)?[0-9][0-9A-Za-z.-]*\.(el|fc)[0-9]+(_[0-9]+)?(\.[0-9]+)?//g' /tmp/installed-pkgs.txt
```

{% include asciinema-player.html name="make-conversion.cast"
    poster="npt:1.5" %}

I finally got the list of packages specified in the form of `name.arch` in a
file. All I needed to do at this moment was to pass in every line of the file
to the `dnf remove` command as argument. This is where `xargs` came in handy.
The `-a` option was for telling `xargs` to read the arguments from the
specified file instead of standard input.

```console
$ xargs -a /tmp/installed-pkgs.txt sudo dnf remove
```

{% include asciinema-player.html name="xargs.cast" poster="npt:7" %}

The transaction summary showed that 197 packages would be removed. No unused
packages would remain in my system, and no unrelated packages were accidentally
erased. When you are doing this step, **please double check the number of
packages which will be altered** as well to prevent unexpected changes to your
system. Should you find a mismatch, review any error messages from DNF and your
package list file.

The manual reversal of the transaction with the help of `dnf history info`,
`grep`, `sed`, `xargs` and `dnf remove` was successful. This is yet another
example for the Unix philosophy: multiple general-purpose tools were used
together to complete a specialized and complex task, and they interfaced with
each other through nothing but text streams.

## A Single Command for the Whole Task

In the steps above, I used a file `/tmp/installed-pkgs.txt` to observe how
every command changed the package list more conveniently. Creation of the file
is not necessary: once you are confident about what each command does so you do
not need to study how the list is changed, you can use pipes to let each
command pass its standard output directly to the next command as the standard
input, so no file creation is required at all. This also transforms the whole
process to a single long command.

```console
$ sudo dnf history info <transaction-id> | \
    grep 'Install' | \
    sed -E 's/^ *Install *//g' | \
    sed -E 's/ *@.+//g' | \
    sed -E 's/-([0-9]+:)?[0-9][0-9A-Za-z.-]*\.(el|fc)[0-9]+(_[0-9]+)?(\.[0-9]+)?//g' | \
    xargs -o sudo dnf remove
```

Some notable changes to the commands include:

- The `-i` flag for `sed` is no longer used. Without this flag, `sed` will
  print the edited text to the standard output. Because the standard output
  will be passed to the next program's standard input by a pipe, this is the
  desired behavior.

- Since there is no file involved, the `-a` option for `xargs` is no longer
  needed. Instead, the `-o` flag is used here so you can make input from your
  keyboard to the program you run with `xargs`. DNF will ask for your
  confirmation before it performs the requested operation, and the `-o` option
  of `xargs` will allow you to answer `y` to DNF.
