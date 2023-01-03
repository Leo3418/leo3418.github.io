---
title: "Run Windows 98 in Vanilla DOSBox"
tags:
  - Windows
categories:
  - Tutorial
toc: true
---

As a DOS emulator, DOSBox is theoretically capable of running DOS-based
versions of Windows, like Windows 3.1, 95, and 98.  Certainly, the
[compatibility list][dosbox-comp-list] on DOSBox official website classifies
Windows 3.1 and 95 as *supported*; but for Windows 98, it is just rated
[*runnable*][dosbox-comp-list-windows-98] -- even lower than the intermediate
*playable* tier.  Perhaps for this reason, most people would just resort to
other DOSBox forks that offer better support for Windows 98, like
[DOSBox-X][dosbox-x-windows-98], when they want to run this version of Windows.

But, I did not give up getting Windows 98 to run in vanilla DOSBox and
discovered that only a little special care would be required to bring it to at
least the *playable* territory, if the ability to run games like Solitaire and
3D Pinball would justify a "playable" rating.  So, I decided to write this
tutorial for people who wish to try it out.

![Solitaire on Windows 98 in vanilla DOSBox]({{< static-path type=img l10n=y
file=solitaire.png >}})

![3D Pinball on Windows 98 in vanilla DOSBox]({{< static-path type=img l10n=y
file=pinball.png >}})

[dosbox-comp-list]: https://www.dosbox.com/comp_list.php?letter=W
[dosbox-comp-list-windows-98]: https://www.dosbox.com/comp_list.php?showID=3485&letter=W
[dosbox-x-windows-98]: https://dosbox-x.com/wiki/Guide%3AInstalling-Windows-98

## Prerequisites

To follow this tutorial's instructions, these things are required:

- DOSBox version 0.74-3 on Windows
  - The instructions to install Windows 98 in this tutorial have only been
    verified to work on DOSBox for Windows.  If Windows 98 is installed in
    DOSBox on another platform, like GNU/Linux and macOS on Apple silicon, then
    Windows 98 might not be able to boot into the desktop after installation
    completes.  It is still possible to *run* Windows 98 in DOSBox on GNU/Linux
    though, as long as the installation is performed in DOSBox on Windows.  For
    more information, please consult the [*On Non-Windows
    Platforms*][on-non-windows-platforms] section below.
- An ISO image of the Windows 98 CD from a full version (rather than an upgrade
  version)
  - An ISO for an upgrade version *might* work but is out of this tutorial's
    scope
  - Both the original release ("first edition") and the Second Edition can be
    used
  - Both retail versions and OEM versions can be used
- A disk image of an MS-DOS or Windows 9x boot disk
  - This tutorial uses the Windows 98 Second Edition Startup Disk as an
    example; an image for it is available [on
    WinWorld][winworldpc-boot-disk-98-se]

[winworldpc-boot-disk-98-se]: https://winworldpc.com/product/microsoft-windows-boot-disk/98-se
[on-non-windows-platforms]: {{< relref "#on-non-windows-platforms" >}}

## Modify DOSBox Configuration for Windows 98

The following configuration options should be present in the [DOSBox
configuration file][dosbox-wiki-dosbox.conf]:

```ini
[cpu]
core=dynamic
cputype=pentium_slow
cycles=max

[dosbox]
machine=svga_s3
```

- The `core=dynamic` and `cputype=pentium_slow` options play the most important
  role in allowing Windows 98 to run without major issues in vanilla DOSBox.
  If they are not set like this, then Windows 98 might not boot into the
  desktop after it is installed in DOSBox.
  - Note that as long as DOSBox's dynamic core is available, setting `core` to
    `auto` (which is the default) is also fine.

