---
title: "Gentoo Configuration Guide: Full Disk LUKS2 with GRUB and systemd"
url: "collections/gentoo-config-luks2-grub-systemd"
tags:
  - Gentoo
  - GNU/Linux
categories:
  - Tutorial
show_reading_time: false
aliases:
  - "/2022/08/21/gentoo-config-luks2-grub-systemd"
cascade:
- date: 2022-08-21
- show_date: true
- toc: true
lastmod: 2022-08-21
---

This collection is a tutorial which provides instructions to set up LUKS2-based
full disk encryption on a Gentoo system using GRUB as the bootloader and
systemd as the init system.  In particular, setting up LUKS2 for use with GRUB
is especially tricky, and this tutorial addresses any intricacies there.

This tutorial aims to support both new Gentoo installations and existing ones,
so it can be used to encrypt an unencrypted system too.

This tutorial was originally organized as a single post, but because it ended
up being too long for a post, it has been decomposed into several smaller
articles in this collection.

## Caveats and Disclaimers

- This tutorial depends on **unofficial modifications** to GRUB 2.06.  The
  patches for these modifications are from staged commits for the next GRUB
  release, the [grub-devel mailing list][grub-devel-archive], and a modified
  GRUB package on the [Arch User Repository (AUR)][arch-wiki-aur].  Although
  these patches have been tested by myself and have not exhibited any issues so
  far, and they presumably have also been tested by their original authors,
  reviewers, testers, and some other users too, there is **no guarantee** on
  the modifications' functionality, stability, compatibility, security, or
  performance whatsoever.

- This tutorial gives **no professional advice on computer security**.
  Although I endeavor to make responsible recommendations on security practices
  which *should* help make a system reasonably secure, there is **no
  guarantee** that following this tutorial to the full extent produces an
  invulnerable system.  This particularly applies to any Argon2id parameter
  recommendations in this tutorial.

- Some steps in this tutorial can render existing data on a disk **permanently
  irretrievable**, even when they are performed correctly.  Please make sure
  all important data has been backed up in advance, and there is a known and
  working method to restore the backup after data loss.  I am **not
  responsible** for any irrecoverable data loss.

In general, no guarantee of validity on this tutorial's content is made.  I try
my best to make the information in this tutorial accurate, but still, **use it
at your own risk**.

[grub-devel-archive]: https://lists.gnu.org/archive/html/grub-devel/
[arch-wiki-aur]: https://wiki.archlinux.org/title/Arch_User_Repository
