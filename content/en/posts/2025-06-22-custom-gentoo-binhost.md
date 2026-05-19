---
title: "Set Up a Custom Gentoo Binary Package Host"
tags:
  - Gentoo
categories:
  - Tutorial
toc: true
---

Gentoo is a GNU/Linux distribution where users themselves can easily build
software packages for the entire operating system from source code.  For a long
time, building packages on their own was the only choice Gentoo users had
because Gentoo only distributed the scripts (i.e. ebuilds) to build the
packages, not the packages' ready-to-run, pre-built binaries like on other
distributions.  Compiling software packages for a whole operating system takes
a considerable amount of time, and Gentoo users had had to deal with it.  This
all changed at the end of 2023, when [the official Gentoo binary package host
was launched][gentoo-news-binary].  It has been providing users with pre-built
binary packages for many software packages available in the Gentoo ebuild
repository, and users can install these binary packages to skip the build
process, thus saving time.

Even though the official binary package host can already satisfy many users'
needs, some users might have special use cases that a *custom* binary package
host can serve.  This article will introduce some of these example use cases
and an approach to set up a custom binary package host for Gentoo.

[gentoo-news-binary]: https://www.gentoo.org/news/2023/12/29/Gentoo-binary.html

## Definitions

For simplicity and clarity, this article will use the following terms to refer
to some commonly-mentioned meanings:

Binhost
: Binary package host.

