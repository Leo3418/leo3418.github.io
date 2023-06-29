---
title: "Setup Process"
weight: 300
toc: false
---

The overall setup process consists of the following steps:

1. A working environment where LUKS2 can be set up and a Gentoo installation
   can be configured while it is not running is ready.
2. The LUKS partition is created and opened from the environment.
3. A Gentoo installation that can boot from the LUKS partition is configured in
   the LUKS partition.
   1. LUKS2 and Argon2 support are enabled for software packages that will
      unlock the LUKS partition.
   2. The system is configured so that the passphrase is asked only once during
      boot.
   3. The Linux kernel is configured with support for the LUKS partition.
   4. To improve user experience, GRUB is configured to postpone asking for the
      passphrase until necessary.
4. The LUKS partition's parameters are tuned to achieve an acceptable unlock
   speed in GRUB.
