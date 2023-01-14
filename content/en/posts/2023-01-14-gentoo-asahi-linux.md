---
title: "Installing Gentoo via Asahi Linux on an Apple Silicon-based Mac"
tags:
  - Gentoo
  - GNU/Linux
categories:
  - Blog
toc: true
header:
  actions:
    - label: "View Screenshot"
      url: /img/posts/2023-01-14-gentoo-asahi-linux/mate-de.png
  overlay_image: /img/posts/2023-01-14-gentoo-asahi-linux/mate-de.png
  og_image: /img/posts/2023-01-14-gentoo-asahi-linux/mate-de.png
  caption: "Gentoo running on Mac mini 2020, with MATE Desktop Environment"
  overlay_filter: 0.5
  show_overlay_excerpt: false
---

When Apple launched Macs with Apple silicon, people speculated that a
revolution in desktop computing had started.  I saw on Reddit a GNU/Linux user
claimed that GNU/Linux distributions should start to worry about the potential
transition from x86-64 to ARM64 and do something about it to survive.  What
they might have not realized was that common software packages that constitute
GNU/Linux had been long prepared for ARM64 thanks to portability of high-level
programming languages.  The power houses built by Apple would not necessarily
threaten GNU/Linux but instead set up a wider stage for it.  Thanks to the
[Asahi Linux][asahi-linux] project's efforts, it is now possible to exploit an
Apple silicon-based Mac's performance by running GNU/Linux on it.  After seeing
it for myself, I think the project is very promising in making Apple
silicon-based Macs a worthy choice for GNU/Linux users.

Recently, I bought my dad a Mac mini 2020 with the Apple M1 chip, which would
allow him to replace his aging 2014 model.  (I knew Apple was rumored to
refresh the product line in 2023, but my dad was fine with the 2020 model.
Also, I purchased an Apple certified refurbished one, which saved around
US$120.)  I had a chance to play around with it before handing it over to him
when I meet him next time, so I decided to do something fun: install and run
Gentoo on it.  This would be an ultimate test for M1's CPU performance because
it would involve compiling a lot of software packages from source.  Personally,
code compilation has also been my major performance-demanding workflow since I
have been daily-driving Gentoo and maintaining some Gentoo packages, so I was
interested to see how well M1 could handle it compared to my other x86-64
machines.

[asahi-linux]: https://asahilinux.org/

## An Attempt to Boot from Gentoo Minimal Installation CD Image

Nowadays, on PCs, when someone wants to install a new operating system, they
would usually create a bootable USB drive from the OS's installation ISO, boot
from the USB drive to start the installation environment, and complete the
installation steps in there.  Gentoo's installation procedure also follows this
pattern.

To enable a similar experience on Apple silicon-based Macs, the Asahi Linux
installer offers a "[UEFI environment only][asahi-alpha-uefi-env]" option.  I
first tried to use this option and boot from the Gentoo minimal installation CD
image for ARM64, but the attempt was obviously unsuccessful.  As of writing,
the kernel used in those CD images was still 5.15 (the then-latest stabilized
version on Gentoo), but support submitted by Asahi Linux for a lot of important
devices had not landed in the upstream kernel [until around
5.19][asahi-feature-support]:
- Mac mini's USB-A ports have been supported only since 5.16, and the
  USB-C/Thunderbolt port support had not been upstreamed yet as of writing,
  meaning that even if I could successfully boot the image, I still would not
  be able to use a keyboard, let alone install Gentoo.
- The internal NVMe storage device had not been supported until 5.19, so even
  if I could use a keyboard, I would not be able to access the internal disk
  from the installation environment.

I briefly thought about replacing the kernel on the CD image myself, but it
seemed time-consuming, and I did not want to be stuck on a blocker for too long
when the adventure had just started.  So, I fell back to [the method given on
an Asahi Linux wiki page][asahi-docs-gentoo], whose existence I had been
already aware of; I did not try it first because I wanted to use a "normal"
method as long as it had seemed feasible.