Binpkg
: Binary package.  This refers to a file that a user can install onto a Gentoo
system via Portage (Gentoo's package manager).  A binpkg's filename typically
ends with `.gpkg.tar` or `.tbz2`, depending on its binary package format (GPKG
or XPAK respectively).

Package
: When used standalone without a qualifier (i.e. not used as in "binary
package"), this is what is technically called a *Portage package directory* in
the [manual page for `emerge`][man-emerge].  For example, each of
`app-shells/bash`, `dev-lang/python`, and `sys-devel/gcc` is a *package*.

[man-emerge]: https://dev.gentoo.org/~zmedico/portage/doc/man/emerge.1.html

Client
: A Gentoo system that has been configured to use a binhost.

Container
: An operating system installation that can run in a virtualized manner on
another operating system, e.g. a Docker container, a `systemd-nspawn`
container.  This article also considers a chroot environment a container
despite the fact that it is not ubiquitously called a "container."

Host system
: The operating system on which a container runs.

## Reasons for a Custom Binhost

The main reason to maintain a custom binhost instead of using Gentoo's official
one is to be able to apply customizations to packages while still saving time
by using binpkgs.  Gentoo provides users with various package customization
mechanisms not found on other GNU/Linux distributions, like the ones enumerated
below; however, it is generally impossible to apply these types of
customizations when binpkgs from the official Gentoo binhost are used.

- The ability to customize compiler flags (`CFLAGS`, `CXXFLAGS`, etc.).
  Compiler flags like `-march=x86-64-v4` can enable optimizations that enhance
  system performance on the latest CPU models.  Consider [CachyOS], a GNU/Linux
  distribution pitched at high performance because it distributes binaries
  compiled with optimizations for the latest x86-64 feature levels, including
  x86-64-v4.  [Benchmark][cachyos-benchmark] showing performance improvements
  of x86-64-v4 optimizations exists.  While the official Gentoo binhost [does
  provide binpkgs optimized for x86-64-v3][gentoo-news-x86-64-v3], it does not
  do so for x86-64-v4 at the time of writing, so users of the latest x86-64-v4
  CPU models (e.g. those with AMD Zen 4 or later microarchitecture) cannot
  leverage their CPU's full performance potentials with those binpkgs.

- USE flags.  In general, they allow users to enable and disable package
  features, for more functionality and reduced package footprints respectively.
  For instance, a user of a computer with a Trusted Platform Module (TPM)
  device can enable the `tpm` USE flag to allow packages to utilize it; a user
  who never uses the Samba networking protocol can disable the `samba` USE
  flag, which may reduce package sizes and build times.  Currently, a single
  binpkg file supports only one USE flag combination, so when a package's USE
  flag setting changes, either another binpkg file for that new combination
  must be used, or the package must be rebuilt from source.  While the official
  Gentoo binhost sometimes provides multiple binpkgs for the same package, each
  for a unique USE flag combination, it never can provide binpkgs for all
  possible combinations.  Thus, when a package has a USE flag setting that no
  binpkg covers, Portage falls back to building the package from source locally
  on the client.

- User patches.  Gentoo allows users to apply changes to a software package's
  source code before building it within Portage.  This enables users to
  [apply fixes to software bugs even before a new version is
  delivered][portage-user-patches-fix-bugs] and, in some cases, even [add a new
  feature to a package][portage-user-patches-grub-argon2].  The official Gentoo
  binhost does not build binpkgs with any user patches, nor does it allow users
  to upload a user patch and build a binpkg with it.  Therefore, using a binpkg
  from the official Gentoo binhost means giving up on user patches.

When a person sets up their own binhost, they can customize all the packages as
they would when they build them in the traditional way, i.e. locally from
source.  After all, to build a binpkg, the package must first have been built
from source using Portage through the same traditional process.

Another situation where a custom binhost is useful is when a package is being
installed but the official Gentoo binhost does not have a binpkg for it.  At
the time of writing, the official Gentoo binhost has binpkgs for GNOME, KDE,
some other select applications, and all dependencies thereof, but it is not
configured to build binpkgs for every single ebuild in the Gentoo ebuild
repository.  Therefore, packages that do not have a binpkg on the official
Gentoo binhost exist.  To have binpkgs for these packages, a custom binhost
must be set up.

[CachyOS]: https://cachyos.org/
[cachyos-benchmark]: https://www.phoronix.com/review/cachyos-x86-64-v3-v4
[gentoo-news-x86-64-v3]: https://www.gentoo.org/news/2024/02/04/x86-64-v3.html
[portage-user-patches-fix-bugs]: {{< relref "2021-03-01-portage-user-patches" >}}
[portage-user-patches-grub-argon2]: {{< relref "collections/gentoo-config-luks2-grub-systemd/patch-grub" >}}

## Effects

With a binhost set up through the approach that this article will introduce,
the binhost's system administrator can fully customize packages using Portage
configuration files, such as `/etc/portage/make.conf`,
`/etc/portage/package.use`, and `/etc/portage/patches`, and so the binhost will
apply the customizations when it builds binpkgs.

The system administrator can also both select packages for which they would
like to build binpkgs and exclude packages from binpkg building, and this is
generally done through Portage configuration files as well.

This article's approach will also automate builds of updated binpkgs for new
ebuilds, so the binhost can build and provide updated binpkgs autonomously;
manual interventions are not required in the normal course of operation.

One thing that this article's approach cannot enable is binpkg builds on client
demands.  For example, if the binhost does not have a binpkg for package
`foo/bar`, and a client runs a command like `emerge --ask foo/bar`, then
Portage on the client will fall back to building `foo/bar` locally; this
command will not trigger a binpkg build for `foo/bar` on the binhost.  After
all, Portage has no mechanism that allows a client to request a binhost to
build a binpkg on demand.  In this case, if a binpkg for `foo/bar` is desired,
the binhost's system administrator should complete the following process (just
once for each package):

1. On the binhost, the system administrator includes `foo/bar` in the
   collection of packages for which binpkgs should be built.
2. The system administrator triggers an initial binpkg build for `foo/bar`,
   typically by running command `emerge --ask foo/bar` in the binhost
   container.  After this is complete, when a client runs `emerge --ask
   foo/bar`, Portage on the client should start to use the binpkg.

### Building Binpkgs for an Entire System vs. Just a Few Select Packages

With this article's approach, it is possible to build binpkgs only for a small
amount of specified packages (such as some 1--100 packages) rather than all
packages needed for an entire functional Gentoo system (500--1000 packages,
depending on factors like whether a desktop environment is included), for any
reason.  (Building binpkgs for an entire system is still supported.)

One possible reason someone might wish to build binpkgs only for a small amount
of packages is to balance time saving and machine-specific performance
optimizations, especially when there are multiple client machines with an
eclectic set of CPU microarchitectures.  For example, I have a Dell XPS 15 9570
with Intel Core i7-8750H CPU, whose microarchitecture is Kaby Lake
(`-march=skylake`), at feature level x86-64-v3; I also have a Framework Laptop
13 with AMD Ryzen 7 7840U CPU, whose microarchitecture is Zen 4, at feature
level x86-64-v4.  I would like to have binpkgs for at least packages that
typically take several dozens of minutes to build, such as `sys-devel/gcc` and
`llvm-core/llvm`, so I could save a lot of time; meanwhile, on the Zen 4 CPU,
for most (if not all) packages, I would also like to have Zen 4-specific and
x86-64-v4-specific optimizations.  To let binpkgs be compatible with both CPUs,
I must build them using compiler flag `-march=skylake`, but this would make the
binpkgs miss out on the Zen 4-specific optimizations.  Therefore, I let my
binhost build binpkgs only for the aforementioned packages with long build
times rather than an entire system's packages.  This way, on the machine with
the Zen 4 CPU, packages without binpkgs -- which are the majority -- would
still be built locally with `-march=native` for CPU-specific optimizations for
better performance; those a few packages with binpkgs would not be fully
optimized for the Zen 4 CPU, but there would not be too many of them.  To me,
this is an acceptable trade-off.

## Overview of the Approach

This article's approach utilizes a technical stack with these components:

- A container initialized from a stage 3 file, such as a `systemd-nspawn`
  container, a Docker container, or just a chroot environment.  In this
  container, Portage will be configured to build binpkgs.

  - The host system that runs this container does not need to run Gentoo; it
    theoretically can run any Linux distribution, though I have not tested any
    distribution other than Gentoo.

- A method to distribute the binpkgs built, like HTTP, SSH, or NFS.

- A way to automate building updated binpkgs for new ebuilds, such as cron
  scripts or a systemd timer unit.

In this article, I will walk through my particular solution, which uses the
following technical stack:
- A `systemd-nspawn` container
- nginx
- A systemd timer unit

You may definitely choose different components for your technical stack.  If
you do so, you will need to follow steps different from what this article
outlines, but this article's contents should still be a useful reference.

In addition, one special thing about my solution is that I run the container on
a Gentoo host system, so the container can directly share some files and
directories with the host system.  For example, the container can use the host
system's copy of the Gentoo ebuild repository (`/var/db/repos/gentoo`) and
distfiles (`/var/cache/distfiles`); also, the host system can directly access
and use the local binpkg files that the container has built, without going
through HTTP, SSH, etc. for an unnecessary detour.

Despite already having a Gentoo host system, which itself can build binpkgs, I
still chose to run a container and build binpkgs in it.  This is for isolation
of the binpkg build environment from the host system.  The host system is my
home server and runs services beyond a binhost, and I do not want an automated
system update (for automatically building updated binpkgs) to break those
services' operations.

## Create the Container

This section will mainly discuss creating a `systemd-nspawn` container.
Readers who are interested in other options are recommended to check out these
resources:

- Docker container: The [`gentoo/stage3`][docker-hub-gentoo-stage3] Docker
  image will be useful in setting up a Docker container.  The Docker
  container's bind mounts can be set up like the bind mounts for a
  `systemd-nspawn` container as this section will outline below.
- Chroot environment: The binary package guide on Gentoo Wiki has [a section
  for using a chroot environment][gentoo-wiki-binpkg-guide-chroot].

The following instructions are for setting up a `systemd-nspawn` container for
the binhost:

1. Create the container's settings file.  Assuming the container is to be
   called `binhost`, the settings file's path should be
   `/etc/systemd/nspawn/binhost.nspawn`.  The settings file should be
   configured to allow the container to access the Internet (to download
   distfiles) and add bind mounts that share files between the container and
   the host system.  For example:
   ```ini
   # /etc/systemd/nspawn/binhost.nspawn
   [Exec]
   Capability=CAP_NET_ADMIN
   ResolvConf=bind-stub

   [Files]
   Bind=/var/cache/binpkgs
   # The two `Bind=` lines below are only useful if the host system runs Gentoo
   Bind=/var/cache/distfiles
   Bind=/var/db/repos
   ```
   - `Capability=CAP_NET_ADMIN` grants the container the capability to access
     networks; the container needs this capability when it downloads distfiles.
   - `ResolvConf=bind-stub` is responsible for domain name resolution inside
     the container.  This is also needed for downloading distfiles from within
     the container.
   - `Bind=/var/cache/binpkgs` shares Portage's binpkg directory between the
     container and the host system at this path.  With this bind mount, the
     host system can distribute the binpkgs by serving the content of
     `/var/cache/binpkgs` through an HTTP server, exporting
     `/var/cache/binpkgs` through NFS, etc.  If the host system runs Gentoo,
     then the host system can be very easily configured to read the binpkgs
     that the container has built from this default binpkg path on the local
     filesystem.

   If the host system runs Gentoo, two additional bind mounts will be useful
   in eliminating file duplicates and reducing the amount of data downloaded
   from the Internet:
   - `Bind=/var/cache/distfiles` shares the distfiles directory (_DISTDIR_)
     between the container and the host system.
   - `Bind=/var/db/repos` shares ebuild repositories' files.

2. Create the container's directory.  Assuming the container is called
   `binhost`, its directory should be `/var/lib/machines/binhost`.
   ```console
   # mkdir --parents /var/lib/machines/binhost
   ```

3. [Download a stage 3 file][gentoo-downloads] that best matches the most
   common setup among the clients.  For example, if most clients are x86-64
   laptops and desktop computers that run a desktop environment and use systemd
   as the init system, and only one client is an x86-64 server that also uses
   systemd but does not run a desktop environment, then the amd64 "desktop
   profile | systemd" stage 3 (`stage3-amd64-desktop-systemd`) is the best
   stage 3.

4. Import the stage 3 file into the container's directory:
   ```console
   # tar -C /var/lib/machines/binhost -xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
   ```

5. Now, the `systemd-nspawn` container is ready to run.  Assuming it is called
   `binhost`,  it can be run using this command:
   ```console
   # systemd-nspawn --machine=binhost
   ```

[docker-hub-gentoo-stage3]: https://hub.docker.com/r/gentoo/stage3
[gentoo-wiki-binpkg-guide-chroot]: https://wiki.gentoo.org/wiki/Binary_package_guide#Chrooting
[gentoo-downloads]: https://www.gentoo.org/downloads/

## Configure Portage in the Container

The instructions in this section apply to all types of container
(`systemd-nspawn` container, Docker container, and chroot environment).

1. Start the container and launch a shell in it.  All subsequent steps in this
   section are to be performed inside the container, not directly on the host
   system.

2. In the container's `/etc/portage/make.conf`, specify the desired compiler
   flags.  Note that all compiler flags, especially machine-dependent C/C++
   compiler options (those that start with `-m`, particularly `-march`), must
   be compatible with both all clients *and the binhost itself*.  The binhost
   itself must also be considered because the build tools to run in the
   container on the binhost (compilers, interpreters, build systems, etc.) will
   also be compiled with these compiler flags, thus any compiler flags
   incompatible with the binhost machine itself may prevent the binhost machine
   from executing the build tools and, in turn, building binpkgs.  For more
   details, please consult the [relevant
   section][gentoo-wiki-binpkg-guide-flags] in the binary package guide on
   Gentoo Wiki.

3. If `CPU_FLAGS_*` USE flags customization is desired, in the container, set
   `CPU_FLAGS_*` USE flags to be the *intersection* of the sets of each
   client's supported flags as well as the binhost itself's supported flags.
   "Intersection" here has its [set theory
   meaning][wikipedia-intersection-set-theory]: a flag in the intersection must
   be found in every individual set.

   For example, suppose these machines are being considered:
   - A client that supports `CPU_FLAGS_X86` flags `aes avx f16c fma3`
   - Another client that supports flags `avx f16c mmx`
   - The binhost, which supports flags `aes avx f16c avx2`

   Then the intersection is `avx f16c`.

   On each machine, the supported `CPU_FLAGS_*` flags can be checked using
   `app-portage/cpuid2cpuflags`.  It can be installed with this command:
   ```console
   # emerge --ask app-portage/cpuid2cpuflags
   ```

   Then, run this command on each machine to check its supported flags:
   ```console
   $ cpuid2cpuflags
   ```

4. If `VIDEO_CARDS` USE flags customization is desired, in the container, set
   `VIDEO_CARDS` USE flags to be the *union* of the sets of all clients'
   `VIDEO_CARDS` values.  If, on the binhost, the host system does not run
   Gentoo with a desktop environment, then the binhost itself's `VIDEO_CARDS`
   values may be omitted.  "Union" here has its [set theory
   meaning][wikipedia-union-set-theory]: it is the combination of all values
   from all sets.

   For example, suppose these machines are being considered:
   - A client that needs `VIDEO_CARDS` flags `amdgpu radeonsi`
   - Another client that needs flags `radeon radeonsi`

   Then the union is `amdgpu radeon radeonsi`.

5. If most clients use the same *profile* (as in `eselect profile`), it is a
   good idea to select that profile in the container too.  For example, all my
   clients are laptops and desktop computers that run GNOME and systemd, so I
   would choose the `default/linux/amd64/23.0/desktop/gnome/systemd` profile in
   the container.  [Instructions to list profiles and select a
   profile][gentoo-handbook-profile] are available in the Gentoo Handbook.

6. In the container's Portage configuration files, select the packages for
   which binpkgs should be built.  As mentioned previously, binpkgs can be
   built for either the entire system or just select packages; this is done at
   this step by enabling `FEATURES="buildpkg"` for either all packages or only
   the select packages.

   - If binpkgs should be built for all packages, then in the container's
     `/etc/portage/make.conf`, set the following option:

     ```bash
     FEATURES="buildpkg"
     ```

     In this case, it is still possible to exclude certain packages from binpkg
     building; to do so, continue to follow the instructions in the list item
     below.

   - If it is desirable to enable or disable binpkg building for only certain
     packages:

     1. In the container, create directory `/etc/portage/env`:
        ```console
        # mkdir --parents /etc/portage/env
        ```

     2. In this directory, create two files for later use: one for enabling
        binpkg builds on an individual package basis, and one for explicitly
        disabling binpkg builds.  The files' names do not matter as long as
        they are not the same as either each other or any other existing files
        under `/etc/portage/env` in the container.  For example, the files can
        be called `buildpkg-yes.conf` and `buildpkg-no.conf`:
        ```console
        # echo 'FEATURES="buildpkg"' > /etc/portage/env/buildpkg-yes.conf
        # echo 'FEATURES="-buildpkg"' > /etc/portage/env/buildpkg-no.conf
        ```

     3. In the container, create directory `/etc/portage/package.env`.
        (Although Portage allows `/etc/portage/package.env` to be a file, some
        packages, such as `sys-devel/crossdev`, require it to be a
        directory[^portage-package-env-dir-requirement].)
        ```console
        # mkdir --parents /etc/portage/package.env
        ```

     4. In a file in the container's `/etc/portage/package.env` (such as
        `/etc/portage/package.env/buildpkg`), enable binpkg building for a
        package by listing the package name and adding `buildpkg-yes.conf`
        after it, and disable binpkg building for a package by adding
        `buildpkg-no.conf` after its name.

        Patterns are supported too for bulk enabling or disabling binpkg
        building.

        For example:

        ```bash
        # /etc/portage/package.env/buildpkg

        # Build binpkgs for these packages
        app-office/libreoffice buildpkg-yes.conf
        llvm-core/llvm buildpkg-yes.conf
        sys-devel/gcc buildpkg-yes.conf
        sys-kernel/vanilla-kernel buildpkg-yes.conf

        # Exclude packages matching these patterns from binpkg building
        */*-bin buildpkg-no.conf
        acct-*/* buildpkg-no.conf
        app-alternatives/* buildpkg-no.conf
        virtual/* buildpkg-no.conf
        ```

        This way to disable binpkg builds for select packages still works even
        if `FEATURES="buildpkg"` has been globally enabled for all packages
        from `/etc/portage/make.conf`.
        {.notice--success}

