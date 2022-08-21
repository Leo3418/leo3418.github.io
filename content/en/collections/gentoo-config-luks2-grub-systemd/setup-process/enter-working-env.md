---
title: "Enter the Working Environment"
weight: 310
toc: false
---

The working environment is where the bulk of the steps in this tutorial will be
performed.  It must meet the following criteria:
- A Linux-based system where the kernel has dm-crypt support and the
  `cryptsetup` program has been installed.
- If an existing Gentoo installation is being encrypted, then the working
  environment must be another operating system on a different partition,
  because some following steps require the existing Gentoo installation to be
  not running.

The easiest way to get access to such an environment is to create a bootable
drive from one of the following medias, then restart the computer and boot into
this drive:
- Gentoo minimal installation CD, which has a small size and provides a pure
  command-line environment
- The fairly new Gentoo LiveGUI USB image, which provides a live Gentoo system
  with a desktop environment
- Most GNU/Linux distributions' live ISO image, which usually provides a
  desktop environment too

The Gentoo medias can be obtained from the [Downloads page on the Gentoo
website][gentoo-downloads].  A bootable USB drive can be created using
[instructions on the Gentoo Wiki][gentoo-wiki-liveusb].

[gentoo-downloads]: https://www.gentoo.org/downloads/
[gentoo-wiki-liveusb]: https://wiki.gentoo.org/wiki/LiveUSB
