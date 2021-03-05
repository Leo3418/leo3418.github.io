---
title: "Merge the `/usr` Directory of a Gentoo Installation"
lang: en
tags:
  - Gentoo
categories:
  - Tutorial
toc: true
last_modified_at: 2021-03-05
---

The *`/usr` merge*, sometimes also known as *`/usr` move*, refers to a process
on a [Filesystem Hierarchy Standard (FHS)][fhs] compliant system, which most
GNU/Linux distributions are, that moves all contents under `/bin`, `/lib`,
`/lib64` and `/sbin` into `/usr/bin`, `/usr/lib`, `/usr/lib64` and `/usr/sbin`
respectively, and then replace each of `/bin`, `/lib`, `/lib64` and `/sbin`
with a symbolic link to the directory with the same name under `/usr`.  More
information about `/usr` merge is available on [freedesktop.org][freedesktop]
and [Fedora Wiki][fedora].

The trend of `/usr` merge in GNU/Linux distributions seemed to be started by
Fedora in 2012, and then, we can see that many well-known and popular
distributions, including Debian and Arch Linux, have made the move.  It was
similar to the wide adoption of systemd in GNU/Linux distributions, both of
which were started by Red Hat's desire to shape all modern Linux-based systems
at *their* discretion and [Lennart Poettering's support][0pointer-de], then
made their debut in Fedora, and finally accepted by other distributions.

Gentoo, being one of the few distributions that still do not use systemd as the
default init system, is also absent from the group of distributions that have
completed the `/usr` merge.  By default, in the root file system of a Gentoo
installation, `/bin`, `/lib`, `/lib64` and `/sbin` are still standalone
directories instead of symbolic links.  But judging from a [`split-usr` global
Portage USE flag][split-usr], there might have already been plans to merge
`/usr` in Gentoo.  As of the current revision of this post was published, the
USE flag was forcibly declared, to indicate that `/bin`, `/lib`, `/lib64` and
`/sbin` were still split from `/usr`; in the future, the USE flag might become
optional when Gentoo is fully ready for the `/usr` merge.

This article will show you how to merge `/usr` on a Gentoo installation now,
when it is yet to be officially supported.  It is by no means suggesting that
`/usr` split is a definitely beneficial decision, and the advantages of `/usr`
merge are not the subject of discussion here.  The sole purpose of this post is
to help people who are interested in making the merge to do it.

{: .notice--danger}
Though it is possible, **merging `/usr` is not officially supported by Gentoo
yet!** Unless you are somewhat confident in resolving arbitrary issues on your
system, particularly those pertinent to system file paths and symbolic links,
it is not advisable to merge `/usr` on Gentoo.

{: .notice--danger}
It is already known that a few packages cannot be installed correctly on a
Gentoo system with `/usr` merged, like `dev-ml/dune`.  Fixing those package
installation issues will typically require you to modify the package's
`ebuild`, so unless you know how to do this right, merging `/usr` is not a good
idea.

[freedesktop]: https://www.freedesktop.org/wiki/Software/systemd/TheCaseForTheUsrMerge/
[fedora]: https://fedoraproject.org/wiki/Features/UsrMove#Detailed_Description
[fhs]: https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
[0pointer-de]: http://0pointer.de/blog/projects/the-usr-merge
[split-usr]: https://packages.gentoo.org/useflags/split-usr

## Variants of `/usr` Merge

It is worth mentioning that there are two different ways of merging `/usr` that
can be found in various GNU/Linux distributions:

1. Merge `/bin` into `/usr/bin`, `/lib` into `/usr/lib`, `/lib64` into
   `/usr/lib64`, and `/sbin` into `/usr/sbin`.  This kind of merge is what
   Fedora and Debian do.
   {: #usr-merge-variant-1}

   ```console
   $ ls -dl /bin /lib /lib64 /sbin /usr/sbin
   lrwxrwxrwx 1 root root    7 Dec 13 14:11 /bin -> usr/bin
   lrwxrwxrwx 1 root root    7 Dec 13 14:11 /lib -> usr/lib
   lrwxrwxrwx 1 root root    9 Dec 13 14:11 /lib64 -> usr/lib64
   lrwxrwxrwx 1 root root    8 Dec 13 14:11 /sbin -> usr/sbin
   drwxr-xr-x 1 root root 7006 Dec 26 09:50 /usr/sbin
   ```

2. Perform not only the merges mentioned above but also another one that moves
   contents of `/usr/sbin` into `/usr/bin`.  Arch Linux merges `/usr` in this
   way, and from the [`ebuild` for Gentoo package
   `sys-apps/baselayout`][baselayout], which already supports the `split-usr`
   USE flag, this is likely to be how Gentoo merges `/usr` too.
   {: #usr-merge-variant-2}

   ```console
   $ ls -dl /bin /lib /lib64 /sbin /usr/sbin
   lrwxrwxrwx 1 root root 7 Dec 13 14:11 /bin -> usr/bin
   lrwxrwxrwx 1 root root 7 Dec 13 14:11 /lib -> usr/lib
   lrwxrwxrwx 1 root root 9 Dec 13 14:11 /lib64 -> usr/lib64
   lrwxrwxrwx 1 root root 7 Dec 13 14:11 /sbin -> usr/bin
   lrwxrwxrwx 1 root root 3 Dec 13 14:11 /usr/sbin -> bin
   ```

{: .notice--info}
The command output snippets above are only for demonstrating the difference of
`/usr/sbin` in both methods of merging `/usr`; they might slightly differ from
the actual file system layout you might encounter.

This article will mainly focus on the first way because the resulting merged
file system layout is what I am personally more familiar with, and I prefer
that layout because I have used Fedora and Debian, but not Arch Linux.  Even if
you would like to perform the second type of merge, this should not matter too
much because it is the way Gentoo devises. Doing the first type of merge, on
the other hand, is actually a little more complicated because of this.  If I
provide you a guide for a more difficult goal, then you should be able to use
it to achieve an easier goal, though you might need to slightly change some
commands for your special situation.

[baselayout]: https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-apps/baselayout/baselayout-2.7.ebuild#n192

## Prerequisites

- The `/usr` merge can be performed either during installation of a new system
  or on an existing installation.  The steps slightly differ, and this article
  will cover both cases in two separate sections.

- Please make sure you have another bootable drive (e.g. a USB drive with
  Gentoo minimal installation CD image applied) available before you start.
  Obviously, if you are installing Gentoo, you must have had such a drive for
  installation.  If you are doing `/usr` merge on an existing system, you will
  need to shut down the system and modify file system layout for the merge
  while the system is not running, so you need another bootable media with an
  environment from which you can work on an existing Gentoo installation.
  {: #bootable-drive}

## Merge During System Installation

The following instruction assumes you are following installation steps outlined
in the [Gentoo Handbook][handbook].

1. After you have [unpacked the stage tarball][unpack-stage] under the
   "Installing stage3" step, enter the extracted `usr` directory, and
   re-extract `./bin`, `./lib`, `./lib64` and `./sbin` from the stage tarball.

   ```console
   livecd /mnt/gentoo # cd usr
   livecd /mnt/gentoo/usr # tar xpvf ../stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner ./{bin,lib,lib64,sbin}
   ```

2. Go back to the parent directory, and replace each of `bin`, `lib`, `lib64`
   and `sbin` with symbolic link to the directory under `usr` with the same
   name.

   ```console
   livecd /mnt/gentoo/usr # cd ..
   livecd /mnt/gentoo # rm -rf bin lib lib64 sbin
   livecd /mnt/gentoo # ln -s usr/bin bin
   livecd /mnt/gentoo # ln -s usr/lib lib
   livecd /mnt/gentoo # ln -s usr/lib64 lib64
   livecd /mnt/gentoo # ln -s usr/sbin sbin
   ```

   <div class="notice--primary" id="variant-2-usr-sbin">
   {{ "If you wish to have the [second type of `/usr`
   merge](#usr-merge-variant-2), you should additionally move everything in
   `usr/sbin` into `usr/bin` and replace `usr/sbin` with a symbolic link to the
   `usr/bin` directory:" | markdownify }}

   {{ "```console
livecd /mnt/gentoo # cd usr
livecd /mnt/gentoo/usr # mv sbin/* bin
livecd /mnt/gentoo/usr # rmdir sbin
livecd /mnt/gentoo/usr # ln -s bin sbin
```" | markdownify }}
   </div>

   The result of this operation is something like the following.  Note that
   `bin`, `lib`, `lib64` and `sbin` are now symbolic links:

   ```console
   livecd /mnt/gentoo # ls -l
   total 16
   lrwxrwxrwx 1 root root    7 Dec 28 04:07 bin -> usr/bin
   drwxr-xr-x 1 root root   10 Dec 23 05:20 boot
   drwxr-xr-x 1 root root 1686 Dec 23 05:25 dev
   drwxr-xr-x 1 root root 1546 Dec 23 06:32 etc
   drwxr-xr-x 1 root root   10 Dec 23 05:20 home
   lrwxrwxrwx 1 root root    7 Dec 28 04:07 lib -> usr/lib
   lrwxrwxrwx 1 root root    9 Dec 28 04:07 lib64 -> usr/lib64
   drwxr-xr-x 1 root root   10 Dec 23 05:20 media
   drwxr-xr-x 1 root root   10 Dec 23 05:20 mnt
   drwxr-xr-x 1 root root   10 Dec 23 05:20 opt
   drwxr-xr-x 1 root root    0 Dec 23 03:28 proc
   drwx------ 1 root root   10 Dec 23 05:20 root
   drwxr-xr-x 1 root root   10 Dec 23 05:20 run
   lrwxrwxrwx 1 root root    8 Dec 28 04:08 sbin -> usr/sbin
   drwxr-xr-x 1 root root   10 Dec 23 05:20 sys
   drwxrwxrwt 1 root root   10 Dec 23 06:32 tmp
   drwxr-xr-x 1 root root  128 Dec 23 05:29 usr
   drwxr-xr-x 1 root root   66 Dec 23 05:20 var
   ```

3. Continue to follow Gentoo Handbook's instruction, until you have [`chroot`ed
   into `/mnt/gentoo`][chroot].

4. Find broken symbolic links under `/usr` by using `find -L /usr -type l`.
   The command's output will show all broken links.
   {: #sys-inst-4}

   ```console
   (chroot) livecd / # find -L /usr -type l
   /usr/sbin/resolvconf
   /usr/bin/awk
   ```

   Here, `/usr/sbin/resolvconf` and `/usr/bin/awk` are broken links -- they
   point to path that does not exist.  This can cause problems when other
   programs and scripts need to use the files pointed by those links.  For
   instance, `awk` is a very important program required for compiling many
   other packages; since `/usr/bin/awk` is a broken symbolic link, the `awk`
   command is unavailable, and you might have trouble installing packages that
   require `awk` to build.

   ```console
   (chroot) livecd / # /usr/bin/awk
   bash: /usr/bin/awk: No such file or directory
   ```

   To fix a broken symbolic link, first enter the directory containing it, then
   use `ls -l` to find the file that link points to.

   ```console
   (chroot) livecd / # cd /usr/bin/
   (chroot) livecd /usr/bin # ls -l awk
   lrwxrwxrwx 1 root root 15 Dec 23 05:26 awk -> ../usr/bin/gawk
   ```

   The `awk` symbolic link was supposed to be under `/bin`, and
   `/bin/../usr/bin/gawk`, which is equivalent to `/usr/bin/gawk`, is a valid
   path.  Because it is now moved to `/usr`, and `/usr/bin/../usr/bin/gawk`,
   i.e. `/usr/usr/bin/gawk`, does not exist, the symbolic link is thus broken.
   To fix it, remove the old link and create a new one with correct target:

   ```console
   (chroot) livecd /usr/bin # rm awk
   (chroot) livecd /usr/bin # ln -s gawk awk
   ```

   Apply the same procedure for `/usr/sbin/resolvconf`:

   ```console
   (chroot) livecd / # cd /usr/sbin/
   (chroot) livecd /usr/sbin # ls -l resolvconf
   lrwxrwxrwx 1 root root 21 Dec 23 06:28 resolvconf -> ../usr/bin/resolvectl
   (chroot) livecd /usr/sbin # rm resolvconf
   (chroot) livecd /usr/sbin # ln -s ../bin/resolvectl resolvconf
   ```

   If you run `find -L /usr -type l` again now, nothing should be printed,
   which indicates that all broken symbolic links have been fixed.

   <div class="notice--success">
   {{ "`find -L -type l` is the panacea for finding broken symbolic links.
   `find` is a basic but powerful command that is usually preinstalled on most
   GNU/Linux distributions.  There is no need to install other packages like
   `symlinks` for this purpose!" | markdownify }}

   {{ "The `find(1)` manual page says:" | markdownify }}
        
   {{ "```
        -type c
               File is of type c:

               l      symbolic link; this is never true if the -L option or the
                      -follow  option is in effect, unless the symbolic link is
                      broken.  If you want to search for symbolic links when -L
                      is in effect, use -xtype.
```" | markdownify }}
   </div>

5. Mask the `split-usr` USE flag, so packages can know the current system has
   its `/usr` merged if they support it.  Declaring `-split-usr` is not
   sufficient to mask the USE flag because `split-usr` is forcibly enabled; you
   need to mask the USE flag in `/etc/portage/profile/use.mask` instead:
   {: #sys-inst-5}

   ```
   # /etc/portage/profile/use.mask

   # Mask the USE flag for split /usr file system layout
   split-usr
   ```

   Please visit [this Gentoo Wiki page][use-mask] for more information.

6. Complete the remaining steps in the Gentoo Handbook as instructed.  Be sure
   to [update the `@world` set][update-world] to apply the `split-usr` USE flag
   change.

   When you run a command installed to `/sbin` or `/usr/sbin`, you may see a
   "command not found" error message.  For example, if you choose GRUB as the
   bootloader, you will need to run `/usr/sbin/grub-install`, but an error will
   occur when it is invoked.  You can use the `whereis` program to confirm that
   the command is installed to `/usr/sbin`.

   ```console
   (chroot) livecd ~ # grub-install --target=x86_64-efi --efi-directory=/boot
   bash: grub-install: command not found
   (chroot) livecd ~ # whereis grub-install
   grub-install: /usr/sbin/grub-install /usr/share/man/man8/grub-install.8.bz2
   ```

   The reason for this error is that `/usr/sbin` is not added to the `PATH`
   environment variable:

   ```console
   (chroot) livecd ~ # printenv PATH
   /usr/local/bin:/usr/bin:/opt/bin
   ```

   To complete the installation, you can use the quickest way to solve this
   issue, which is to add `/usr/sbin` temporarily to `PATH` by running `export
   PATH="/usr/sbin:$PATH"`.  This needs to be done every time when you start a
   new shell.  For a permanent solution, please look at the ["Permanently Add
   `/usr/sbin` to `PATH`"][add-sbin-to-path] section below.

   ```console
   (chroot) livecd ~ # export PATH="/usr/sbin:$PATH"
   (chroot) livecd ~ # printenv PATH
   /usr/sbin:/usr/local/bin:/usr/bin:/opt/bin
   (chroot) livecd ~ # grub-install --target=x86_64-efi --efi-directory=/boot
   Installing for x86_64-efi platform.
   Installation finished. No error reported.
   ```

[handbook]: https://wiki.gentoo.org/wiki/Handbook:Main_Page
[unpack-stage]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Unpacking_the_stage_tarball
[chroot]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Entering_the_new_environment
[use-mask]: https://wiki.gentoo.org/wiki//etc/portage/profile/use.mask
[update-world]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Updating_the_.40world_set
[add-sbin-to-path]: #permanently-add-usrsbin-to-path

## Merge on an Installed System

1. Boot your computer from [the bootable drive][bootable-drive] you prepared,
   and [mount][mount-root] your system's root partition.  The subsequent steps
   assume your root partition is mounted to `/mnt/gentoo`.  Switch to the
   directory where the partition is mounted.

   ```console
   livecd ~ # cd /mnt/gentoo
   ```

2. Using the `\cp` command with `-r`, `--preserve=all` and
   `--remove-destination` options, copy everything inside `bin`, `lib`, `lib64`
   and `sbin` into `usr/bin`, `usr/lib`, `usr/lib64` and `usr/sbin`
   respectively.

   ```console
   livecd /mnt/gentoo # \cp -rv --preserve=all --remove-destination bin/* usr/bin
   livecd /mnt/gentoo # \cp -rv --preserve=all --remove-destination lib/* usr/lib
   livecd /mnt/gentoo # \cp -rv --preserve=all --remove-destination lib64/* usr/lib64
   livecd /mnt/gentoo # \cp -rv --preserve=all --remove-destination sbin/* usr/sbin
   ```

   {: .notice--info}
   The `-v` option for `cp` allows you to see the copying progress.  Feel free
   to omit it if you do not need it.

   <div class="notice--info">
   {{ "Adding a backslash `\` in front of `cp` ignores any alias set for `cp`.
   If you are using the Gentoo minimal installation CD image, the default alias
   for `cp` is `cp -i`, which lets `cp` ask for your confirmation on every file
   being overwritten." | markdownify }}

   {{ "```console
livecd ~ # alias cp
alias cp='cp -i'
```" | markdownify }}

   {{ "Using `\cp` instead of `cp` ignores the alias.  Alternatively, you may
   also use `unalias cp` to remove that alias and continue to invoke `cp`
   without `\` in front, or pipe in a lot of `y`'s with `yes | cp ...`." |
   markdownify }}

   {{ "```console
livecd /mnt/gentoo # unalias cp
livecd /mnt/gentoo # cp -rv --preserve=all --remove-destination bin/* usr/bin
livecd /mnt/gentoo # cp -rv --preserve=all --remove-destination lib/* usr/lib
livecd /mnt/gentoo # cp -rv --preserve=all --remove-destination lib64/* usr/lib64
livecd /mnt/gentoo # cp -rv --preserve=all --remove-destination sbin/* usr/sbin
```" | markdownify }}

   {{ "```console
livecd /mnt/gentoo # yes | cp -rv --preserve=all --remove-destination bin/* usr/bin
livecd /mnt/gentoo # yes | cp -rv --preserve=all --remove-destination lib/* usr/lib
livecd /mnt/gentoo # yes | cp -rv --preserve=all --remove-destination lib64/* usr/lib64
livecd /mnt/gentoo # yes | cp -rv --preserve=all --remove-destination sbin/* usr/sbin
```" | markdownify }}
   </div>

3. Replace each of `bin`, `lib`, `lib64` and `sbin` with symbolic link to the
   directory under `usr` with the same name.

   ```console
   livecd /mnt/gentoo # rm -rf bin lib lib64 sbin
   livecd /mnt/gentoo # ln -s usr/bin bin
   livecd /mnt/gentoo # ln -s usr/lib lib
   livecd /mnt/gentoo # ln -s usr/lib64 lib64
   livecd /mnt/gentoo # ln -s usr/sbin sbin
   ```

   {: .notice--primary}
   If you wish to have the [second type of `/usr` merge][variant-2], you should
   additionally move everything in `sbin` and `usr/sbin` into `usr/bin`, and
   replace `usr/sbin` with a symbolic link to the `usr/bin` directory.  Please
   see [here][variant-2-usr-sbin] for commands you may use to do this.

4. Restart your computer and boot into your system (not the bootable drive).
   As long as you have correctly copied the contents of `/bin`, `/lib`,
   `/lib64` and `/sbin` into `/usr` and established the symbolic links, your
   system should boot up normally.

5. Fix broken symbolic links under `/usr` by following [step 4][sys-inst-4] for
   the method to merge `/usr` during system installation.  However, you do not
   need to manually fix all broken symbolic links:

   - If you use systemd *and* dracut, you may see some broken links whose names
     are something like `dracut-*.service`.  These links can be easily fixed by
     reinstalling `sys-kernel/dracut` **after** systemd is rebuilt with
     `split-usr` USE flag masked.

   - It should be fine to leave `/usr/lib/modules/*.*.*/build` and
     `/usr/lib/modules/*.*.*/source` unfixed.

   Any other broken symbolic links, like `/usr/bin/awk` and
   `/usr/sbin/resolvconf`, still require manual intervention.

6. Mask the `split-usr` USE flag by following [step 5][sys-inst-5] for the
   method to merge `/usr` during system installation.

7. Update the `@world` set of Portage to rebuild packages that had the
   `split-usr` USE flag enabled.

   ```console
   # emerge --ask --update --deep --newuse @world
   ```

   If you are using systemd and dracut, you can rebuild dracut now to fix the
   broken `dracut-*.service` symbolic links.  Run the following command
   **only** if you intend to use dracut, because otherwise it will install
   dracut onto your system.

   ```console
   # emerge --ask --oneshot sys-kernel/dracut
   ```

[bootable-drive]: #bootable-drive
[mount-root]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Mounting_the_root_partition
[variant-2]: #usr-merge-variant-2
[variant-2-usr-sbin]: #variant-2-usr-sbin
[sys-inst-4]: #sys-inst-4
[sys-inst-5]: #sys-inst-5

## Additional Tasks

After following the steps above, your file system is `/usr`-merged, and the
operating system should still function as if `/usr` is not merged.  There are
some additional tasks which would not cause system to malfunction if you chose
not to perform them, but they fix minor issues which would arise after `/usr`
merge.

### Permanently Add `/usr/sbin` to `PATH`

{: .notice--primary}
This task is not required if you are using the [second variant of `/usr`
merge][variant-2].

As mentioned briefly when [discussing how Gentoo intends to merge
`/usr`][variant-2], `/usr/sbin` is planned to be merged into `/usr/bin`.  If
you look carefully at the [`ebuild` for `sys-apps/baselayout`][baselayout], you
may find that when the `split-usr` USE flag is disabled, `/usr/sbin` is removed
from the `PATH` environment variable, because every file that was supposed to
be under `/usr/sbin` is now in `/usr/bin`, which is already in `PATH`.

However, if you are doing the [first kind of `/usr` merge][variant-1], this is
not the desired result.  Executables under `/usr/sbin` are not moved in this
case, but `/usr/sbin` is removed from `PATH` if we disable the `split-usr` USE
flag, so we cannot directly invoke any command installed to that location
without prepending `/usr/sbin/` to the front of the command name!

The way I suggest to add `/usr/sbin` back to `PATH` is to define it globally
with a file under `/etc/env.d`.  Create a file with any name you like (e.g.
`50baselayout-sbin`) under that path, and add the following `PATH` and
`ROOTPATH` definitions:

```sh
# /etc/env.d/50baselayout-sbin

PATH="/usr/local/sbin:/usr/sbin"
ROOTPATH="/usr/local/sbin:/usr/sbin"
```

In this example, I have added not only `/usr/sbin` but also `/usr/local/sbin`
to `PATH` because `/usr/local/sbin` is removed from `PATH` if `split-usr` is
disabled for `sys-apps/baselayout` too.

Then, update your environment to apply the change:

```console
# /usr/sbin/env-update
$ source /etc/profile
```

For more information about using the `/etc/env.d` directory, please refer to
[this Gentoo Handbook section covering it][etc-env.d].

[variant-1]: #usr-merge-variant-1
[etc-env.d]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Working/EnvVar#Defining_variables_globally

### Remove Messages Regarding Symbolic Links from `emerge`

You may see a warning message like the following one when you update or
uninstall a package with `emerge`:

```
 * One or more symlinks to directories have been preserved in order to
 * ensure that files installed via these symlinks remain accessible. This
 * indicates that the mentioned symlink(s) may be obsolete remnants of an
 * old install, and it may be appropriate to replace a given symlink with
 * the directory that it points to.
 *
 * 	/bin
 * 	/lib64
 * 	/sbin
 *
```

This kind of messages is expected, because `/bin`, `/lib`, `/lib64` and `/sbin`
are indeed symbolic links rather than directories now.

If you are interested in suppressing those messages, you may add the following
line to `/etc/portage/make.conf`:

```sh
UNINSTALL_IGNORE="/bin /lib /lib64 /sbin"
```