7. In the container, ensure the packages for which binpkgs should be created
   are also selected in @world.  Just setting `FEATURES="buildpkg"` is not
   enough because it only means "if a package is being merged, then build a
   binpkg for it," but if the condition in this sentence is not satisfied, then
   the outcome will not occur.  For example, regardless of whether
   `FEATURES="buildpkg"` has been enabled for all packages or only
   `app-office/libreoffice`, if `app-office/libreoffice` is not in @world, then
   Portage will never merge it in the normal course of operation, so Portage
   will never build a binpkg for `app-office/libreoffice`.

   The most common way to select a package in @world is to let Portage add it
   to the world file (`/var/lib/portage/world`).  For example, the following
   command adds `app-office/libreoffice` to the world file:
   ```console
   # emerge --ask --noreplace app-office/libreoffice
   ```

   An alternative, recommended method is to create a [user-defined package
   set][gentoo-wiki-etc-portage-sets], add those packages to the set, and
   install that set, so all the packages in the set will be selected in @world:

   1. In the container, create the `/etc/portage/sets` directory:
      ```console
      # mkdir --parents /etc/portage/sets
      ```

   2. Under the container's `/etc/portage/sets` directory, create a file to
      define the package set; the filename will be the package set's name.  For
      example, file `/etc/portage/sets/buildpkg` defines set @buildpkg.

   3. In this file, specify packages to be included in the set.  For example:
      ```bash
      # /etc/portage/sets/buildpkg
      app-office/libreoffice
      sys-kernel/vanilla-kernel
      ```