[asahi-alpha-uefi-env]: https://asahilinux.org/2022/03/asahi-linux-alpha-release/#uefi-environment-only-m1n1--u-boot--esp
[asahi-feature-support]: https://github.com/AsahiLinux/docs/wiki/Feature-Support
[asahi-docs-gentoo]: https://github.com/AsahiLinux/docs/wiki/Installing-Gentoo-with-LiveCD

## Connecting to Wi-Fi on Asahi Linux Minimal

I had to rely on Wi-Fi for Internet connectivity during the installation
process since I could not move the Mac mini and all peripherals to the room
where my router was to use Ethernet.  At first, when I followed the wiki page's
instructions to get Asahi Linux Minimal running for the first step, I did not
figure out how I could connect to my Wi-Fi network.  The instructions claimed
that NetworkManager was available, but the `nmcli` command did not exist.
`wpa_supplicant` was also absent.  Maybe "Minimal" really meant minimal as in
"no Wi-Fi support, Ethernet only", I thought.

It was only after I had reinstalled the fuller Asahi Linux Desktop instead --
so I could connect to my Wi-Fi from the desktop environment -- did I discover
that the Minimal version actually shipped with a Wi-Fi support package called
iwd, which I had not been aware of at all.  Well, iwd *was* mentioned on the
wiki page, but I had no clue as to what it could do and fully focused on
NetworkManager instead.

These steps are what I did to connect to Wi-Fi on Asahi Linux Minimal:

1. If DHCP is needed, it must be enabled for the Wi-Fi interface:
   1. Create directory `/etc/iwd`:
      ```console
      # mkdir /etc/iwd
      ```
   2. Create file `/etc/iwd/main.conf`, and add the following content to it:
      ```ini
      [General]
      EnableNetworkConfiguration=true
      ```

2. Start the iwd service:

   ```console
   # systemctl start iwd.service
   ```

3. Use the `iwctl` command to connect to Wi-Fi.  Detailed instructions are
   available [on ArchWiki][arch-wiki-iwctl].

[arch-wiki-iwctl]: https://wiki.archlinux.org/title/Iwd#iwctl

## Fixing the `genstrap.sh` Script

{{<div class="notice--success">}}
**TL;DR:** I had to modify the `genstrap.sh` script in the
`asahi-gentoosupport` repository to boot into the Gentoo minimal installation
environment and be able to connect to a Wi-Fi network from it.  To apply my
modifications, run the following command at the root of the
`asahi-gentoosupport` repository:

```console
$ curl {{<static-path res genstrap.sh.diff abs>}} | patch -p1
```
{{</div>}}

The next steps in the wiki page's instructions would concern running
[`genstrap.sh`][genstrap.sh] in the `asahi-gentoosupport` repository.
The script would build a root file system image for the Gentoo minimal
installation environment and install a GRUB boot entry for that environment.
The boot entry would cleverly reuse the kernel and initramfs installed by Asahi
Linux Minimal, allowing the Gentoo installation environment to boot.

I had to make two modifications to `genstrap.sh` to get a really usable Gentoo
installation environment though.  The first one was to expand the capacity of
the RAM disk used to build the file system image.  Perhaps because system
files' size had increased after the last update to the script, the RAM disk
space allocated by the script was insufficient:

```
Creating live image...

cp: error writing '/mnt/temp/var/db/pkg/dev-python/jaraco-functools-3.5.2/environment.bz2': No space left on device
```

I got rid of this error by increasing the RAM disk's size to 1 GiB, thanks to
information in a [related issue ticket][brd-space-issue]:

```diff
--- a/genstrap.sh
+++ b/genstrap.sh
@@ -42,7 +42,7 @@
 echo "Creating temporary mount..."
 echo
 mkdir /mnt/temp
-modprobe brd rd_nr=1 rd_size=923600
+modprobe brd rd_nr=1 rd_size=1048576

 if [[ $? -ne 0 ]]; then
     echo "ERROR: could not create ram block device. Installing asahi-dev"
```