- Setting `cycles` to `max` is not required, but it greatly improves the
  performance of Windows 98 in DOSBox, particularly during the operating
  system's boot process.  `max` lets DOSBox's emulated CPU run at the maximum
  speed at all times.  The default `auto` setting starts emulation at a
  significantly lower speed of 3000 cycles/ms before it automatically switches
  to the maximum speed after Windows 98 boots, which is why Windows 98 takes
  longer time to start under this setting.

- `machine=svga_s3` (which is also the default) provides great graphics
  experience and performance with Windows 9x.  Windows will be able to
  automatically install the graphics driver for it, which supports 32-bit true
  color at 800 × 600 screen resolution.  Other options might work but are out
  of this tutorial's scope.

[dosbox-wiki-dosbox.conf]: https://www.dosbox.com/wiki/Dosbox.conf

## Prepare a Hard Disk Image

A bootable hard disk image is mandatory for running Windows 98 in DOSBox.
Windows 98 needs to be booted via its own MS-DOS 7.1-based bootloader, which
must be installed to a hard disk's MBR.  The only way to provide an MBR's
functionality in DOSBox is to use a bootable hard disk image.

This tutorial assumes that only one primary partition will be created on the
hard disk image.  Creating and using additional partitions might be possible
but is out of this tutorial's scope.

### File System: FAT16 vs. FAT32

Unless auxiliary tools are used, the hard disk image's primary partition must
be *initially* formatted with FAT16.  It can be converted to FAT32 after
Windows 98 is installed though.

Before installing Windows 98, the Setup files under the `Win98` folder on the
Windows 98 CD must be copied to the hard disk image.  This is because there is
no known way to start Windows 98 Setup with CD-ROM support in vanilla DOSBox,
so the Setup files cannot be read from the ISO during the Setup process proper
and thus must be transferred to the hard disk image in advance.

DOSBox can be used to copy the files from the ISO to the hard disk image
**only** if the file system on the image is FAT16.  As of version 0.74-3,
DOSBox has issues with writing files to a FAT32 file system.

If another tool will be used to copy the files to the hard disk image, and that
tool supports FAT32, then FAT32 can be used as the initial file system.  Use of
these tools is out of this tutorial's scope.

### Size of the Image

The hard disk image's size is recommended to be at least 0.5 GiB so it has
enough space for both the Windows 98 installation and the Setup files.

The image's size must also be within 2 GiB.  As of version 0.74-3, DOSBox has
issues with booting from hard disk images whose size exceeds 2 GiB.  Such
images will appear to mount successfully, but the mounted virtual hard disk
will be gone once an operating system boots in DOSBox.

### Obtaining an Image

Vanilla DOSBox does not provide the functionality to create a hard disk image,
meaning that users must either download an image created by others or use
another tool to create a custom image.

A pre-created hard disk image with a 2 GiB FAT16 partition was kindly
[provided][pre-created-hdd-imgs] by user *DosFreak* on vogons.org,
which can be downloaded with [this link][pre-created-2gib-fat16-img].  This
image has the following [geometry][wikipedia-chs]:
- Cylinders: 1023
- Heads: 64
- Sectors: 63

Users who want to create their own image can use tools like
[DOSBox-X][dosbox-x-create-hdd-img] to do it.  For instance, the following
command lets DOSBox-X create a 2 GiB FAT16 image at path `D:\hdd.img` on the
host system:

```
imgmake D:\hdd.img -t hd_2gig -fat 16
```

When using such a tool, be sure to note down the cylinder-head-sector (CHS)
geometry reported by the tool for the new image, as shown in the example below.
This information will be needed later.

![DOSBox-X reporting CHS geometry for new image]({{< static-path img
dosbox-x-imgmake.png >}})

[pre-created-hdd-imgs]: https://www.vogons.org/viewtopic.php?t=17324#post-123503-attachments-title
[pre-created-2gib-fat16-img]: https://www.vogons.org/download/file.php?id=9430
[dosbox-x-create-hdd-img]: https://dosbox-x.com/wiki/Guide%3AManaging-image-files-in-DOSBox%E2%80%90X#_creating_harddisk_images
[wikipedia-chs]: https://en.wikipedia.org/wiki/Cylinder-head-sector

