---
title: "Slipstream Windows NT 4.0 SP6a into Installation Media"
tags:
  - Windows
categories:
  - Tutorial
toc: true
---

Microsoft has once released official Windows installation media with a service
pack integrated, such as [Windows Vista with SP1][vista-with-sp1-box] and
[Windows XP with SP2][xp-with-sp2-box].  The process of integrating a service
pack into the installation media is called **slipstreaming**.  By using such a
slipstreamed media, users need not install the slipstreamed service pack
separately after they have installed Windows.

[vista-with-sp1-box]: https://www.betaarchive.com/forum/viewtopic.php?t=38003
[xp-with-sp2-box]: https://archive.org/details/WindowsXPProfessionalSP2German

For Windows NT 4.0 Workstation, the latest slipstreamed official installation
media that can be found online only have SP1, whereas the latest service pack
for Windows NT 4.0 is SP6a.  This is unlike Windows 2000, XP, Vista, or 7, all
of which have official installation ISOs with the latest available service pack
slipstreamed.

An unofficial Windows NT 4.0 Workstation installation ISO with SP6a
slipstreamed created by an enthusiast does
[exist][archive.org-nt4-sp6a-integrated].  However, some users might not prefer
it:

- Users who look for installing Windows NT 4.0 Server obviously cannot use the
  Workstation edition's ISO.

- Setup will report a "The file oleaccrc.dll was not copied correctly" message
  (as shown below).  It seems that the message can be safely dismissed by
  pressing Esc, and the issue reported does not seem to affect the installed
  system.  However, some users might prefer to have zero warning messages
  during Setup.

  ![The oleaccrc.dll Setup message]({{< static-path img oleaccrc.dll.png >}})

- Some users might be relunctant to trust a modified Windows installation ISO
  made by an individual user online whom they do not know.

[archive.org-nt4-sp6a-integrated]: https://archive.org/details/win-nt-4-en-sp-6.-nt-4-alive

In response, this tutorial provides readers with instructions to build their
own Windows NT 4.0 installation ISO with SP6a slipstreamed, and the
slipstreamed ISO built with this method will not emit the `oleaccrc.dll`
message during Setup.

## Compatibility

Users will need to run some tools to slipstream a service pack into an
installation ISO.  The tools' system requirements are:

- To avoid the `oleaccrc.dll` Setup message, the latest Windows version on
  which the tools can run is **Windows XP**.  Windows Vista and later versions
  are not compatible with the tool that fixes the `oleaccrc.dll` message.

  - The author has only verified this tool's functionality on a 32-bit edition
    of Windows XP, not 64-bit.

- Users who do not care about the `oleaccrc.dll` message can use Windows Vista
  or later versions, as well as Windows XP.  The author has verified the other
  tools' functionality on a 32-bit edition of Windows XP, a 32-bit edition of
  Windows Vista, and both a 32-bit edition and a 64-bit edition of Windows 10.

The slipstreaming tools support **English** versions of Windows NT 4.0.  The
tools do not support all languages: for example, the author has confirmed that
they do not work for Simplified Chinese versions.  Although the tools can
generate an Simplified Chinese installation ISO, the system installed from the
ISO does not actually have SP6a integrated.  The tools might support more
languages, but the author has not tested the tools on other languages.

The tools support both Workstation and Server editions of Windows NT 4.0 as per
their documentation, and they support slipstreaming SP6 or SP6a.  The author
has verified that the tool can slipstream SP6a into the official Windows NT 4.0
Workstation with SP1 English installation media.

## Known Limitations

### Setup Will Lack Large Disk Support

Even after slipstreaming SP6a, Windows NT 4.0 Workstation Setup still might not
recognize disk space beyond 8 GB.  For a new disk larger than 8 GB, Setup might
only show 8 GB of unpartitioned space, despite the fact that SP4 added support
for disks larger than 8 GB.

![Setup showing only 8033 MB unpartitioned space for an empty 16379 MB
drive]({{< static-path img large-disk.png >}})