The root file system image could be built successfully and boot after this
change.  However, I could not connect to Wi-Fi from the resulting Gentoo
installation environment.  The Wi-Fi interface was not available at all, and I
found the following messages from `dmesg`:

```plain {hl_lines=13}
$ dmesg | grep brcmfmac
[    1.887035] usbcore: registered new interface driver brcmfmac
[    1.887260] brcmfmac 0000:01:00.0: Adding to iommu group 2
[    1.887456] brcmfmac 0000:01:00.0: enabling device (0000 -> 0002)
[    1.992216] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4378b1-pcie for chip BCM4378/3
[    1.993260] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m-6.11-X0.bin failed with error -2
[    1.993486] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m-6.11.bin failed with error -2
[    1.993679] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m.bin failed with error -2
[    1.993866] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP.bin failed with error -2
[    1.994056] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-X0.bin failed with error -2
[    1.994249] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb.bin failed with error -2
[    1.994444] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.bin failed with error -2
[    1.994610] brcmfmac 0000:01:00.0: brcmf_pcie_setup: Dongle setup failed
```

Based on a comparison between `dmesg` output under the Gentoo installation
environment and that under Asahi Linux Minimal, where the Wi-Fi interface was
available, the issue appeared to be triggered by missing firmware:

```plain {hl_lines="10-12"}
[    1.426797] usbcore: registered new interface driver brcmfmac
[    1.428942] brcmfmac 0000:01:00.0: Adding to iommu group 2
[    1.429249] brcmfmac 0000:01:00.0: enabling device (0000 -> 0002)
[    1.537313] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4378b1-pcie for chip BCM4378/3
[    1.538025] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m-6.11-X0.bin failed with error -2
[    1.538074] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m-6.11.bin failed with error -2
[    1.538119] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP-m.bin failed with error -2
[    1.538164] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-RASP.bin failed with error -2
[    1.538208] brcmfmac 0000:01:00.0: Direct firmware load for brcm/brcmfmac4378b1-pcie.apple,atlantisb-X0.bin failed with error -2
[    2.072563] brcmfmac: brcmf_c_process_txcap_blob: TxCap blob found, loading
[    2.073063] brcmfmac: brcmf_c_process_cal_blob: Calibration blob provided by platform, loading
[    2.081177] brcmfmac: brcmf_c_preinit_dcmds: Firmware: BCM4378/3 wl0: Feb  8 2022 01:44:45 version 18.60.21.0.7.8.126 FWID 01-1cdae627
```

This was weird, because `genstrap.sh` was [supposed
to][genstrap.sh-cp-firmware] include Broadcom firmware files for the Wi-Fi
adapter in the root file system image.  Unfortunately, additional firmware
files that Asahi Linux Minimal and Desktop would load to `/lib/firmware/vendor`
were also required, and the script did not include them, hence the Wi-Fi
interface was unavailable.

I first tried to copy the missing files to `/lib/firmware/vendor` in the Gentoo
installation environment and reload the `brcmfmac` kernel module.  These
actions did bring the Wi-Fi interface up, but the system still could not
connect to a Wi-Fi network as these errors showed up in `dmesg` output:

```
[  361.439282] ieee80211 phy0: brcmf_msgbuf_query_dcmd: Timeout on response for query command
[  361.439292] ieee80211 phy0: brcmf_cfg80211_get_channel: chanspec failed (-5)
[  363.487297] ieee80211 phy0: brcmf_msgbuf_query_dcmd: Timeout on response for query command
[  363.487302] ieee80211 phy0: brcmf_cfg80211_get_tx_power: error (-5)
[  384.031294] ieee80211 phy0: brcmf_msgbuf_query_dcmd: Timeout on response for query command
[  384.031305] ieee80211 phy0: brcmf_vif_set_mgmt_ie: vndr ie set error : -5
[  387.039303] ieee80211 phy0: brcmf_msgbuf_query_dcmd: Timeout on response for query command
[  387.039312] ieee80211 phy0: brcmf_run_escan: error (-5)
[  387.039317] ieee80211 phy0: brcmf_cfg80211_scan: scan error (-5)
```