## Copy Windows 98 Setup Files

[As discussed previously][fs-fat16-vs-fat32], Windows 98 Setup files must be
copied to the hard disk image.  The following instructions only rely on vanilla
DOSBox for this task to avoid unnecessarily requiring use of additional tools
and thus assume that the file system on the image is FAT16.  If another tool is
chosen to copy those files, then please ignore these instructions and take
whatever steps needed to copy the files using that tool instead.

Launch DOSBox, and run the following commands in the DOS prompt:

1. Mount the hard disk image and the ISO image of the Windows 98 CD.  Replace
   `D:\hdd.img` and `D:\win98.iso` with the actual paths to those image files
   respectively.

   ```
   imgmount C D:\hdd.img
   imgmount D D:\win98.iso -t iso
   ```

2. Create a directory for Windows 98 Setup files on the hard disk image, and
   enter the directory.  In the following example, the directory is named
   `Win98`.

   ```
   C:
   mkdir Win98
   cd Win98
   ```

3. Start copying the Setup files from the `Win98` folder on the ISO.  Note that
   DOSBox will freeze for a moment when the files are being copied, which is OK
   -- just wait for the operation to complete.

   ```
   copy D:\Win98
   ```

4. Unmount both images.

   ```
   imgmount -u C
   imgmount -u D
   ```

[fs-fat16-vs-fat32]: {{< relref "#file-system-fat16-vs-fat32" >}}

## Install Windows 98

When the hard disk image and Windows 98 Setup files are ready, the installation
process can start.

1. Mount the hard disk image in DOSBox as a bootable disk.  The mount command's
   syntax is:

   ```
   {{% imgmount-2.inline %}}imgmount 2 <image-path> -fs none -size <sector-size>,<sectors>,<heads>,<cylinders>{{%/ imgmount-2.inline %}}
   ```

   The sector size is normally 512 bytes.  The sectors, heads, and cylinders
   parameters are determined by the image's CHS geometry.  For example, if the
   pre-created image was downloaded and used, then the following DOSBox command
   should be used to mount it:

   ```
   imgmount 2 2GB.img -fs none -size 512,63,64,1023
   ```

2. Boot from the MS-DOS or Windows 9x boot disk image.  Replace
   `D:\bootdisk.img` with the actual path to the boot disk image file.

   ```
   boot D:\bootdisk.img
   ```

   This step is necessary because Windows 98 Setup relies on the environment
   that the boot disk provides.  If Setup is started directly from DOSBox
   instead, the SU0013 error will occur.

   ![Error message from Setup when it is started directory from DOSBox]({{<
   static-path type=img l10n=y file=setup-on-emulated-dos.png >}})

3. If the boot disk presents an option to boot with CD-ROM support, do **not**
   select that option.  Choose any option that boots **without** CD-ROM support
   instead.

   ![Boot from Windows 98 Startup Disk without CD-ROM support]({{< static-path
   img bootdisk-without-cdrom.png >}})

   If an option with CD-ROM support is chosen, an error will occur, which will
   cause the system in DOSBox to halt.

   ![Error when booting with CD-ROM support]({{< static-path img
   bootdisk-with-cdrom-error.png >}})

4. Change to the directory in which Windows 98 Setup files reside.

   ```
   C:
   cd Win98
   ```