According to [Microsoft Knowledge Base article 197667][kb197667], the correct
solution to this issue is to let Setup separately load the updated IDE driver
from SP4.  After all, the slipstreaming process only applies the service pack
to the installed system, not the minimal version of Windows that runs the
text-mode portion of Setup.  Attentive users may notice that, while the
text-mode portion is starting, the build version string shown on the boot
splash screen does not contain a service pack version.

[kb197667]: https://archive.org/details/kb197667

### AUTOCHK Before Conversion to NTFS

After the text-mode portion of Setup finishes and reboots the computer, and
during the first reboot, if the user chose to format the Windows NT 4.0
partition using NTFS, the boot splash screen may show this message before
converting the file system to NTFS:

```
WARNING!  Your drive may be corrupt.  Please let AUTOCHK run.
Skipping AUTOCHK on a volume may lead to an unmountable volume.
Skipping AUTOCHK on a system drive may lead to an unusable system.
Press any key in <X> seconds to abort AUTOCHK.
```

![The "Your drive may be corrupt" warning on the boot splash screen]({{<
static-path img autochk.png >}})

(Tip: Regardless of which file system the user chooses, Windows NT 4.0 Setup
will always format the partition with FAT first; if the user chooses NTFS,
Setup will convert the file system to NTFS upon the first reboot.)

The user can let AUTOCHK run and fix any file system issues by not doing
anything when this message is displayed.  Regardless of whether AUTOCHK is
skipped, this warning does not seem to affect the installed system.

## Instructions

1.  Click [here][nt4alive-download] to download the [*NT 4 Alive slipstream
    script*][nt4alive], the main tool for slipstreaming.

2.  Extract the downloaded Zip file into a folder, and open this folder.

    ![Contents of the extracted folder]({{< static-path img 02.png >}})

