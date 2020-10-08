---
title: "USB Issue on Raspberry Pi 4 Running Fedora - Complex Solution"
lang: en
tags:
  - Raspberry Pi
  - Fedora
categories:
  - Tutorial
toc: true
last_modified_at: 2020-10-07
---

In [the previous post](/2020/09/20/raspi4-fedora-usb-simple.html) we looked at
a very simple solution to fix the USB ports on Raspberry Pi 4B 4GB/8GB RAM
models running Fedora, which involves a trade-off between the USB ports'
functionality and the amount of RAM available to the operating system. This
post will give you another solution that takes more steps but no longer limits
available memory to 3 GiB.

As said in the previous post, no action is required for the 2GB model. The
symptoms of this issue are available
[there](/2020/09/20/raspi4-fedora-usb-simple.html#symptoms) as well.

## Overview

You probably are already feeling this solution is not so simple just by finding
that an overview section like this is needed for it. To summarize, this
solution involves using the bootloader and firmware of *openSUSE* - another
GNU/Linux distribution - on Fedora. So, you will need to
- obtain those files from openSUSE,
- copy them to the SD card on which you have installed Fedora, then
- modify openSUSE's boot configuration file for Fedora.

I will go over many details on how each step should be performed. From the
length and content of this post, you might think the procedure is complicated,
but it really boils down to only these objectives.

## Obtain Files from openSUSE

### Download openSUSE's Image

For the mere purpose of extracting some critical boot and firmware files, I
would recommend downloading the *openSUSE Leap JeOS* image. *Leap* is
openSUSE's regular release channel, so it is supposed to be more stable. JeOS
stands for *Just enough Operating System*, which is a minimal distribution
without a desktop environment, helping to reduce download size and disk usage.

As of this post was initially composed, the newest version of the openSUSE Leap
JeOS image for Raspberry Pi 4 was [Leap
15.2](http://download.opensuse.org/ports/aarch64/distribution/leap/15.2/appliances/openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64.raw.xz).
You may also get the latest image from [this
page](https://en.opensuse.org/HCL:Raspberry_Pi4) on the openSUSE Wiki.

### Extract the Image

The downloaded file is a `.xz` file, a compressed image. Before doing anything
with the image, you need to decompress the `.xz` file.

If the `xz` program is available to you, you may decompress the file with the
following command:

```console
$ xz -dv openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw.xz
```

{: .notice--info}
Depending on the version of the image you download and where you download it
to, you might need to change the file name in this command and all subsequent
commands in the later steps.

In this command, the `-d` flag tells `xz` to decompress. The `-v` flag is
optional, as it does nothing more than enabling progress reporting.

When the command completes, the decompressed image replaces the original `.xz`
file in the same directory, with the `.xz` suffix removed.

### Mount the Image

After the image is decompressed, it can be mounted so you are able to copy out
the files in it. The image consists of multiple partitions; the main focus is
on the first of them, which is the boot partition and contains the files you
will need. Therefore, you just need to mount the first partition of the image.

You may use whatever tool available on your operating system for mounting, as
long as you can achieve the goal of this step, which is to ensure you can copy
the files in that partition from the openSUSE image to the SD card containing
your Fedora installation.

The following instructions are for mounting the image's first partition on a
GNU/Linux system with the `mount` program.

1. Get the offset of the boot partition in the image. This information is
   available indirectly from `fdisk`.

   ```console
   $ fdisk -l openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw
   Disk openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw: 2.2 GiB, 2353004544 bytes, 4595712 sectors
   Units: sectors of 1 * 512 = 512 bytes
   Sector size (logical/physical): 512 bytes / 512 bytes
   I/O size (minimum/optimal): 512 bytes / 512 bytes
   Disklabel type: dos
   Disk identifier: 0x52b80fee

   Device                                                                     Boot   Start     End Sectors  Size Id Type
   openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw1         2048  133119  131072   64M  c W95
   openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw2       133120 1157119 1024000  500M 82 Linu
   openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw3      1157120 4595678 3438559  1.7G 83 Linu
   ```

   The above output shows that the size of one sector is 512 bytes, and the
   first partition starts at sector 2048. Sectors are numbered from 0, so being
   sector 2048 means there are exactly 2048 sectors before it. Thus, the number
   of bytes from the image's start to the partition's beginning in that image
   is 512 * 2048 = 1,048,576 bytes, and that is the value of offset, which you
   will need later.

2. Create a directory to be used as the partition's mount point, like
   `/mnt/tmp` for example. `/mnt` is typically not writable by a normal user,
   so if you decide to use this path as the mount point, you need to run this
   command with *superuser privilege* (often by prepending `sudo` to it).

   ```console
   # mkdir /mnt/tmp
   ```

3. Mount the image, and specify the offset you calculated before. Note that the
   `mount` program usually needs to be run with superuser privilege.

   ```console
   # mount -o loop,offset=1048576 openSUSE-Leap-15.2-ARM-JeOS-raspberrypi4.aarch64-2020.07.08-Build1.35.raw /mnt/tmp/
   ```

The files in the boot partition are now available at the mount point, so you
are ready to copy them to elsewhere and have achieved the goal of mounting.

```console
$ cd /mnt/tmp
$ ls
bcm2708-rpi-b.dtb       bcm2710-rpi-3-b-plus.dtb  LICENCE.broadcom
bcm2708-rpi-b-plus.dtb  bcm2710-rpi-cm3.dtb       overlays
bcm2708-rpi-cm.dtb      bcm2711-rpi-4-b.dtb       start4.elf
bcm2708-rpi-zero.dtb    bootcode.bin              start.elf
bcm2708-rpi-zero-w.dtb  config.txt                startup.nsh
bcm2709-rpi-2-b.dtb     EFI                       u-boot.bin
bcm2710-rpi-2-b.dtb     fixup4.dat                ubootconfig.txt
bcm2710-rpi-3-b.dtb     fixup.dat
```

## Copy the Files to Fedora SD Card

This step is very straightforward; just copy every file and directory in
openSUSE's boot partition to your Fedora SD card's boot partition. If you want
to use a command for this task, run the following one under the SD card's boot
partition:

```console
$ cp -rv /mnt/tmp/* .
```

The `-r` flag let `cp` descend into child directories and copy their contents
as well, and the `-v` flag is again an optional one merely for progress
reporting.

As of Fedora 32 and Linux kernel 5.8, there is one file in openSUSE's boot
partition that should not be used on Fedora, which is the *U-Boot image*
`u-boot.bin`. When openSUSE's U-Boot image is being used, Fedora fails to boot.
You can keep using Fedora's image `rpi4-u-boot.bin` instead, by first deleting
openSUSE's `u-boot.bin` and then renaming `rpi4-u-boot.bin` to `u-boot.bin`.

The file deletion and renaming operations can be done together with a single
command, if you are willing to use it:

```console
$ mv {rpi4-,}u-boot.bin
```

### Extra Step for Fedora 33

When the U-Boot image shipped with Fedora 33 is used together with openSUSE's
boot files, the boot process will get stuck until you connect the Raspberry Pi
to a monitor. This can be easily fixed by creating a file called
`extraconfig.txt` under the SD card's boot partition and inserting the
following line into the file:

```
hdmi_force_hotplug=1
```

This may be done by running the following command under the SD card's boot
partition:

```console
$ echo 'hdmi_force_hotplug=1' > extraconfig.txt
```

## Modify Boot Configuration File

The bootloader you have ported from openSUSE to Fedora will attempt to read
files from an invalid location and fail to boot unless it is reconfigured for
Fedora. You need to tell the bootloader the correct path to Fedora's boot
files.

Replace everything in file `EFI/BOOT/grub.cfg` under your SD card's boot
partition with the following lines:

```
set prefix=($root)/EFI/fedora
normal
```

Save the file and safely eject the SD card. Insert it into your Raspberry Pi,
power it on, and the USB ports should be working after the system boots. Enjoy
using your USB peripherals on Raspberry Pi running Fedora!

## Clean Up

If everything works well, you can start cleaning up the trace you have left on
your computer. Should you have used `mount` to mount the openSUSE's image,
unmount it and remove the mount point with the following commands.

```console
# umount /mnt/tmp
# rmdir /mnt/tmp
```

## Known Issues

- When Fedora 32 runs on the 8GB model, regardless of whether this solution has
  been applied, the amount of RAM available to the operating system is limited
  to 4 GiB. This is caused by Fedora 32's outdated U-Boot image. Fedora 33
  fixes this particular problem by shipping a newer U-Boot image.

## References

This post is basically just a detailed explanation of the issue's solution
described in [this page](http://rglinuxtech.com/?p=2768) written by Robert
Gadsdon on rglinuxtech.com. Any credit for the abstract idea behind this
solution should go to that author; what I have done here is merely writing
step-by-step instructions on how to apply it.