5. If the Second Edition of Windows 98 is being installed, and the Setup files
   were copied to the hard disk image using DOSBox, then it is recommended that
   ScanDisk is run manually before starting Setup to automatically fix file
   system problems caused by DOSBox during the file transfer:

   ```
   scandisk /autofix
   ```

   When ScanDisk prompts to create an Undo disk, choose "Skip Undo".  At this
   point, the hard disk image should only contain Windows 98 Setup files, so
   there should be no precious data to preserve, hence an Undo disk is
   unnecessary.

   ![Let ScanDisk skip Undo disk]({{< static-path img scandisk-skip-undo.png
   >}})

   When ScanDisk finishes, it shows a summary of problems it detected and
   fixed:

   ![ScanDisk reporting fixed errors]({{< static-path img scandisk-success.png
   >}})

   Although Windows 98 Setup can also run ScanDisk, in that scenario, ScanDisk
   will ask, for **every** problem it finds, whether the problem should be
   fixed, and there will not be a "Fix All" option.  Therefore, running
   ScanDisk manually with the `/autofix` option prevents the need to select
   "Fix It" 63 times.

   ![ScanDisk prompting for action for every problem it finds]({{< static-path
   img setup-scandisk-problem.png >}})

6. Start Windows 98 Setup, and complete the first stage of Setup.

   ```
   setup
   ```

   ![Windows 98 Setup is started in DOSBox]({{< static-path type=img l10n=y
   file=setup-welcome.png >}})

   In general, the installation process in this stage on DOSBox is the same as
   on a physical computer or virtual machine.  A few points are worth noting:

   1. If the file system on the hard disk image is FAT16, then in the "Windows
      Components" step of the Setup Wizard, it is recommended that the *Drive
      Converter (FAT32)* under *System Tools* is selected, so the file system
      can be converted to FAT32 using this component after Windows 98 is
      installed.

      1. When prompted, select "Show me the list of components so I can
         choose."

         ![Opt to choose Windows 98 components]({{< static-path type=img l10n=y
         file=setup-components-custom.png >}})

      2. Select "System Tools" on the left, then click the "Details" button on
         the right.

         ![Select "System Tools"]({{< static-path type=img l10n=y
         file=setup-components-sys-tools.png >}})

      3. Ensure the check box next to "Drive Converter (FAT32)" is selected,
         then click "OK".

         ![Select "Drive Converter (FAT32)"]({{< static-path type=img l10n=y
         file=setup-components-drv-converter.png >}})

   2. At the "Startup Disk" step, skip creating a startup disk.

      ![Skip creating a startup disk]({{< static-path type=img l10n=y
      file=setup-startup-disk-cancel.png >}})

      A startup disk cannot be created at this point in DOSBox anyway.
      Doing so would result in a "disk initialization error":

      ![A startup disk cannot be created]({{< static-path type=img l10n=y
      file=setup-startup-disk-error.png >}})

7. After the first stage of Setup completes, Setup will request a reboot, and
   DOSBox will exit.  Restart DOSBox, and mount the hard disk image as bootable
   again:

   ```
   {{% imgmount-2.inline /%}}
   ```

   Then, boot from the hard disk image to continue Setup:

   ```
   {{% boot-c.inline %}}boot -l C{{%/ boot-c.inline %}}
   ```

   ![Windows 98 is booting for the first time]({{< static-path type=img l10n=y
   file=setup-firstboot.png >}})

   The installation process in this stage is also straightforward, except that
   if the Second Edition is being installed, an "illegal operation" error will
   be reported for Rundll32 before this stage concludes.  This error can be
   ignored.

   !["Illegal operation" error for Rundll32 during Setup]({{< static-path
   type=img l10n=y file=setup-rundll32-error.png >}})

   When Setup reboots the computer again, DOSBox will seem to freeze at the
   "Windows is shutting down" screen.  This is normal: Windows 98 sent an
   [APM][wikipedia-apm] event to trigger a reboot, but vanilla DOSBox does not
   support APM, hence it cannot handle the event.  Wait for about 5 seconds,
   and manually close DOSBox to complete the reboot.

   [wikipedia-apm]: https://en.wikipedia.org/wiki/Advanced_Power_Management

   ![DOSBox stuck at Windows 98's shut-down screen]({{< static-path type=img
   l10n=y file=setup-stuck-at-shutdown.png >}})