3.  Run the script `NT4Alive_080310b.cmd`.  In the script's window, press
    Enter.

    ![The script's window]({{< static-path img 03-1.png >}})

    Upon the first run, the script will immediately exit after creating some
    new folders under the folder it is in, including `PACKAGES`, `SOURCE`, and
    `TOOLS`.  In the subsequent steps, readers will copy different types of
    files into these folders.

    ![New folders created by the script]({{< static-path img 03-2.png >}})

4.  For readers who would like to avoid the `oleaccrc.dll` Setup message, click
    [here][modifype-download] to download a Zip file that contains
    `modifype.exe`, a tool that NT 4 Alive needs to fix `oleaccrc.dll`, as
    indicated by NT 4 Alive's `_readme.txt` file.  This tool is not easy to
    find online; the best source that the author identified was [this
    page][modifype].

    Readers who do not care about the `oleaccrc.dll` Setup message can skip
    downloading this file.

5.  For those who downloaded the Zip file, extract `modifype.exe` in it
    to the `TOOLS` folder that the NT 4 Alive script created.

6.  Click [here][cdimage-download] to download a Zip file that contains
    `CDIMAGE.EXE`, a tool that NT 4 Alive can use to create bootable
    slipstreamed ISOs.  This tool is also not easy to find online; the best
    source that the author identified was [this][cdimage] Internet Archive
    item.

7.  Extract `CDIMAGE.EXE` in the downloaded Zip file to the `TOOLS` folder that
    the NT 4 Alive script created.

8.  Copy the `SETTINGS.INI` configuration settings file of NT 4 Alive, which is
    under the same folder where `NT4Alive_080310b.cmd` is, to the `TOOLS`
    folder.

9.  Edit the new `SETTINGS.INI` in the `TOOLS` folder, and make these changes
    to it:
    - Append `YES` after `CREATE_ISO=`
    - Append `CDIMAGE` after `ISO_TOOL=`

    The resulting content of `SETTINGS.INI` will be:
    ```ini {hl_lines=["5-6"]}
    ; SKIPINTRO, FULLAUTO or nothing
    RUNMODE=

    ; ISO
    CREATE_ISO=YES
    ISO_TOOL=CDIMAGE
    ISO_FILE_NAME=NT40_SP6.iso
    ISO_VOLUME_LABEL=NT40_SP6
    CDIMAGE_SWITCHES=-h -j1 -m -o
    MKISOFS_SWITCHES=-relaxed-filenames -d -D -N -J -no-emul-boot -no-iso-translate -boot-load-size 4
    ```

    ![The resulting content of `SETTINGS.INI`]({{< static-path img 09.png >}})

10. Download and install [7-Zip] if it is not installed.  It will be used to
    extract files as well as boot information from an ISO.

11. Use 7-Zip to open an original Windows NT 4.0 installation ISO, enter the
    `[BOOT]` folder, and extract the file `Boot-NoEmul.img` to the `TOOLS`
    folder that the NT 4 Alive script created.  This file contains the ISO's
    boot information, which `CDIMAGE.EXE` will need to create a bootable
    slipstreamed ISO.

    ![The `[BOOT]` folder shown in 7-Zip]({{< static-path img 11-1.png >}})

    ![The `Boot-NoEmul.img` file shown in 7-Zip]({{< static-path img 11-2.png
    >}})

12. Rename `Boot-NoEmul.img` to `boot.bin`, which is the file name that NT 4
    Alive expects.  Ensure the file's extension is changed to `.bin`.  If
    necessary, let Windows Explorer show extensions for known file types.

    ![The "Properties" box of file `boot.bin`, showing the type of file as "BIN
    File"]({{< static-path img 12.png >}})

13. The `TOOLS` folder created by the NT 4 Alive script should now contain
    the following files.  Before proceeding to the next step, confirm that all
    these files exist.
    - `boot.bin`
    - `CDIMAGE.EXE`
    - `modifype.exe` (optional; only needed when the `oleaccrc.dll` Setup
      message should be avoided)
    - `SETTINGS.INI`

    ![Correct contents of the `TOOLS` folder]({{< static-path img 13.png >}})

14. Use 7-Zip to open the original Windows NT 4.0 installation ISO, then
    extract all files and folders except the `[BOOT]` folder to the `SOURCE`
    folder that the NT 4 Alive script created.

    ![Everything except The `[BOOT]` folder shown in 7-Zip]({{< static-path img
    14.png >}})

15. Put the EXE file for Windows NT 4.0 SP6 or SP6a into the `PACKAGES` folder
    that the NT 4 Alive script created, and rename the file to `sp6i386.exe`.
    Either SP6 or SP6a can be used.  In the case of SP6a, also use the
    `sp6i386.exe` file name.

16. Run `NT4Alive_080310b.cmd` again, and press Enter in the script's window.
    If all the required files have been copied to their correct folders, the
    script will now start to slipstream the service pack and create the
    slipstreamed ISO.

    ![NT 4 Alive slipstreaming service pack]({{< static-path img 16.png >}})

17. If `CDIMAGE.EXE`, `SETTINGS.INI`, and `boot.bin` have been prepared
    properly, then when the script finishes, the slipstreamed ISO can be found
    as `NT40_SP6.iso` under the same folder where `NT4Alive_080310b.cmd` is.
    The script will print a message saying "NT40\_SP6.iso was created too."

    ![NT 4 Alive reports successful ISO creation]({{< static-path img 17-1.png
    >}})

    ![The ISO file created by NT 4 Alive]({{< static-path img 17-2.png >}})

[nt4alive-download]: https://archive.org/download/nt-4-alive/NT4Alive.zip
[nt4alive]: https://archive.org/details/nt-4-alive
[modifype-download]: https://media.askvg.com/files/modifype.zip
[modifype]: https://www.askvg.com/how-to-include-your-edited-system-files-in-windows-setup/
[cdimage-download]: https://archive.org/download/cdImageGUI_all/cdImageGUI_all.zip/CDIMAGE_247.zip
[cdimage]: https://archive.org/details/cdImageGUI_all
[7-Zip]: https://7-zip.org/