8. Trigger an initial binpkg build by rebuilding @world in the container, with
   the new compiler flags and USE flags customized just now applied.  If a
   package set was defined in the previous step, ensure that set is also going
   to be built.  For example, if the package set is called @buildpkg:
   ```console
   # emerge --ask --emptytree @world @buildpkg
   ```

   If a package set is not being used, then just rebuild @world:
   ```console
   # emerge --ask --emptytree @world
   ```

[gentoo-wiki-binpkg-guide-flags]: https://wiki.gentoo.org/wiki/Binary_package_guide#Handling_.2AFLAGS_in_detail
[wikipedia-intersection-set-theory]: https://en.wikipedia.org/wiki/Intersection_(set_theory)
[wikipedia-union-set-theory]: https://en.wikipedia.org/wiki/Union_(set_theory)
[gentoo-handbook-profile]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Choosing_the_right_profile
[gentoo-wiki-etc-portage-sets]: https://wiki.gentoo.org/wiki//etc/portage/sets

[^portage-package-env-dir-requirement]: https://wiki.gentoo.org/wiki//etc/portage/package.env#.2Fetc.2Fportage.2Fpackage.env_must_be_a_directory_for_some_packages_to_work

## Set Up Binpkg Distribution

The binpkgs built can be distributed through several different networking
protocols, including but not limited to FTP, HTTP/HTTPS, NFS, and SSH.  The
binary package guide on Gentoo Wiki has [a section that covers many of these
methods][gentoo-wiki-binpkg-guide-dist].