Next, I `grep`ped Asahi Linux Minimal system files, starting with `grep -r
/lib/firmware/vendor`, to see whether any additional steps were required to
make the Wi-Fi interface functional.  I got [some
results][asahi-scripts-vendorfw] from some dracut and mkinitcpio hooks and
scripts, which led me to hypothesize that the firmware files must be present
upon the first load of the Wi-Fi adapter's driver module, hence they would be
loaded during the initramfs stage.  Asahi Linux wiki had [a
paragraph][asahi-vendorfw] with similar idea:

> Firmware must be located and loaded before udev starts up. This is because
> udev can arbitrarily cause modules to load and devices to probe (even if not
> triggered directly, the kernel can e.g. discover PCI devices while the
> initramfs is already running), and this creates race conditions where
> firmware might not be available when it is needed.

Thus, I fixed this issue with additional changes to `genstrap.sh` shown below.
After I ran command `net-setup wlp1s0f0`, where `wlp1s0f0` was the Wi-Fi
interface's name, the Gentoo installation environment finally connected to my
Wi-Fi network.

```diff
--- a/genstrap.sh
+++ b/genstrap.sh
@@ -74,6 +74,7 @@ cp -r /lib/modules/$(uname -r) lib/modules/
 depmod -a --basedir=. $(uname -r)

 cp -r /lib/firmware/brcm/. lib/firmware/brcm/.
+cp -r /lib/firmware/vendor lib/firmware/
 # The squashfs doesn't log in automatically for some reason?
 echo "agetty_options=\"--autologin root\"" >> etc/conf.d/agetty
 sed -i 's/\<agetty\>/& --autologin root/g' etc/inittab
@@ -102,7 +103,6 @@ dracut --force \
     --add-drivers "nvme-apple" \
     --add-drivers "squashfs" \
     --add-drivers "apple-dart" \
-    --add-drivers "brcmfmac" \
     --add "dmsquash-live" \
     --filesystems "squashfs ext4" \
     --include overlay / \
```

[genstrap.sh]: https://github.com/chadmed/asahi-gentoosupport/blob/main/genstrap.sh
[brd-space-issue]: https://github.com/chadmed/asahi-gentoosupport/issues/6
[genstrap.sh-cp-firmware]: https://github.com/chadmed/asahi-gentoosupport/blob/ba26bf73615a1eb813d7967afbb9581e9da5a295/genstrap.sh#L76
[asahi-scripts-vendorfw]: https://github.com/AsahiLinux/asahi-scripts/search?q=%2Flib%2Ffirmware%2Fvendor
[asahi-vendorfw]: https://github.com/AsahiLinux/docs/wiki/Open-OS-Ecosystem-on-Apple-Silicon-Macs#linux-specific

## Performance

The Gentoo installation process would involve building a lot of packages for
the first time, which gave me the first peek into Apple M1's CPU performance in
terms of how fast it could compile programs and how much heat it would produce
under heavy loads.

### Package Build Times

I compared the time taken to build some software packages between the Mac mini
and two x86-64-based laptops I had been using for developing and testing Gentoo
packages.  These machines' specifications are summarized in the following
table:

| Model | Mac mini (2020) | HP Envy x360 13-ay0000 | Dell XPS 15 9570 |
| :---- | :-------------: | :--------------------: | :--------------: |
| CPU | Apple M1 | AMD Ryzen 7 4700U | Intel Core i7-8750H |
| CPU Power Limit | < 39 W[^m1-pwr] | 28 W[^ryzen-pwr] | 56 W[^core-pwr] |
| CPU Cores (Threads) | 4 (4) &times; Firestorm + 4 (4) &times; Icestorm | 8 (8) &times; Renoir (Zen 2) | 6 (12) &times; Coffee Lake |
| CPU Process | 5 nm | 7 nm | 14 nm |
| Year of Launch | 2020 | 2020 | 2018 |

