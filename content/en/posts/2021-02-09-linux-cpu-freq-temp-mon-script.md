---
title: "Create a CPU Frequency and Temperature Monitoring Bash Script for Linux-based Systems"
tags:
  - Unix Programs
  - GNU/Linux
categories:
  - Tutorial
lastmod: 2021-02-09
---

This post will show you a way to monitor CPU frequency and temperature on
Linux-based systems without aid of any programs or packages that are not
commonly preinstalled on major GNU/Linux distributions.  No extra hardware
drivers are required: the magic is done merely by a short Bash script in just a
few lines that only relies on mechanisms provided by the Linux kernel itself
and some most essential Unix commands.

You can click [here][script] to jump to the script directly.  If you are
interested in seeing how I came up with the script, please read on.

[script]: #script

If you are a Windows power user, you have probably used the Task Manager as a
simple system monitor.  It allows you to check CPU utilization and frequency,
which are the most essential indicators of your system's load.  It is not the
most comprehensive hardware monitoring tool, but it is the most handy and
accessible utility.  It exists in every Windows installation and can be fired
up easily and quickly.

![CPU statistics in Windows Task Manager]({{< static-path img windows-task-manager.png >}})

I have been struggling to find an ideal Windows Task Manager equivalent for
GNU/Linux.  As a GNOME user, the bundled System Monitor, as shown below, can
only give me utilization of each CPU execution unit and does not show CPU
frequency.  [htop][htop] is a great choice for hardware monitoring on
GNU/Linux, but on some distributions, e.g. Fedora, it is not shipped by default
and thus requires manually installing an extra package.

[htop]: https://htop.dev/

![GNOME System Monitor does not show CPU frequency]({{< static-path img gnome-system-monitor.png >}})

Recently, I have discovered a simple command for getting each CPU execution
unit's frequency on an `x86_64` system.  It only relies on `grep`, a
fundamental Unix program that should be preinstalled on every GNU/Linux system:

```console
$ grep 'cpu MHz' /proc/cpuinfo
```

{{< asciicast poster="npt:6.2" >}}
{{< static-path res cpu-freq.cast >}}
{{< /asciicast >}}

Sometimes I am also interested in seeing how CPU temperature is affected by
system loads, especially when I am testing a cooling solution.  In this case, I
would want to see CPU temperature and CPU frequency at the same time.  After a
brief research, I found a way to get CPU temperature without help of any fancy
packages like `lm-sensors`:

```console
$ cat /sys/class/thermal/thermal_zone0/temp
```

{{< asciicast poster="npt:6" >}}
{{< static-path res cpu-temp.cast >}}
{{< /asciicast >}}

The value shown in this command's output is the CPU temperature in degrees
Celsius multiplied by 1000.  Stripping the three zeros off from the value gives
the temperature value in degrees Celsius that we are familiar with.  The
following command performs this calculation directly in Bash:

```console
$ echo $(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
```

By the way, the commands I am mentioning here assume
`/sys/class/thermal/thermal_zone0` is for the CPU, not other hardware
components like disk or wireless NIC.  This is true for all of my devices that
run a Linux-based system and allow me to check this, although there might be
very rare situations where this assumption does not hold.

Now that we know the commands for getting CPU frequency and temperature, we can
assemble them into a very simple Bash shell script for printing out CPU status:

{{< highlight bash >}}
#!/usr/bin/env bash

grep --color=never 'cpu MHz' /proc/cpuinfo
cpu_temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
echo "cpu temperature : ${cpu_temp}"
{{< /highlight >}}
{#script}

You can put this script under a location in the `PATH` environment variable to
run it easily from everywhere, e.g. `~/.local/bin` on most GNU/Linux
distributions.  To check which locations are in `PATH`, you may use `printenv
PATH`.  In addition, do not forget to make the script executable (`chmod +x`).

{{< asciicast poster="npt:3.5" >}}
{{< static-path res install.cast >}}
{{< /asciicast >}}

And if you wish to continuously monitor CPU frequency and temperature, you can
invoke the script with the [`watch`][watch] program.  It runs the command you
specify every 2 seconds and prints the command output on the screen.  In case
you want to use another interval, you can use the `-n` option to specify it.
For example, `watch -n 1` runs the command you specify every 1 second.

[watch]: https://man.archlinux.org/man/watch.1

{{< asciicast poster="npt:3.8" >}}
{{< static-path res watch.cast >}}
{{< /asciicast >}}

## Compatibility

This script should be compatible with all modern `x86_64` CPUs from AMD and
Intel.  I have tested it on a Ryzen 7 4700U and a Core i5-7200U, and it has
worked perfectly.

{{< asciicast poster="npt:5.5" >}}
{{< static-path res amd-4700u.cast >}}
{{< /asciicast >}}

{{< asciicast poster="npt:7.5" >}}
{{< static-path res intel-7200u.cast >}}
{{< /asciicast >}}

I have also tried it out on some `aarch64` devices!  The script could not read
CPU frequency, but it was still able to get CPU temperature.  The devices I
tested were a Raspberry Pi 4 running Fedora 33's Linux 5.10.9 kernel and a
Nexus 9 Android tablet running [Gentoo Android][gentoo-android] on an aging
3.10 kernel from a custom Android ROM.

[gentoo-android]: https://wiki.gentoo.org/wiki/Project:Android

{{< asciicast poster="data:text/plain,Raspberry Pi 4" >}}
{{< static-path res raspi-4.cast >}}
{{< /asciicast >}}

{{< asciicast poster="data:text/plain,Nexus 9" >}}
{{< static-path res nexus-9.cast >}}
{{< /asciicast >}}