This section will introduce a method that the binary package guide does not
cover: an nginx HTTP server.

1. On the host system (not the container), install nginx.

2. Set up nginx in its configuration file (typically `/etc/nginx/nginx.conf`)
   to serve the binpkgs at a URI.  For example, the following configuration is
   the most basic HTTP (port 80, not HTTPS) configuration that serves binpkgs
   stored under `/var/cache/binpkgs` on the host system at URI
   `/gentoo-binpkgs/amd64`.

   ```
   http {
       server {
           listen 0.0.0.0;
           listen [::];

           location /gentoo-binpkgs/amd64 {
               alias /var/cache/binpkgs;
               autoindex on;
           }
       }
   }
   ```

   Many users might prefer an HTTPS server instead of an HTTP one.  An HTTPS
   server is definitely possible, though it requires a domain name and a TLS
   certificate, which are out of this article's scope.

   The `autoindex on;` setting is optional; when it is set, it allows users to
   access the binhost from a web browser and see from there which binpkgs are
   available.

   ![Viewing binpkgs available on a binhost in a web browser]({{< static-path
   img binhost-web.png >}})

[gentoo-wiki-binpkg-guide-dist]: https://wiki.gentoo.org/wiki/Binary_package_guide#Setting_up_a_binary_package_host

## Automate Builds of Updated Binpkgs

