---
title: "Gentoo Configuration Guide: systemd"
lang: en
tags:
  - Gentoo
  - GNU/Linux
categories:
  - Tutorial
toc: true
---

As of now, the Gentoo Handbook, which is the official Gentoo installation
guide, mainly focuses on steps to install a system based on OpenRC instead of
systemd.  After all, as a project mainly maintained by Gentoo developers, it
would be a surprise if Gentoo did not introduce OpenRC as the distribution's
init system with primary support.  For people who want to use systemd on
Gentoo, the Handbook does include a few instructions in itself, but it largely
asks the users to refer to the [standalone systemd
article][gentoo-wiki-systemd].  In my opinion, that article is very
comprehensive but is not well organized: commands that should be run during the
installation process scatter around the entire article, making it easy to miss
required steps.  Therefore, this article is created as my effort to come up
with a clear and working procedure for getting systemd to work on Gentoo.

[gentoo-wiki-systemd]: https://wiki.gentoo.org/wiki/Systemd

## How to Interpret This Article's Instructions

The general installation steps of Gentoo are the same regardless of which init
system is used, but there are some details that would change with the choice of
init system.  Users who want to use systemd can follow all Handbook's
instructions to install the operating system, but when it comes to a step in
the Handbook that has extra comments, notes or remarks in this article, please
pay attention to the relevalt information here.

## Configuring the Kernel

Users who want to create their own kernel configuration should make sure all
mandatory options required by systemd listed [here][systemd-kernel-options] are
enabled.

For systemd, an initramfs is probably needed to ensure that `/usr` is mounted
at boot time.  More related information can be found [here][systemd-initramfs].
Note that if a [distribution kernel package][dist-kernel] is used, there is no
need to worry about this matter because all distribution kernel packages build
and use an initramfs by default.

[systemd-kernel-options]: https://wiki.gentoo.org/wiki/Systemd#Kernel
[systemd-initramfs]: https://wiki.gentoo.org/wiki/Systemd#Ensure_.2Fusr_is_present_at_boot_time
[dist-kernel]: https://wiki.gentoo.org/wiki/Project:Distribution_Kernel

## Configuring the System

### Host and Domain Information

For this part, the Handbook's instructions are all for OpenRC, so please ignore
them.  For systemd, the way of editing the hostname when the system is not
running is to edit the file `/etc/hostname` and put nothing but the desired
hostname into the file.  Note that the `hostnamectl` command does not work in
chroot environment.

### Configuring the Network

systemd has a component called `systemd-networkd` that already provides network
interface management capabilities, so users can elect to use it directly
without installing any other packages.  To use `systemd-networkd`, please
ignore all Handbook instructions in this section and peruse the information
given [here][systemd-networkd].

[systemd-networkd]: https://wiki.gentoo.org/wiki/Systemd#systemd-networkd

### Automatically Start Networking at Boot

If `systemd-networkd` is being used, please ignore this Handbook section too,
and run the following command to start `systemd-networkd` and get network
interfaces running at boot if it has not been executed before:

```console
# systemctl enable systemd-networkd.service
```

### Init and Boot Configuration

As of now, the instructions in this section are all applicable to only OpenRC,
so please ignore them for systemd.

## Installing Tools

### Cron Daemon

Although systemd supports timer units, which can replace cron daemons, some
Gentoo packages will still install cron scripts into directories like
`/etc/cron.{daily,hourly}` for tasks they need to run every day or every hour
respectively, even if systemd is installed on the system and the `systemd` USE
flag is enabled.

For example, below is a list of scripts installed into `/etc/cron.daily` on my
system, which runs systemd:

```console
leo@nvme-fussy ~ $ ls /etc/cron.daily/
logrotate  man-db  mlocate  suse.de-snapper
```

While those packages are shipped with one or more corresponding systemd timer
units, they are disabled by default, so users must manually enable them, which
is something they might forget to do.

Therefore, the easiest way to ensure that all scheduled tasks can run as
intended is to install a cron daemon, even if systemd is used.  The cron daemon
runs every script under a `/etc/cron.*` directory at regular intervals, so as
long as a package installs its cron script to one of the `/etc/cron.*`
directories, which most Gentoo packages that contain a scheduled task do, it
will be picked up and handled by the cron daemon without any extra user
intervention required.  There would be no more hassle of manually finding and
enabling systemd timer units for newly-installed packages.

At this point, the Handbook draws readers' attention to `sys-process/cronie`.
Cronie should work fine on systemd; however, there exists
`sys-process/systemd-cron`, a package that integrates those cron scripts under
`/etc/cron.*` directories with systemd better and more tightly. `systemd-cron`
is not a standalone cron daemon like Cronie; rather, it is mainly just a set of
systemd timer units that can run all scripts under `/etc/cron.*` directories at
appropriate times.

Users who wish to install a cron daemon on systemd and use
`sys-process/systemd-cron` as the cron daemon can refer to information over
[here][systemd-cron].

[systemd-cron]: https://wiki.gentoo.org/wiki/Systemd#Replacing_cron

### Remote Access

The Handbook only mentions the command to start `sshd` automatically upon
system boot on OpenRC.  On systemd, the equivalent command is:

```console
# systemctl enable sshd.service
```

### Installing a DHCP Client

`systemd-networkd` has a built-in DHCP client, so there is no need to install a
standalone one.

## Before Rebooting Into the Installed System

At the end of system installation, please make sure to run the following
commands before leaving the chroot environment:

```console
# systemd-machine-id-setup
# systemctl preset-all --preset-mode=enable-only
```

The first command creates a machine ID that systemd journaling and
`systemd-networkd` depend on.  The second command enables systemd units that
should be enabled by default, some of which are vital to basic system
functionality.

## Remarks to the systemd Article on Gentoo Wiki

Those should be all the instructions users need to properly configure systemd
on Gentoo.  The [systemd article][gentoo-wiki-systemd] on Gentoo Wiki contains
some additional useful information pertaining to systemd configuration, and
systemd users are suggested to use it as a reference.  There are a few
additional notes for information in that article.

### `/etc/mtab`

The systemd article says `/etc/mtab` should be a symbolic link to
`/proc/self/mounts`, but chances are this link has already been created in the
stage3 archive the user has downloaded.  To check it, please run:

```console
$ ls -l /etc/mtab
```

If something like the following is shown, then the link has been established
correctly, and there is no need to create it again:

```
lrwxrwxrwx 1 root root 19 Nov 18 23:41 /etc/mtab -> ../proc/self/mounts
```
