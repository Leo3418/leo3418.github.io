---
title: "Compile Raspberry Pi's `vcgencmd` on Fedora"
lang: en
tags:
  - Raspberry Pi
  - Fedora
  - GNU/Linux
asciinema-player: true
toc: true
---

## Updates

### {{ "2020-07-29" | date: site.data.l10n.date_format }}

So, only one day after this post was published, the Raspberry Pi software
maintainers made a
[patch](https://github.com/raspberrypi/userland/commit/fdc2102ccf94a397661d495c6942eb834c66ee28)
that allowed `vcgencmd` to be compiled directly on Fedora without any
workaround. As a result, **you may now build `vcgencmd` on Fedora with simply
`./buildme --aarch64`**.

The building method described in this post still works after the patch, but it
is no longer necessary. You can definitely use it without any issues, but just
remember that `./buildme --aarch64` is now working fine and is probably the
easier way to compile `vcgencmd`.

`./buildme --aarch64` replaces the following commands:

```console
$ cmake -DARM64=ON .
$ make -j 4
$ sudo make install
```

The remaining instructions in this post are still accurate and working. In
addition, you always have the option to [install my `vcgencmd` build with
DNF](#use-dnf-to-install-the-program) if you are not a fan of building software
packages yourself.

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

## ~~Challenge~~

{: .message-box}
**Update**: the issue described in this section has been fixed by the upstream.

You probably have already tried to build a software package distributed by
others. High-quality packages contain build instruction which makes the
building process as easy as copy-pasting some commands. Although the `userland`
package's build instruction is not very clear, at least it tells you to build
with the `buildme` script and include the `--aarch64` flag if you are compiling
the package for 64-bit ARM. ~~Unfortunately, `buildme --aarch64` will fail on
Fedora, as shown below.~~

{% include asciinema-player.html name="build-failure.cast"
    poster="data:text/plain,Presentation of the issue, which has been fixed" %}

So, I spent about an hour figuring out what the `buildme` script would do and
how the package could be built without errors. I was able to find a solution,
which I will introduce in the rest of this post.

Multiple tickets concerning the inability to compile `userland` on Fedora have
been opened ([GH-631](https://github.com/raspberrypi/userland/issues/631),
[GH-635](https://github.com/raspberrypi/userland/issues/635)). They suggested
that this problem was related to GCC 10. The solution I am giving here does not
require downgrading GCC, so you can stick with the latest version of GCC
shipped with Fedora.

## Build the Program

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

3.  This is the most important step in the building process. Use the following
    commands ~~instead of `./buildme --aarch64`~~ to compile the program:

    ```console
    $ cmake -DARM64=ON .
    $ make -j 4
    ```

    {% include asciinema-player.html name="compile.cast" poster="npt:17.5"
    start_at="14" %}

## Install the Program

Now that the `vcgencmd` program, along with the `userland` package, has been
compiled without errors, it is time to install it to the system. Like many
other software packages, the command to install `userland` is `make install`.
The package is always copied into `/opt/vc`. Because the `/opt` directory is
usually only writable by `root`, you need to run the command with `sudo`:

```console
$ sudo make install
```

After this command completes, you will find the `vcgencmd` program under
`/opt/vc/bin`.

{% include asciinema-player.html name="make-install.cast" %}

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

## Invoke the Program

On Fedora, if you attempt to use `vcgencmd` to read hardware information as a
normal user, you might get the `VCHI initialization failed` error. Most
solutions to this issue you can find online would tell you to add the user to
the `video` group, but in my testing this did not work on Fedora.

The easiest workaround is to **run `vcgencmd` with `sudo`**.

{% include asciinema-player.html name="run-with-sudo.cast" poster="npt:9.7" %}

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
`/etc/ld.so.conf.d` and modifying `~/.bashrc`. However, you still have to run
`vcgencmd` with `sudo`.

{% include asciinema-player.html name="dnf.cast" poster="npt:3.8" %}

You can also build the RPM packages for `userland` by yourself from the SPEC
file I wrote for it. For this one, I will only give you a demo of how to build
the RPM packages instead of detailed instructions.

{% include asciinema-player.html name="build-rpm.cast"
    poster="data:text/plain,RPM Build Demo" %}