The binhost's system administrator can configure it to automatically
synchronize the Gentoo ebuild repository, update the Gentoo system in the
container, and build updated binpkgs.  This section will introduce how this can
be done through a systemd timer unit.  The host system is assumed to use
systemd as the init system; if not, cron scripts can be created instead of a
systemd timer unit.

1. On the host system, create a systemd service that updates the system in the
   container.  For example, create a file with the following content at path
   `/etc/systemd/system/binhost-update.service` for a new systemd service
   `binhost-update.service`:

   ```ini
   # /etc/systemd/system/binhost-update.service
   [Unit]
   Description=Update the system in the binhost container

   [Service]
   Type=oneshot
   ExecStart=systemd-nspawn --machine=binhost bash -c 'emerge --update --deep --newuse --keep-going --quiet-build --verbose @world && emerge --depclean'
   ```

   The `ExecStart=` option assumes that a `systemd-nspawn` container called
   `binhost` is being used.  If this is not the case, replace the command for
   `ExecStart=` with the appropriate command that launches the container.
   {.notice--info}

   Here is an explanation of the `ExecStart=` command in this service unit
   file:

   - It runs two commands in the container: one that updates the system, and
     then one that cleans up obsolete packages (`emerge --depclean`).  If the
     system update failed, it will not proceed to the clean-up, so the system
     administrator can launch the container, inspect and fix the issue, and try
     again.  Therefore, it connects the two commands with the `&&` operator and
     passes them together to the container through `bash -c`.

   - The system update command uses `emerge` option `--keep-going`, so a single
     package's build failure will not prevent most other packages from being
     automatically updated.

   - The system update command uses `emerge` options `--quiet-build --verbose`
     to leave the information that is most relevant to troubleshooting in the
     systemd journal for automatic system updates.  `--quiet-build` hides
     packages' build output unless a build error occurred, and `--verbose`
     makes more information available in the merge list displayed before
     packages are merged.

     {{<div class="notice--success">}}
To view the systemd journal for automatic system updates, run this command
on the host system:

```console
$ journalctl --all --unit binhost-update.service
```
     {{</div>}}

2. On the host system, create another systemd service that synchronizes the
   ebuild repositories in the container.  For example, create a file with the
   following content at path `/etc/systemd/system/binhost-emerge-sync.service`:

   ```ini
   # /etc/systemd/system/binhost-emerge-sync.service
   [Unit]
   Description=Update ebuild repositories in the binhost container
   After=network-online.target
   Wants=binhost-update.service
   Before=binhost-update.service

   [Service]
   Type=oneshot
   ExecStart=systemd-nspawn --machine=binhost emerge --sync
   ```

   The `Wants=` and `Before=` options let `binhost-update.service` perform a
   system update in the container after each time this service synchronizes the
   ebuild repositories.

3. On the host system, create a systemd timer unit for the service that
   synchronizes the ebuild repositories in the container.  By default, if the
   service is called `binhost-emerge-sync.service`, then systemd expects its
   corresponding timer unit to be called `binhost-emerge-sync.timer`.

   ```ini
   # /etc/systemd/system/binhost-emerge-sync.timer
   [Unit]
   Description=Periodically update ebuild repositories in the binhost container
   After=network-online.target

   [Timer]
   OnCalendar=Sat *-*-* 00:00:00
   Persistent=true

   [Install]
   WantedBy=timers.target
   ```

   The system administrator can freely customize the `[Timer]` section of this
   unit to trigger repository synchronization and container system update at
   different times or based on other rules.  See the
   [`systemd.timer(5)`][man-systemd.timer-options] manual page for more
   details.