8. Restart DOSBox, mount the hard disk image, and boot from it again:

   ```
   {{% imgmount-2.inline /%}}
   {{% boot-c.inline /%}}
   ```

   On the Second Edition, the "illegal operation" error for Rundll32 will be
   reported again three times before Windows 98 loads the desktop, all of which
   can be ignored as well.

   !["Illegal operation" error for Rundll32 after Setup]({{< static-path
   type=img l10n=y file=oobe-rundll32-error.png >}})

   The installation is complete when the "Welcome to Windows 98" window
   appears.

   ![The "Welcome to Windows 98" window]({{< static-path type=img l10n=y
   file=oobe-welcome.png >}})

## Boot Windows 98

After Windows 98 is installed, the DOSBox commands to boot the operating system
are the same as the ones used during the installation process:

```
{{% imgmount-2.inline /%}}
{{% boot-c.inline /%}}
```

To avoid having to type these commands every time, they can be added to the
`[autoexec]` section of the DOSBox configuration file.  The following example
not only lets the commands be executed automatically when DOSBox starts but
also extracts the `imgmount` arguments into variables for better explanation
and easier modification in the future.

```ini
[autoexec]

set BOOT_IMAGE=D:\hdd.img
set SECTOR_SIZE=512
set SECTORS=63
set HEADS=64
set CYLINDERS=1023

imgmount 2 "%BOOT_IMAGE%" -fs none -size %SECTOR_SIZE%,%SECTORS%,%HEADS%,%CYLINDERS%
{{% boot-c.inline /%}}
```

## Optional: Convert File System to FAT32

After Windows 98 is installed, the file system on the hard disk image can be
converted to FAT32 without affecting the ability to boot Windows 98 from it in
vanilla DOSBox.  As the `-fs none` argument to `imgmount` suggests, DOSBox will
only create a virtual hard disk per se from the image without trying to read
and mount the file system on the image, so the file system on the image no
longer needs to be one supported by vanilla DOSBox.

Keeping the file system as FAT16 does not have any functional drawbacks, so the
conversion is optional.  However, converting the file system to FAT32 usually
makes additional disk space available.  On a file system with a new Windows 98
Second Edition installation and its Setup files, the file system conversion can
yield around 60 MB of free space.

![Disk usage before FAT32 conversion]({{< static-path type=img l10n=y
file=du-fat16.png >}})

![Disk usage after FAT32 conversion]({{< static-path type=img l10n=y
file=du-fat32.png >}})

To convert the file system, from the Start menu, open *Programs* >
*Accessories* > *System Tools* > *Drive Converter (FAT32)*, then follow the
Drive Converter wizard's prompts.

![Launching the Drive Converter]({{< static-path type=img l10n=y
file=drv-converter-launch.png >}})

## On Non-Windows Platforms

In general, more issues are expected with Windows 98 in vanilla DOSBox when the
host platform where DOSBox runs is not Windows.  Users who are on these
platforms are recommended to either install Windows 95 in vanilla DOSBox
instead or switch to a DOSBox fork that offers better support for Windows 98.
For those who still want to give Windows 98 in vanilla DOSBox a try, please pay
attention to information in this section.

### Extra DOSBox Configuration Required

On non-Windows platforms, like GNU/Linux and macOS, the following additional
settings are needed in the DOSBox configuration file **in addition to** the
ones [listed above][dosbox-config-for-windows-98]:

```ini
[serial]
serial1=disabled
serial2=disabled
```

By default, `serial1` and `serial2` are both set to `dummy`, which will cause a
black screen of death when Windows 98 boots in vanilla DOSBox on these
platforms.

[dosbox-config-for-windows-98]: {{< relref "#modify-dosbox-configuration-for-windows-98" >}}

### First Install on Windows, then Run Elsewhere

