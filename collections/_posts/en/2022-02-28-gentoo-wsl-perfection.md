---
title: "Refine Gentoo on Windows Subsystem for Linux"
lang: en
tags:
  - Gentoo
  - GNU/Linux
  - Windows
categories:
  - Tutorial
toc: true
---
{% include res-path.liquid %}
This article covers some information that can help perfect a Gentoo
installation on [Windows Subsystem for Linux (WSL)][wsl] to maximize its
performance, improve its interoperability with Windows, and even unlock new
system capabilities.

Originally, I had been planning to write a full Gentoo on WSL installation
tutorial during September of the last year, but that tutorial was only halfway
done before I had to move on for something more important in my real life,
which is why I have disappeared from my personal site for almost another half
of year (though you could find my development activities on GitHub if you
looked at my profile).  Now that I can enjoy a short break with some peace of
mind, I have decided to at least complete that tutorial.  But before I started,
I happened to search for "Gentoo WSL" on Google out of curiosity.  While I had
been away, there was a new [*Gentoo in WSL* article on Gentoo
Wiki][gentoo-wiki-wsl] originally created on November 24, 2021.  That article
already covers the bulk of what I wanted to mention in my tutorial in a very
concise way, and it is easy to find thanks to the fact that it is on Gentoo
Wiki, thus I could no longer see the value of repeating the identical things in
lengthy and verbose paragraphs on my personal site.

Despite this, the Gentoo Wiki article does not contain some arcane things with
regards to setting up Gentoo on WSL that I would like to share with people.
These things might not necessarily make any significant difference, but they
can still improve the user experience of certain use cases.

[wsl]: https://docs.microsoft.com/en-us/windows/wsl/
[gentoo-wiki-wsl]: https://wiki.gentoo.org/wiki/Gentoo_in_WSL

## Use WSL Version 2

Although a setup based on WSL 1 is possible, for the best overall experience,
please use WSL 2 for Gentoo instead of WSL 1.  The main rationale for using WSL
2 is improved file system performance.

Many system administration tasks on Gentoo involve a lot of random file system
operations.  Before a system upgrade, new and updated ebuilds and metadata
cache files need to be synchronized to the system, and it is quite normal for a
sync operation to create and write hundreds of new files, if not thousands.
When a package is being compiled, a lot of files can be created and copied
around the file system too.  Using WSL version 2 rather than 1 will help reduce
sync time and package build times.

The impact of WSL 1's inferior file system performance can be shown clearly
even during the setup process of Gentoo on WSL.  Gentoo stage archives do not
contain the ebuilds in the Gentoo repository, so an initial sync of *all*
ebuilds is needed during the setup.  As of the initial version of this article
is written, there are more than 121,000 files in the Gentoo repository, and
downloading every of them to a distribution using WSL 1 would take more than 10
minutes, whereas on WSL 2, this would need only about one minute.

In addition, on WSL 1, Portage can emit `scanelf: enabling seccomp failed` and
`Unable to unshare: EACCES` warning messages.  This is likely to be caused by
the fact that WSL 1 does not use a real Linux kernel.  On WSL 2, however,
Portage and everything else on Gentoo work perfectly just like on a bare-metal
Gentoo installation because a real Linux kernel is being used.  So, this would
be another reason to prefer version 2 to version 1 when setting up Gentoo on
WSL.

To use WSL 2, simply include `--version 2` at the end of the `wsl --import`
command used to import Gentoo stage3 tarball into WSL:

```console
> wsl --import <Distro> <InstallLocation> <Tarball> --version 2
```

Windows might emit messages saying that some updates need to be installed or
some features need to be enabled.  In this case, follow any instructions given
in the messages to install or enable them.

## Preserve `PATH` Environment Variable Elements Added by Windows

When configured properly, Windows applications and tools can [be launched from
WSL][wsl-run-win-tools] with their commands, which usually end with `.exe`.
WSL achieves this by including the elements of Windows's `PATH` environment
variable in WSL's `PATH` environment variable.  For example, `PATH` in Debian
downloaded from Microsoft Store consists of the following elements:

```console
$ printenv PATH | tr ':' '\n'
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
/usr/games
/usr/local/games
/usr/lib/wsl/lib
/mnt/c/Program Files/WindowsApps/Microsoft.WindowsTerminal_1.11.3471.0_x64__8wekyb3d8bbwe
/mnt/c/Windows/system32
/mnt/c/Windows
/mnt/c/Windows/System32/Wbem
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/
/mnt/c/Users/Leo/AppData/Local/Microsoft/WindowsApps
```

Note the last several `PATH` elements that start with `/mnt` -- these are
members of Windows's `PATH` environment variable.  They correspond to Windows
paths like `C:\Windows\System32`, and they are the key factor that allows
Windows commands to be called from WSL.

However, Gentoo will overwrite those `PATH` elements added by WSL by default,
which will break Windows commands in WSL:

```console
$ printenv PATH | tr ':' '\n'
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
/opt/bin
```

```console
$ ipconfig.exe
-bash: ipconfig.exe: command not found
```

This can be resolved by patching the `sys-apps/baselayout` package on the
Gentoo installation on WSL.  The patch will back up the `PATH` environment
variable set by WSL before Gentoo may overwrite it, then append the backup
value to `PATH` set by Gentoo.

```patch
From 3ef3b5bf3c4911502beb2a35121699e5f08ebfc8 Mon Sep 17 00:00:00 2001
From: root <root@NVMe-Fussy.localdomain>
Date: Mon, 23 Aug 2021 20:41:01 -0700
Subject: [PATCH] Honor PATH elements set by WSL

---
 etc/profile | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/etc/profile b/etc/profile
index 2afd51d..46026b4 100644
--- a/etc/profile
+++ b/etc/profile
@@ -4,12 +4,18 @@
 # environment for login shells.
 #
 
+# Back up PATH set by WSL because it might be overwritten by profile.env
+WSLPATH="${PATH}"
+
 # Load environment settings from profile.env, which is created by
 # env-update from the files in /etc/env.d
 if [ -e /etc/profile.env ] ; then
 	. /etc/profile.env
 fi
 
+export PATH="${PATH}:${WSLPATH}"
+unset WSLPATH
+
 # You should override these in your ~/.bashrc (or equivalent) for per-user
 # settings.  For system defaults, you can add a new file in /etc/profile.d/.
 export EDITOR=${EDITOR:-/bin/nano}
--
2.31.1

```