4. On the host system, enable and start the timer unit.  This just starts the
   timer unit, but the timer will trigger the service that synchronizes ebuild
   repositories, which in turn will trigger the service that updates the
   system in the container after synchronization is finished.
   ```console
   # systemctl enable --now binhost-emerge-sync.timer
   ```

[man-systemd.timer-options]: https://man.archlinux.org/man/core/systemd/systemd.timer.5.en#OPTIONS

## Use the Binpkgs on Clients and a Gentoo Host System

Now that the binhost has been set up to build and distribute binpkgs, the
clients can now be configured to fetch binpkgs from it.  If the host system
itself runs Gentoo, then the host system can now also be set up to use local
binpkgs built by the container.

The instructions to configure a client to use the binhost differ depending on
how the binpkgs are distributed.  All binpkg distribution methods can be
categorized into two paradigms:

- Clients **mount** a filesystem that contains *all* binpkgs that the binhost
  has built to `/var/cache/binpkgs`.  All binpkgs will be available under a
  client's `/var/cache/binpkgs` directory **before** `emerge` is run.  NFS
  shares, SSHFS, and so on fall under this paradigm.
  - A Gentoo host system using local binpkgs built by the container should also
    be considered to be under this paradigm.

- Clients **download** binpkgs to `/var/cache/binpkgs` **while** `emerge` is
  running.  Binpkgs to be installed might *not* exist under a client's
  `/var/cache/binpkgs` directory before `emerge` is run.  HTTP, HTTPS, plain
  SSH (using an `ssh://` URI, without SSHFS and so on), etc. fall under this
  paradigm.

### Clients Mount a Filesystem, or on a Gentoo Host System Itself

Note: If a Gentoo host system is being configured to use local binpkgs built by
the container, then the Gentoo host system should be considered a client in
this section's instructions.

1. On each client, ensure the filesystem that contains the binpkgs built is
   mounted before `emerge` is run.  The specific procedure varies depending on
   the networking protocol used (e.g. NFS vs. SSHFS vs. others), but it usually
   involves editing the client's `/etc/fstab`.  See [the section for
   NFS][gentoo-wiki-binpkg-guide-nfs] in the binary package guide on Gentoo
   Wiki for an example.

2. If the client's user would like to use binpkgs only when they explicitly
   specify so in the command-line options for `emerge`, then they should run
   `emerge` with option `--usepkg` when they would like to use binpkgs.

   If the client's user would like to always use binpkgs when they are
   available, then add the following line to the client's
   `/etc/portage/make.conf`:
   ```bash
   EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --usepkg"
   ```

   In both cases, the user can still temporarily let `emerge` not use any
   binpkg by running `emerge` with command-line option `--usepkg=n`.

[gentoo-wiki-binpkg-guide-nfs]: https://wiki.gentoo.org/wiki/Binary_package_guide#NFS_exported

### Clients Download Binpkgs

1. On each client, ensure directory `/etc/portage/binrepos.conf` exists:
   ```console
   # mkdir --parents /etc/portage/binrepos.conf
   ```

2. Create a new file under the client's `/etc/portage/binrepos.conf` for the
   binhost, such as `/etc/portage/binrepos.conf/custom-binhost.conf`.  In this
   file, specify the binhost's URI, which typically starts with `http://`,
   `https://`, `ssh://`, and so on.
   ```ini
   # /etc/portage/binrepos.conf/custom-binhost.conf
   [custom-binhost]
   sync-uri = https://example.com/gentoo-binhost/amd64
   priority = 10
   ```

   More details and examples are available in the [relevant
   section][gentoo-wiki-binpkg-guide-binrepos.conf] in the binary package guide
   on Gentoo Wiki.

3. If the client's user would like to use binpkgs only when they explicitly
   specify so in the command-line options for `emerge`, then they should run
   `emerge` with option `--getbinpkg` when they would like to use binpkgs.

   If the client's user would like to always use binpkgs when they are
   available, then there are two different ways to configure Portage to do so:

   - Add the following line to the client's `/etc/portage/make.conf`:
     ```bash
     FEATURES="getbinpkg"
     ```

     With this setting, if the user wants to temporarily let `emerge` not use
     any binpkg, they should run `emerge` with `FEATURES="-getbinpkg"` set in
     the environment, such as:
     ```console
     # FEATURES="-getbinpkg" emerge --ask app-office/libreoffice
     ```

   - Add the following line to the client's `/etc/portage/make.conf`:
     ```bash
     EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --getbinpkg"
     ```

     With this setting, the user can temporarily let `emerge` not use any
     binpkg by running `emerge` with command-line option `--getbinpkg=n`.