[^m1-pwr]: I did not find the precise figure for how much power the M1 on Mac
    mini was allowed to consume.  [Apple's official support
    document][mac-mini-pwr-consumption] stated that the maximum power
    consumption of the entire machine with the highest configuration would be
    39 W, so the CPU power limit must be less than that.
[^ryzen-pwr]: This was not the stock CPU power limit set by the machine's
    manufacturer; I overrode it using [RyzenAdj][sys-power/RyzenAdj].
[^core-pwr]: Despite operating at the stock power limit, I undervolted the CPU
    using [intel-undervolt][sys-power/intel-undervolt], so it would perform
    better under the same power.

For each machine, I collected the following data:

- The [*Standard Build Unit* (SBU)][lfs-sbu], which is a concept from the
  *Linux From Scratch* (LFS) book.  The book uses this unit to approximate each
  software package's build time.  I measured it by compiling GNU binutils 2.39
  without parallelism on a tmpfs using the instructions
  [here][lfs-binutils-pass1].

- Build time of `sys-devel/binutils-2.39-r4` under Portage reported by
  [`qlop`][gentoo-wiki-qlop], to compare with the SBU.  This differs from SBU
  mainly in parallelism: by default, Portage would attempt to utilize all CPU
  threads available on the system to build packages.

- Build times of some other packages under Portage reported by `qlop`.  I
  picked some packages that had been recently built on all of those machines
  under equivalent configurations.  Reasons for a package not participating in
  the comparison include:
  - The package had not been built on one of the machines yet, e.g.
    `sys-devel/gcc`, as I had been using the compiler included in the stage3
    tarball on the Mac mini.
  - The package was built with different USE flags, e.g. `media-libs/mesa`,
    as varying `VIDEO_CARDS` USE flags were enabled on different machines.
  - The package was built with other variations on different machines, e.g. the
    Linux kernel, due to different kernel sources (Asahi Linux-patched sources
    vs. upstream sources) and configurations being used.

These are the build times:

| CPU | M1 @ Mac mini (2020) | Ryzen 7 4700U @ 28 W | Core i7-8750H @ 56 W |
| :-- | -------------------: | -------------------: | -------------------: |
| LFS SBU              |  2'09" |  2'37" |  2'49" |
| `sys-devel/binutils` |    51" |  1'00" |  1'02" |
| `sys-apps/systemd`   |  1'20" |  1'53" |  1'41" |
| `sys-devel/llvm`     | 18'11" | 24'35" | 24'08" |
| `sys-devel/clang`    | 18'56" | 25'15" | 24'35" |

For each build time item, the M1 could save 15 to 30% of time compared to the
two x86-64 laptops of mine while maintaining high power efficiency, which was
amazing in my opinion.

[mac-mini-pwr-consumption]: https://support.apple.com/en-us/HT201897
[sys-power/RyzenAdj]: https://packages.gentoo.org/packages/sys-power/RyzenAdj
[sys-power/intel-undervolt]: https://packages.gentoo.org/packages/sys-power/intel-undervolt
[lfs-sbu]: https://www.linuxfromscratch.org/lfs/view/stable/chapter04/aboutsbus.html
[lfs-binutils-pass1]: https://www.linuxfromscratch.org/lfs/view/stable/chapter05/binutils-pass1.html
[gentoo-wiki-qlop]: https://wiki.gentoo.org/wiki/Q_applets#Extracting_information_from_emerge_logs_.28qlop.29

### Thermal and Noise

Even under sustained heavy loads, the thermal behavior of the Mac mini was also
impressive.  While building large packages like LLVM and Clang consecutively
for dozens of minutes, the chassis only became slightly warmer.  The fan would
spin in this case, as it would normally do when the system had been idle, but
without ever increasing the fan speed -- only the air blown out became a little
warmer.  During winter time, do not count on effectively warming your hands
with the heat generated by the Mac mini while it is compiling a package under
Gentoo.