Users who want to run vanilla Windows 98 in DOSBox on a non-Windows platform,
including but not limited to GNU/Linux, should install Windows 98 and
**complete the first boot into the Windows 98 desktop in DOSBox on Windows**.
Then, the hard disk image may be copied to the non-Windows environment to run
Windows 98 in DOSBox there.

If Windows 98 is installed in vanilla DOSBox on the non-Windows platform, then
the system might freeze upon the first boot into Windows 98 desktop after the
Setup process proper.  After this first boot is complete, Windows 98 *might* no
longer freeze.  Based on my testing, this first boot can only complete in
vanilla DOSBox on Windows.

### Platform-specific Notes

#### Fedora

Fedora has replaced its official DOSBox package with [DOSBox
Staging][dosbox-staging], but I was able to install and run the [last official
build][fedora-vanilla-dosbox-last] of the vanilla DOSBox package, which was for
Fedora 34, on Fedora 37.  As long as the first boot into the Windows 98 desktop
is complete, the hard disk image can be used with this last official build of
vanilla DOSBox without obvious issues on Fedora 37.

[dosbox-staging]: https://dosbox-staging.github.io/
[fedora-vanilla-dosbox-last]: https://koji.fedoraproject.org/koji/buildinfo?buildID=1676070

#### Gentoo

Even after the first boot into the Windows 98 desktop is complete, with
[`games-emulation/dosbox-0.74.3`][gentoo-dosbox-stable], Windows 98 often
freezes after it has been up for a few minutes, so it is basically unusable.

For this reason, Gentoo users who want to run Windows 98 in a DOS emulator are
recommended to use a DOSBox fork instead.  Personally, I have been using
DOSBox-X on Gentoo to run Windows 98 for a while, and stability has been
impressive.  There is not an official DOSBox-X package for Gentoo yet, which is
why I have created and been maintaining ebuilds for DOSBox-X myself.  These
ebuilds are now available as `games-emulation/dosbox-x` [in
GURU][guru-dosbox-x]; interested Gentoo users are welcome to try them out.

[gentoo-dosbox-stable]: https://gitweb.gentoo.org/repo/gentoo.git/tree/games-emulation/dosbox/dosbox-0.74.3.ebuild
[guru-dosbox-x]: https://gitweb.gentoo.org/repo/proj/guru.git/tree/games-emulation/dosbox-x

#### macOS on Apple silicon

As of macOS 13.1 and DOSBox 0.74-3-3, regardless of whether the first boot into
the Windows 98 desktop is complete, Windows 98 often gives "illegal operation"
errors for various processes including Explorer and sometimes even crashes with
blue screen of death, rendering it completely unusable.

## Known Issues

Besides the known issues of Windows 98 in vanilla DOSBox on non-Windows
platforms mentioned above, this section documents additional known issues that
may happen even in DOSBox on Windows.

### DOSBox Does Not Exit after Windows 98 Is Shut Down

DOSBox stays on a screen saying "it's now safe to turn off your computer" after
Windows 98 is shut down from the Start menu:

![Message displayed after Windows 98 is shut down in DOSBox]({{< static-path
type=img l10n=y file=shutdown-complete.png >}})

This is also because Windows 98 sent an APM event to power off the machine,
which vanilla DOSBox does not support, and this fallback message is shown
instead.

The DOSBox window needs to be closed manually.  It is safe to do so as long as
this screen is displayed.

### Broken Sound in Microsoft Return of Arcade Games

The sound in Microsoft Return of Arcade games might not play properly on
Windows 98 in vanilla DOSBox.  The following resolutions are recommended:
- Turn off the sound in those games.
- Install and play these games on Windows 95 in vanilla DOSBox, where the
  games' sound can play normally.
- Install and play these games on Windows 98 in DOSBox-X, where the games'
  sound can play normally.

## References

- [Windows 9x DOSBox Guide][refs-windows-9x-dosbox-guide] by *DosFreak* on
  vogons.org

[refs-windows-9x-dosbox-guide]: https://www.vogons.org/viewtopic.php?t=17324
