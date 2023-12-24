---
title: "Background"
weight: 200
---

This section just explains why someone might want to use full disk encryption
based on LUKS2 and what general difficulties a user might encounter when
setting up LUKS2.  Readers who are familiar with these concepts may feel free
to skip this section.

## Motivation of Full Disk Encryption

Disk encryption is pivotal to protection of sensitive data.  Basic system
authentication mechanisms like login passwords are not adequate for data
protection because adversaries can bypass them by booting up another operating
system in their own external drive and then accessing the file system from
there.  Even if a BIOS password is used to prevent booting from an external
drive, adversaries with access to the computer's internals can still remove the
motherboard battery to reset the password or just plug the internal drive
storing the data into another computer to access it.  Disk encryption
effectively defends against these attacks because adversaries always need to
unlock the disk regardless of which operating system or computer they use to
access it.  When the algorithms and encryption keys are both secure, it is
virtually impossible for someone without a key to unlock the disk.

Full disk encryption goes beyond the ordinary disk encryption by protecting the
operating system's files as well as user data.  Certain types of OS files are
common attack surfaces, like SSH host keys under `/etc/ssh`, Sudo's
configuration file under `/etc/sudoers.d`, Linux kernel's files at `/boot` and
`/lib/modules`, etc.  If they are encrypted too, adversaries cannot tamper with
them to inject malicious configuration or executable code, and the system
integrity is thus better protected.  For example, they cannot replace the
kernel image or user-space executable programs with a modified copy containing
dangerous code because those system files are encrypted too under full disk
encryption.

## Benefits and Complications of LUKS2

Perhaps the best disk encryption solution available on Linux is LUKS2 (Linux
Unified Key Setup version 2).  Compared to LUKS1 -- the previous version, LUKS2
is more resilient to header corruption and still provides modest protection
when a weak passphrase is used.  These enhancements are realized by use of a
second copy of the LUKS header and Argon2id.

However, LUKS2 full disk encryption is not necessarily easy to set up:
- On Gentoo, where many software packages' features can be customized via USE
  flags, the USE flags related to LUKS must be enabled.
- Configuring the GRUB bootloader for LUKS2 with Argon2id is tricky because as
  of version 2.12, GRUB still does not support Argon2id.
- The boot process might prompt for the passphrase twice: GRUB asks for it
  first, and the init system will ask for it again because GRUB cannot pass
  the passphrase or the unlocked state to the init system.