[gentoo-wiki-binpkg-guide-binrepos.conf]: https://wiki.gentoo.org/wiki/Binary_package_guide#Pulling_packages_from_a_binary_package_host

## Bonus: Provide an rsync Mirror

Because the binhost must have at least one copy of the Gentoo ebuild repository
used by the container, and it is already serving binpkgs, it can also serve an
rsync mirror of the Gentoo ebuild repository, so clients can use the binhost
server for both binpkgs and repository synchronization.

This is particularly useful to system administrators who manage multiple Gentoo
systems.  If a system administrator has multiple clients and a binhost in the
same local area network (LAN), then serving a local rsync mirror from the
binhost provides these benefits:
- When a client runs `emerge --sync`, it generally synchronizes faster from a
  local rsync mirror than from the default `rsync.gentoo.org` servers.
- "Common Gentoo netiquette" says that each user "should not sync more than
  once a day", and users who abuse the `rsync.gentoo.org` servers may be
  blocked from accessing them[^gentoo-rsync-mirrors].  If the system
  administrator decides to update all the clients on the same day, and every
  client is configured to use `rsync.gentoo.org`, then the LAN may be blocked
  by the servers this way because it would appear that too many
  synchronizations from the same network have been started in a short period of
  time.  By using a local rsync mirror, only one synchronization with
  `rsync.gentoo.org` from the entire LAN is needed each time.

Using a Git repository instead of rsync can also achieve the same effect, but
this requires `dev-vcs/git` on clients.  rsync is supposed to be installed on
every Gentoo system, but Git is not.  Therefore, a local rsync mirror is still
suitable when a client does not have Git installed for any reason.

To set up an rsync mirror on the binhost:

1. On the host system, install rsync.

2. Assuming that the host system itself has a copy of the Gentoo ebuild
   repository at `/var/db/repos/gentoo` (e.g. due to a bind mount of the
   container, or due to the host system already running Gentoo), add these
   lines to file `/etc/rsyncd.conf` on the host system:
   ```ini
   [gentoo-portage]
       path = /var/db/repos/gentoo
       comment = Gentoo ebuild repository
       exclude = /distfiles /packages /lost+found
   ```

   If the host system already runs Gentoo, then these lines are already in
   `/etc/rsyncd.conf` -- just commented out.  In this case, simply uncomment
   these lines.
   {.notice--success}

3. On the host system, enable and start the rsync daemon.  Follow [these
   instructions][gentoo-wiki-rsync-service] on Gentoo Wiki, which are
   applicable to many other Linux distributions too and cover both systems
   running OpenRC and those running systemd.

4. On each client, perform these steps:

   1. Ensure directory `/etc/portage/repos.conf` exists:
      ```console
      # mkdir --parents /etc/portage/repos.conf
      ```

   2. If directory `/etc/portage/repos.conf` does not contain a configuration
      file for the Gentoo ebuild repository, create the file:
      ```console
      # cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf
      ```

   3. Open the configuration file for the Gentoo ebuild repository under
      `/etc/portage/repos.conf`, and find the following line:
      ```ini
      sync-uri = rsync://rsync.gentoo.org/gentoo-portage
      ```

      Change the host part of the `sync-uri` to the hostname or the IP address
      of the binhost, such as:
      ```ini
      #sync-uri = rsync://rsync.gentoo.org/gentoo-portage
      sync-uri = rsync://example.com/gentoo-portage
      ```

[gentoo-wiki-rsync-service]: https://wiki.gentoo.org/wiki/Rsync#Service

[^gentoo-rsync-mirrors]: https://www.gentoo.org/support/rsync-mirrors/

## More Resources

- The [binary package guide][gentoo-wiki-binpkg-guide] on Gentoo Wiki consists
  of instructions to complete various binhost setup and maintenance tasks, many
  of which this article does not cover.

- [hartwork/binary-gentoo][github-hartwork-binary-gentoo] on GitHub consists of
  a set of tools for setting up a binhost in an alternative way.  Regardless of
  whether this tool is used, its README has [great
  instructions][github-hartwork-binary-gentoo-readme-flags] to determine
  suitable compiler flags and `CPU_FLAGS_*` USE flags that are compatible with
  both the binhost itself and the clients.

[gentoo-wiki-binpkg-guide]: https://wiki.gentoo.org/wiki/Binary_package_guide
[github-hartwork-binary-gentoo]: https://github.com/hartwork/binary-gentoo
[github-hartwork-binary-gentoo-readme-flags]: https://github.com/hartwork/binary-gentoo?tab=readme-ov-file#determining-ideal-build-flags
