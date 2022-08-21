---
title: "Goals"
weight: 100
---

Readers are advised to check whether their desired system setup aligns with the
goals of this tutorial to decide whether they should follow it.

## Configuration

The goal assumed by this tutorial is to set up a Gentoo system with the
following configuration:

- A UEFI-based system with an **EFI system partition**.  Throughout this
  tutorial, `/dev/sda1` will be used to identify this partition.  The actual
  block device for the EFI system partition may be different, e.g. `/dev/sdb1`,
  `/dev/nvme0n1p1`; this is normal and expected.  In this case, please replace
  `/dev/sda1` in the instructions with the actual device for the EFI system
  partition.
  - Some systems may be configured to mount the EFI system partition at
    `/boot`, so the EFI system partition also stores the kernel image and
    initramfs.  However, this tutorial assumes that **`/boot` is to be
    encrypted** and the EFI system partition is **not** mounted at `/boot`.
    This allows the kernel image and initramfs to be encrypted and full disk
    encryption to be implemented to the maximum possible extent.

- A single partition to be used as the **LUKS partition**.  `/dev/sda2` will be
  used to identify this partition.  The LUKS partition can be seen and
  identified as a LUKS partition by some partition manager programs even when
  it is locked.
  - The LUKS version to be used will obviously be **LUKS2**.
  - The PBKDF (Password-Based Key Derivation Function) of *all* unlock keys
    will be [**Argon2id**][wikipedia-argon2].
  - All files, except those necessary for loading up GRUB, will be stored in
    this partition to achieve full disk encryption.  Thus, these files and
    directories will be stored here:
    - The initramfs (usually installed as `/boot/initramfs-*.img`)
    - The kernel image (usually installed as `/boot/vmlinuz-*`)
    - The kernel modules (`/lib/modules`)
    - All other system files (those under `/etc`, `/usr`, `/var`, and so on)
    - User files (under `/home`)
  - Another file system may be created on the LUKS partition, and this file
    system cannot be seen when the LUKS partition is locked.  Possible file
    system choices include but are not limited to:
    - A single ext4 file system
    - A Btrfs volume with one or more subvolumes
    - An LVM physical volume with one or more logical volumes

- **GRUB 2.06** is used as the bootloader.
- **systemd** is used as the init system.
- **dracut** is used as the initramfs generator.
  - An initramfs is required for this configuration because unlocking the LUKS
    partition through the init system requires the `cryptsetup` user-space
    program.  The only way to make this program available during the boot
    process is to embed it in an initramfs.

[wikipedia-argon2]: https://en.wikipedia.org/wiki/Argon2

## Resulting Boot Process

The boot process that the instructions in this tutorial are intended to achieve
is described as follows:

1. When GRUB starts, it shows the menu without asking for the passphrase.  This
   will allow the user to enter the passphrase only when it is really needed.
   For example, booting an alternative operating system that is not on the LUKS
   partition (e.g. Microsoft Windows) does not require the passphrase for the
   LUKS partition; neither does using the "UEFI Firmware Settings" option to
   easily launch the computer's BIOS utility.  With the resulting
   configuration, the passphrase will not be asked in these scenarios.
2. When a menu entry for the operating system on the LUKS partition is
   selected, GRUB prompts for the passphrase.  This will be the **only** time
   when the user needs to enter the passphrase.
   ![GRUB asks for passphrase after selecting a menu
   entry]({{< static-path img grub-unlock.png >}})
3. If the passphrase entered is correct, then the boot process continues
   normally.  The passphrase will not be asked anymore during the boot.
   ![GRUB boots the operating system upon successful
   authentication]({{< static-path img grub-unlock-success.png >}})
4. If an incorrect passphrase is supplied, GRUB returns to the menu.  The user
   can retry entering the passphrase by selecting the same menu entry, or
   choose a different entry.