To apply this patch, use [Portage's user patch feature][etc-portage-patches].
Add this patch as a user patch, then reinstall the `sys-apps/baselayout`
package.  For convenience, the patch can be downloaded directly using [this
link][baselayout-patch].

{% assign patch_name = "baselayout-honor-WSL-PATH.patch" %}

The following commands can be used to add the patch as a user patch and
reinstall `sys-apps/baselayout` with the patch applied:

```console
# mkdir -p /etc/portage/patches/sys-apps/baselayout
# cd /etc/portage/patches/sys-apps/baselayout
# curl -O {{ site.url }}{{ site.baseurl }}{{ res_path }}/{{ patch_name }}
# emerge --ask --oneshot sys-apps/baselayout
```

After that, the `PATH` environment variable in Gentoo will contain elements
added by WSL, and Windows commands can thus be invoked from WSL.

```console
$ printenv PATH | tr ':' '\n'
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
/opt/bin
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
/usr/games
/usr/local/games
/usr/lib/wsl/lib
/mnt/c/Program Files/WindowsApps/Microsoft.WindowsTerminal_1.11.3471.0_x64__8wekyb3d8bbwe
/mnt/c/Windows/system32
/mnt/c/Windows
/mnt/c/Windows/System32/Wbem
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/
/mnt/c/Users/Leo/AppData/Local/Microsoft/WindowsApps
```

As a side effect, WSL will also append several duplicate `PATH` elements that
Gentoo already has, including `/usr/local/bin`, `/usr/bin`, and so on.
Fortunately, in general, duplicate elements in `PATH` do not cause any
functional issues.  Having `PATH` elements added by *both* Gentoo and WSL is
more important because it ensures that both programs installed on Gentoo work
normally and Windows commands can be called from WSL.

{: .notice--success}
Readers who are interested in learning more about Portage's user patch feature
are welcome to read [another article on this website][portage-user-patches]
that discusses it in depth.

[wsl-run-win-tools]: https://docs.microsoft.com/en-us/windows/wsl/filesystems#run-windows-tools-from-linux
[etc-portage-patches]: https://wiki.gentoo.org/wiki//etc/portage/patches
[baselayout-patch]: {{ res_path }}/{{ patch_name }}
[portage-user-patches]: /2021/03/01/portage-user-patches.html

## Automatically Change to WSL User Home Directory upon Gentoo Launch

Users who have been using any Unix environment outside WSL might have gotten
used to the fact that when an instance of the shell is launched, the default
initial working directory is the home directory -- namely `~`.  On WSL,
however, the initial working directory is the Windows user profile directory
`%USERPROFILE%`, whose path is usually `C:\Users\<User Name>`
(`/mnt/c/Users/<User Name>` on WSL).  This is not the same directory as `~`, as
`~` still points to the home directory for the Unix user on WSL.

If using `~` as the initial working directory is more preferable, then simply
add the following script snippet into `~/.bash_profile`.  Remember to replace
`/mnt/c/Users/<User Name>` with the actual path to the Windows user profile
directory on WSL, such as `/mnt/c/Users/Leo`.

```bash
# ~/.bash_profile

if [[ "${PWD}" == "/mnt/c/Users/<User Name>" ]]; then
    cd
fi
```

{: .notice--success}
The instructions in this section should be applicable to any other non-Gentoo
distribution running on WSL as well.

## Start OpenRC upon Gentoo Launch on Windows 11 and Above

Since Windows 11, WSL supports [boot settings][wsl-boot-settings], which allow
a command to be run automatically when a new WSL instance starts.  This feature
can be used to fire up OpenRC when the Gentoo installation on WSL is launched.
OpenRC services, like the OpenSSH daemon, can be started automatically with
OpenRC, so this feature essentially also allows automatic launch of services
upon WSL start.

To start OpenRC with Gentoo on WSL, add the following contents to
`/etc/wsl.conf`.  This will start OpenRC in the `default` runlevel, which is
the suitable runlevel for WSL.

```ini
# /etc/wsl.conf

[boot]
command = "/sbin/openrc default"
```

To make a service start with OpenRC automatically, `rc-update add` may be used,
which adds it to the `default` runlevel.  For example, the following command
makes the OpenSSH daemon service start with OpenRC:

```console
# rc-update add sshd
```

Note that any changes to `/etc/wsl.conf` do not take effect until the Gentoo
installation on WSL restarts.  To trigger a restart, run the following command
*from Windows*:

```console
> wsl --shutdown
```

Then, any daemon processes for services to be started with OpenRC will show up
in a few seconds after Gentoo launches.

```console
$ ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 21:47 ?        00:00:00 /init
root        48     1  0 21:47 ?        00:00:00 /init
root        49    48  0 21:47 ?        00:00:00 /init
leo         51    49  0 21:47 pts/0    00:00:00 -bash
root       689     1  0 21:47 ?        00:00:00 sshd: /usr/sbin/sshd -o PidFile=/run/sshd.pid -f /etc/ssh/sshd_config [listener] 0 of 10-100 startups
leo        780    51  0 21:48 pts/0    00:00:00 ps -ef
```

For the special case of OpenSSH daemon, it may also be tested by attempting to
connect to `localhost` via SSH.

```console
$ ssh localhost
The authenticity of host 'localhost (127.0.0.1)' can't be established.
ED25519 key fingerprint is SHA256:RcHZXSg2QvMxE18VygOGZeJQ7sviL2j+8iPVPKSNFdA.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

{: .notice--info}
To access an OpenSSH daemon running on WSL 2, [extra networking setup
steps][wsl-2-lan] are required.

[wsl-boot-settings]: https://docs.microsoft.com/en-us/windows/wsl/wsl-config#boot-settings
[wsl-2-lan]: https://docs.microsoft.com/en-us/windows/wsl/networking#accessing-a-wsl-2-distribution-from-your-local-area-network-lan
