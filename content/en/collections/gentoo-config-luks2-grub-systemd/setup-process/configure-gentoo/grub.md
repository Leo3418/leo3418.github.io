---
title: "Configure GRUB"
weight: 337
---

## Update GRUB Settings for LUKS

With the default configuration, GRUB disregards operating systems in LUKS
partitions and therefore does not generate menu entries for them.  To let GRUB
probe LUKS partitions and create corresponding menu entries, the following
option needs to be added to `/etc/default/grub`:

```bash
# /etc/default/grub

GRUB_ENABLE_CRYPTODISK=y
```

## Mount the EFI System Partition

Because GRUB needs to install files to the EFI system partition (ESP), the ESP
needs to be mounted before GRUB is installed.  The mount point for the ESP can
be anywhere but `/boot` since the instructions in this tutorial encrypt `/boot`
to achieve full disk encryption.  Common choices of the mount point include
`/boot/efi`, `/efi`, and so on.

Although this is not required, storing the ESP's mount point to an environment
variable temporarily is recommended because a lot of commands below include the
mount point in their arguments, and referring to the mount point using a
variable makes running the commands easier and less error-prone.  From this
tutorial's standpoint, replacing occurrences of the actual mount point with the
variable also allows readers to choose a different ESP mount point easier
because this helps them avoid manually changing the commands in the
instructions.

For those who choose `/boot/efi` as the ESP mount point, run this command:
```console
# ESP="/boot/efi"
```

For those who choose `/efi` as the ESP mount point, run this command:
```console
# ESP="/efi"
```

Then, run these commands to mount the ESP, but remember to replace `/dev/sda1`
with the actual block device for the ESP.

```console
# mkdir -p "${ESP}"
# mount /dev/sda1 "${ESP}"
```

## Optional: Delay GRUB's Passphrase Prompt

At this point, if GRUB has been installed normally, it will be functional and
can unlock the LUKS partition already.  However, it will ask for the LUKS
partition's passphrase *immediately* when it launches, even *before* showing
any menu entries:

![GRUB asks for passphrase directly when it starts]({{< static-path img
grub-start-unlock.png >}})

Users who accept this behavior of GRUB can skip this step and move on to the
next one.

To some users, this behavior may be undesirable because they want to access
some GRUB menu options without entering the passphrase.  After all, some options
do not really need the passphrase because they need not unlock the LUKS
partition, like options to boot an alternative operating system that is not on
the LUKS partition (e.g.  Microsoft Windows), and the “UEFI Firmware Settings”
option for launching the computer’s BIOS utility.  These users might not wish to
unnecessarily enter the passphrase to use these options.

To avoid this behavior of GRUB, these users should move the `/boot/grub`
directory to the ESP, then create a symbolic link to the new directory under
`/boot`:

1. If a new Gentoo installation is being performed, or an existing installation
   where GRUB is not used is being worked with, then please run the following
   command:

   ```console
   # mkdir "${ESP}/grub"
   ```

   If GRUB is already being used as the bootloader, please use this command
   instead to move existing GRUB files to the ESP:

   ```console
   # mv /boot/grub "${ESP}"
   ```

2. Then, **in both cases**, run the following command to set up the symbolic link:

   ```console
   # ln -s "${ESP}/grub" /boot
   ```

Now, GRUB's passphrase prompt is deferred until a menu entry that requires the
LUKS partition to be unlocked is selected.

![GRUB asks for passphrase after selecting a menu entry]({{< static-path img
grub-unlock.png >}})

Moving the contents of the `/boot/grub` directory to the ESP resolves this user
experience issue by making all critical files GRUB needs for full
initialization available before the LUKS partition is unlocked.  By default,
GRUB installs bootloader files to two locations: the ESP for the EFI executable
file, and `/boot/grub` for other files, including the GRUB configuration file
`/boot/grub/grub.cfg`, which contains the menu entries.  If GRUB cannot access
`/boot/grub/grub.cfg` when it launches, it has to ask for the passphrase before
being able to read the file and thus showing the menu entries.

Because GRUB supports customization of these install paths, an alternative
solution is to override the default paths via extra arguments to GRUB's
commands so everything is installed into the ESP directly, making the symbolic
link unnecessary.  But in this case, users must remember to keep overriding the
defaults every time they invoke a GRUB command.  For example, when they run
`grub-mkconfig` to regenerate the GRUB configuration file, they need to use
command `grub-mkconfig -o "${ESP}/grub/grub.cfg"` instead of the conventional
default `grub-mkconfig -o /boot/grub/grub.cfg`.  The symbolic link helps avoid
this: users can keep using `grub-mkconfig -o /boot/grub/grub.cfg` and relying
on GRUB's default behaviors.
{.notice--info}

## Install GRUB

Now, GRUB is ready to be installed/reinstalled as normal:

```console
# grub-install --target x86_64-efi --efi-directory "${ESP}"
# grub-mkconfig -o /boot/grub/grub.cfg
```

Once GRUB has been successfully installed, the system is ready to reboot into
the Gentoo installation on the new LUKS partition.