Because the fan would not speed up, the system would emit no audible noise at
all under loads as well.  I had never been accustomed to a quiet, long run of
Portage: on both of those two laptops, the fan would spin at its maximum speed
after only a few minutes of peak loads, generating some noise; on the Mac mini,
I could not tell the system's load from the fan's loudness at all since it had
always been quiet.

## "Distribution Kernel" ebuilds for the Asahi Linux Kernel

On my other Gentoo systems, I had been using a [distribution
kernel][gentoo-wiki-dist-kernel] package to automate kernel builds and updates.
At first, I had missed them on the Mac mini since no distribution kernel
packages were based on the Asahi Linux-patched sources, which were required for
certain hardware functionality.  I had downloaded the kernel sources from Asahi
Linux [with Git][gentoo-kernel-git] and built the kernel manually.  Soon, I
successfully created my own `sys-kernel/asahi-kernel` package to continue the
distribution kernel experience on the Mac mini.

A distribution kernel package would need a default kernel configuration in
addition to the kernel sources.  For the Asahi Linux kernel, the
[configuration][linux-asahi-config] used to build the `linux-asahi` package on
Asahi Linux Desktop and Minimal could be used as the default configuration.
The kernel sources would naturally be the Asahi Linux-patched sources.  Then, a
"distribution kernel" ebuild for the Asahi Linux kernel could be created by
adding those files' links to `SRC_URI`, writing a `src_prepare` function to
prepare a kernel configuration, and inheriting `kernel-build.eclass` to let it
handle the remaining tasks in compiling and installing a kernel.  The following
ebuild snippet, although not really a functional one (feel free to try!), shows
the gist of it:

```bash
# Copyright 2020-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit kernel-build

DESCRIPTION="Asahi Linux kernel for Apple silicon-based Macs built from sources"
HOMEPAGE="https://asahilinux.org/"

PKGBUILD_CONFIG_COMMIT="da67cf02622899775c233f52e441fc8127f51d99"
SRC_URI="
	https://github.com/AsahiLinux/linux/archive/refs/tags/asahi-${PV}.tar.gz
	https://raw.githubusercontent.com/AsahiLinux/PKGBUILDs/${PKGBUILD_CONFIG_COMMIT}/linux-asahi/config
		-> linux-asahi.config.${PKGBUILD_CONFIG_COMMIT}
"
S="${WORKDIR}/linux-asahi-${PV}"

LICENSE="GPL-2"
KEYWORDS="~arm64"

src_prepare() {
	default
	cp "${DISTDIR}/linux-asahi.config.${PKGBUILD_CONFIG_COMMIT}" .config || die
}
```

I call it a "distribution kernel" with quotes because it really is not a kernel
provided by Gentoo as a distribution.  This term is used here only to indicate
that the ebuild can automatically handle the entire kernel configuration, build
and installation process, just like Gentoo's official distribution kernel
packages.

The complete and fully functional "distribution kernel" ebuilds are available
in my personal ebuild repository:
- [`sys-kernel/asahi-kernel`][sys-kernel/asahi-kernel], which corresponds to
  the `linux-asahi` package on Asahi Linux Desktop and Minimal.
- [`sys-kernel/asahi-edge-kernel`][sys-kernel/asahi-edge-kernel], which
  corresponds to the `linux-asahi-edge` package.  `linux-asahi-edge` is built
  from the same sources as `linux-asahi` but with additional [experimental
  kernel configuration options][linux-asahi-edge-config] enabled.

