---
title: "Install Raspberry Pi's `vcgencmd` on Fedora"
lang: en
tags:
  - Raspberry Pi
  - Fedora
  - GNU/Linux
categories:
  - Tutorial
asciinema-player: true
toc: true
last_modified_at: 2022-03-11
---

This post is a continuation of my [previous
one](/2020/07/24/fedora-raspi-cluster.html) about setting up a cluster of
Raspberry Pis running Fedora. After I got the cluster to compute something,
[**@ColsonXu**](https://github.com/ColsonXu), the cluster's owner, asked me if
I could monitor the CPU temperature of each Raspberry Pi by running this
command:

```console
$ /opt/vc/bin/vcgencmd measure_temp
```

The [`vcgencmd`
program](https://www.raspberrypi.org/documentation/raspbian/applications/vcgencmd.md)
is included in Raspberry Pi OS (formerly called Raspbian) as a utility for
retrieving information about Raspberry Pi's hardware. However, it is not
included in Fedora's software repositories. Luckily though, the source code of
`vcgencmd`, along with the entire [`userland`
package](https://github.com/raspberrypi/userland) that contains the program, is
available, so we can compile it on our own.

## Build and Install the Program

1.  Install the required compilers and build tools, and Git for retrieving the
    source code.

    ```console
    $ sudo dnf install cmake gcc gcc-c++ make git
    ```

    {% include asciinema-player.html name="install-deps.cast" poster="npt:9" %}

2.  Clone the `userland` package's source code, then enter its directory.

    ```console
    $ git clone https://github.com/raspberrypi/userland.git
    $ cd userland
    ```

3.  Use `./buildme --aarch64` to compile the program for the `aarch64`
    architecture Fedora runs on and install it.

    After the compilation completes and before the installation, there might a
    prompt from `sudo` asking for authentication. Enter the required
    credentials to proceed.

    ```console
    $ ./buildme --aarch64
    ```

    {% include asciinema-player.html name="build-and-install.cast"
    poster="npt:16.5" start_at="10" %}

After this command completes, the `vcgencmd` program can be found under
`/opt/vc/bin`.

{% include asciinema-player.html name="after-install.cast" poster="npt:6" %}

## Tell the System About `/opt/vc`

If the `vcgencmd` program is invoked now, the following error message is
expected to show up:

```console
$ /opt/vc/bin/vcgencmd
/opt/vc/bin/vcgencmd: error while loading shared libraries: libvchiq_arm.so: cannot open shared object file: No such file or directory
```

This error is caused by the operating system not knowing where to find the
shared object file `libvchiq_arm.so`. That file does exist under `/opt/vc/lib`,
but the system is not told to find the file from that directory. To solve this
issue, create a file whose name ends with `.conf` under the `/etc/ld.so.conf.d`
directory, and add the following line to the file:

```
/opt/vc/lib
```

Then, run the following command to apply the change:

```console
$ sudo ldconfig
```

Running `/opt/vc/bin/vcgencmd` now should no longer produce the error message.

{% include asciinema-player.html name="ldconfig.cast" poster="npt:5" %}

It can be tedious when the full path to the `vcgencmd` program must be entered
to run it every time. To avoid this, add `/opt/vc/bin` to the `PATH`
environment variable. One way of doing this is to edit `~/.bashrc`:

```diff
  # User specific environment
  if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
  then
      PATH="$HOME/.local/bin:$HOME/bin:$PATH"
  fi
+ PATH="/opt/vc/bin:$PATH"
  export PATH
```

Then, run the following command for the change to take effect:

```console
$ source ~/.bashrc
```

{% include asciinema-player.html name="add-to-path.cast" poster="npt:17" %}

## Configure Device Permissions and User Group

At this point, if `vcgencmd` is run using a normal user account to read
hardware information, the `VCHI initialization failed` error might show up.

{% include asciinema-player.html name="init-failed.cast" poster="npt:7" %}

Most solutions to this issue posted online would say that the user account used
to run the program should be added to the `video` group. However, these
solutions assume that `vcgencmd` is being run on Raspberry Pi OS. On Fedora,
doing only this will not suffice. The VCHI device also needs to be configured
so that `video` group users can access it. This is done by adding a new [udev
rule](https://wiki.archlinux.org/index.php/udev#About_udev_rules):

```
KERNEL=="vchiq",GROUP="video",MODE="0660"
```

{: .notice--warning}
This rule has only been tested on relatively-new Linux kernel versions (5.16
and above); it might not work on older kernels. If the rule does not work
because the kernel version is too old, please upgrade to the latest kernel.

To add the udev rule, create a new file whose file extension is `.rules` under
`/etc/udev/rules.d`, and add the rule as a line of text to the file. This can
be achieved by running the following command, which will install the rule to a
file called `92-local-vchiq-permissions.rules`:

```console
$ sudo tee /etc/udev/rules.d/92-local-vchiq-permissions.rules <<< 'KERNEL=="vchiq",GROUP="video",MODE="0660"'
```

Once the udev rule is copied to the correct location, it may be applied
immediately without a reboot by using `udevadm`:

```console
$ sudo udevadm trigger /dev/vchiq
```

To see if the rule is in effect, check the permission settings for the VCHI
device file `/dev/vchiq`. If its group is `video`, then the udev rule has been
successfully activated.

```console
$ ls -l /dev/vchiq
crw-rw----. 1 root video 511, 0 Nov  9 23:17 /dev/vchiq
```

Once this is done, any user in the `video` group can invoke `vcgencmd` without
getting the same error. The following command can be used to add the current
user account to the `video` group; however, **the change will not take effect
until the account is logged out**.

```console
$ sudo usermod -aG video $USER
```

{% include asciinema-player.html name="add-to-group.cast" poster="npt:7.2" %}

## Use DNF to Install the Program

Don't want to build `vcgencmd` by yourself? I have made an RPM package for
`userland` and uploaded it to a [Copr
repository](https://copr.fedorainfracloud.org/coprs/leo3418/raspberrypi-userland/),
so anyone can get `vcgencmd` working by simply running the following DNF
commands:

```console
$ sudo dnf copr enable leo3418/raspberrypi-userland
$ sudo dnf install raspberrypi-userland
```

With this installation method, all the building and installation steps
described above can be skipped, including creating a `.conf` file under
`/etc/ld.so.conf.d`, modifying `~/.bashrc`, and installing the udev rule. The
only thing that must be done manually is to add the user account to the `video`
group.

{% include asciinema-player.html name="dnf.cast" poster="npt:3.8" %}

You can also build the RPM packages for `userland` by yourself from the SPEC
file I wrote for it. For this one, I will only give a demo of how to build the
RPM packages instead of detailed instructions.

{% include asciinema-player.html name="build-rpm.cast"
    poster="data:text/plain,RPM Build Demo" %}
