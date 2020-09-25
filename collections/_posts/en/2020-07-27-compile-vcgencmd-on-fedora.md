---
title: "Install Raspberry Pi's `vcgencmd` on Fedora"
lang: en
tags:
  - Raspberry Pi
  - Fedora
  - GNU/Linux
asciinema-player: true
toc: true
last_modified_at: 2020-09-25
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

    After the compilation completes and before the installation, you might see
    a prompt from `sudo` that demands your password. Enter it to proceed.

    ```console
    $ ./buildme --aarch64
    ```

    {% include asciinema-player.html name="build-and-install.cast"
    poster="npt:16.5" start_at="10" %}

After this command completes, you will find the `vcgencmd` program under
`/opt/vc/bin`.

{% include asciinema-player.html name="after-install.cast" poster="npt:6" %}

## Tell the System About `/opt/vc`

When you run `vcgencmd` now, you will see the following error message:

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

Running `/opt/vc/bin/vcgencmd` now should no longer get you the error message.

{% include asciinema-player.html name="ldconfig.cast" poster="npt:5" %}

It can be tedious when you have to type in the full path to the `vcgencmd`
program in order to run it. To save yourself from the torture, you can add
`/opt/vc/bin` to the `PATH` environment variable by editing `~/.bashrc`:

```diff
 # User specific environment
 if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
 then
     PATH="$HOME/.local/bin:$HOME/bin:$PATH"
 fi
+PATH="/opt/vc/bin:$PATH"
 export PATH
```

Then, run the following command for the change to take effect:

```console
$ source ~/.bashrc
```

{% include asciinema-player.html name="add-to-path.cast" poster="npt:17" %}

## Configure Device Permissions and User Group

At this point, if you attempt to use `vcgencmd` to read hardware information as
a normal user, you might get the `VCHI initialization failed` error.

{% include asciinema-player.html name="init-failed.cast" poster="npt:7" %}

Most solutions to this issue you can find online would tell you to add the user
to the `video` group. However, they typically assume you are running `vcgencmd`
under Raspberry Pi OS. On Fedora, doing only this will not suffice. You need to
configure the VCHI device so that `video` group users can access it. This is
done by adding a new [udev
rule](https://wiki.archlinux.org/index.php/udev#About_udev_rules) shown
[here](https://github.com/sakaki-/genpi64-overlay/blob/master/media-libs/raspberrypi-userland/files/92-local-vchiq-permissions.rules),
published by GitHub user [**@sakaki-**](https://github.com/sakaki-).

```console
$ cd /usr/lib/udev/rules.d/
$ sudo curl -O https://raw.githubusercontent.com/sakaki-/genpi64-overlay/master/media-libs/raspberrypi-userland/files/92-local-vchiq-permissions.rules
```

{% include asciinema-player.html name="udev-rule.cast" poster="npt:11" %}

Once this is done, any user in the `video` group can invoke `vcgencmd` without
getting the same error.

```console
$ sudo usermod -aG video $USER
```

{: .notice--warning}
**Note:** the changes listed in this section require a reboot to take effect.

{% include asciinema-player.html name="add-to-group.cast" poster="npt:7.2" %}

## Use DNF to Install the Program

Don't want to build `vcgencmd` by yourself? I have made an RPM package for
`userland` and uploaded it to a [Copr
repository](https://copr.fedorainfracloud.org/coprs/leo3418/raspberrypi-userland/),
so you can get `vcgencmd` working by simply running the following DNF commands:

```console
$ sudo dnf copr enable leo3418/raspberrypi-userland
$ sudo dnf install raspberrypi-userland
```

With this installation method, you can skip all the building and installation
steps described above, including creating a `.conf` file under
`/etc/ld.so.conf.d`, modifying `~/.bashrc`, and installing the udev rule. The
only thing you must do is to add your user account to the `video` group.

{% include asciinema-player.html name="dnf.cast" poster="npt:3.8" %}

You can also build the RPM packages for `userland` by yourself from the SPEC
file I wrote for it. For this one, I will only give you a demo of how to build
the RPM packages instead of detailed instructions.

{% include asciinema-player.html name="build-rpm.cast"
    poster="data:text/plain,RPM Build Demo" %}