[gentoo-wiki-dist-kernel]: https://wiki.gentoo.org/wiki/Project:Distribution_Kernel
[gentoo-kernel-git]: {{<relref 2022-03-04-gentoo-kernel-git>}}
[linux-asahi-config]: https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config
[sys-kernel/asahi-kernel]: https://github.com/Leo3418/leo3418-ebuild-repo/blob/2e063a35efb385b3f2831db875d4ee959615554a/sys-kernel/asahi-kernel/asahi-kernel-6.1_p3-r1.ebuild
[sys-kernel/asahi-edge-kernel]: https://github.com/Leo3418/leo3418-ebuild-repo/blob/2e063a35efb385b3f2831db875d4ee959615554a/sys-kernel/asahi-edge-kernel/asahi-edge-kernel-6.1_p3-r1.ebuild
[linux-asahi-edge-config]: https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config.edge

## Hardware Support and User Experience

As of Asahi Linux kernel 6.2-rc2-1, most hardware features on the Mac mini that
matter to me work, like Wi-Fi, Bluetooth, and USB.  One feature I miss is DP
Alt Mode, which would have enabled video output through my USB-C dongle's HDMI
port.  I have been connecting my peripherals -- including my monitor -- to the
dongle to switch between machines faster.  For example, if the dongle is
connected to my laptop, and I would like to switch to the Mac mini running
macOS, I can simply replug the dongle into the Mac mini's USB-C port to get all
the peripherals connected to it at once.  However, with the current Asahi Linux
kernel, until DP Alt Mode support is added, I have to unplug the HDMI cable
from the dongle and connect it directly to the Mac mini's HDMI port.

I have encountered two additional, smaller issues related to HDMI, though I am
not sure if they can be solved by installing additional software packages.

- HDMI audio output is not available.  However, I have only set up a basic ALSA
  configuration and have not installed either PipeWire or PulseAudio, which
  might be the cause.  I have not bothered with audio since the Mac mini's
  built-in speaker works and I do not plan to seriously consume any audible
  content on it.

- The desktop environment I have installed under Gentoo on the Mac mini, which
  is MATE, cannot send my monitor to power save mode after the system has been
  idle for a while; it displays a black screen instead when it is supposed to
  turn off the display.  I have not tried another desktop environment yet to
  see if this is a MATE-specific issue, but because I will actively use the Mac
  mini most of the time when I connect my monitor to it, I have not bothered
  with this issue either.

In general, my hardware support-wise user experience with the Asahi Linux
kernel has been satisfying.  I have no trouble browsing the web using Firefox,
developing and testing ebuilds (including the Asahi Linux kernel ebuilds of
course), or maintaining this website.  In fact, I wrote this article entirely
under Gentoo on the Mac mini!

This probably only applies to Mac mini 2020 though; if I had got a MacBook
instead, my mileage might have varied.  Compared to MacBooks, the Mac mini has
the following properties that might have contributed to better user experience
in terms of hardware support:

- The Mac mini should have fewer issues pertaining to input/output devices in
  general.  After all, it is a "BYODKM" (Bring Your Own Display, Keyboard, and
  Mouse) device as Steve Jobs defined.  In contrast, for MacBooks, the Asahi
  Linux developers would need to do more work on the built-in devices to
  deliver satisfying user experience, like making the internal display's
  brightness adjustable, and bringing up the touchpad.

- The Mac mini does not run on a battery, so power management issues would not
  be as impactful as on MacBooks.  On a laptop, if the CPU cannot enter an
  efficient power save state when idle, or suspend does not work, then its
  mobility is severely limited due to shorter battery life and the risk of
  overheating in a bag or a pouch.

- The Asahi Linux developers should have spent the most time and effort
  supporting Mac mini 2020.  After all, it is one of the first Apple
  silicon-based Macs released and was selected as the [first
  target][asahi-device-support] of the Asahi Linux project.

[asahi-device-support]: https://asahilinux.org/about/#what-devices-will-be-supported

## My Two Cents

I view Mac mini 2020 running the Asahi Linux kernel as a great choice for
developers who need an ARM64 computer and accept the compact desktop category.
Some developers might want to test software packages' portability and
compatibility on ARM64, including upstream package authors and GNU/Linux
distribution maintainers. They mainly use toolchains, text editors, and other
development tools to complete the work, all of which are available on a
GNU/Linux system running on the Asahi Linux kernel.  They can use the Mac mini
either as a workstation by running a desktop environment on it, or as a
headless build/development server by connecting it to no peripherals but a
network.

The CPU performance of Apple M1 on the Mac mini is not the greatest among all
desktop computers, but I think it is good enough as an ARM64 processor.  The M1
[is not comparable][phoronix-m1-vs-x86-64] with x86-64 desktop CPUs like the
recent AMD Ryzen 5 and Intel Core i5 models; however, to developers who require
ARM64, those x86-64 CPUs are obviously not relevant.  Among the ARM64 CPUs
relevant to them, the M1 [outperforms][phoronix-m1-vs-pi] other CPUs shipped on
devices one can use for GNU/Linux software development, like Raspberry Pis.
Linus Torvalds has [praised][lkml-linux-5.19] the value of Asahi Linux and
Apple silicon-based Macs to development on ARM64 too:

> ... I did the [Linux 5.19] release (and am writing this) on an arm64 laptop.
> It's something I've been waiting for for a _loong_ time, and it's finally
> reality, thanks to the Asahi team.  We've had arm64 hardware around running
> Linux for a long time, but none of it has really been usable as a development
> platform until now.

Across the spectrum of economy and performance, Mac mini 2020 is also the most
balanced option of an ARM64 computer that I am aware of:

- Raspberry Pis are cheaper but less beefy.
- MacBooks are more expensive and thus less cost-effective for people who
  already have peripherals.  In addition, as of 6.2-rc2-1, no MacBooks can be
  used with an external monitor yet when they run the Asahi Linux kernel, due
  to lack of support for HDMI video output and DP Alt Mode.
- The Mac Studio comes with a more powerful chip but a significantly higher
  price too.

For other developers and users who care less about the CPU architecture and
look for a low-power machine or a compact desktop computer to run GNU/Linux,
Mac mini 2020 is also a solid choice in my opinion.  These types of computer
typically use a mobile x86-64 CPU akin to the Ryzen 7 4700U and Core i7-8750H
on my laptops.  As the build time comparison I presented above shows, the M1 on
the Mac mini has competitive performance among those CPUs.

I would not recommend the combination of an Apple silicon-based Mac and Asahi
Linux to everyone though.  As of writing, the Asahi Linux wiki declares that
the project is "just getting started" and "still in very early alpha stages".
Some use cases are certainly not well supported yet:

- The project is still testing some fundamental hardware features, if not
  working on them.  One example is the GPU driver, which was still in the
  testing phase as of Asahi Linux kernel 6.2-rc2-1.  Without the GPU driver,
  the [Extreme Tux Racer][etr] game could not reach 60 FPS under 1080p based on
  my testing.  On my laptops, this game has been able to easily reach hundreds
  of FPS on integrated graphics.

- The Asahi Linux kernel currently uses the 16 KiB page size, resulting in
  compatibility issues with a few software packages.  Those packages might
  assume the 4 KiB page size, which is common on all CPU architectures.  The
  Asahi Linux wiki [explains][asahi-broken-sw] this in details.

- Users who rely on proprietary programs might encounter more incompatibility
  problems.  Most of those programs do not support ARM64 Linux at all, like
  Google Chrome and Zoom; if they were, the 16 KiB page size issue might still
  apply.

[phoronix-m1-vs-x86-64]: https://www.phoronix.com/review/apple-m1-linux-perf/5
[phoronix-m1-vs-pi]: https://www.phoronix.com/review/apple-m1-linux-perf/7
[lkml-linux-5.19]: https://lore.kernel.org/lkml/CAHk-=wgrz5BBk=rCz7W28Fj_o02s0Xi0OEQ3H1uQgOdFvHgx0w@mail.gmail.com/T/#u
[etr]: https://sourceforge.net/projects/extremetuxracer/
[asahi-broken-sw]: https://github.com/AsahiLinux/docs/wiki/Broken-Software
