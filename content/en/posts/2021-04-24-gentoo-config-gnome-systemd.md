---
title: "Gentoo Configuration Guide: GNOME on systemd"
tags:
  - Gentoo
  - GNU/Linux
categories:
  - Tutorial
toc: true
---

Getting a perfect GNOME configuration on Gentoo is not hard but is tricky.  In
other words, it would be a piece of cake once you have done it, but it is not
easy to get it right with only one shot for the first time.  The [GNOME Guide
on Gentoo Wiki][gentoo-gnome-guide] is a good resource and is enough for a
barely functional GNOME installation, but there are plenty of rooms for
improvements, like removing the authentication dialog when modifying network
settings, and enabling Wayland screen sharing in web browsers like Google
Chrome.

In this article, I will list the important steps for getting GNOME to run
smoothly on Gentoo.  Some fundamental steps are already covered by the Gentoo
GNOME Guide; others are enhancements not covered by that guide but improve the
overall user experience.

This article assumes a Gentoo system that uses systemd, instead of OpenRC.

[gentoo-gnome-guide]: https://wiki.gentoo.org/wiki/GNOME/Guide

## Select Profile and Install GNOME Packages

The Gentoo Handbook instructs users to [select a profile][handbook-profile]
during system installation, and users might have promptly selected the GNOME
systemd profile for a system with GNOME and systemd.  Please note that enabling
this profile alone will not cause GNOME to be installed.  The only purpose of
the profile is to set up USE flags and other Portage options that are necessary
for GNOME to run.  This means after enabling the GNOME profile, users need to
manually install the GNOME meta-package with `emerge`.

```console
# emerge --ask gnome-base/gnome
```

[handbook-profile]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Choosing_the_right_profile

## Enable systemd Unit for GNOME Display Manager

To start GNOME automatically upon system boot, the systemd unit for GNOME
Display Manager (GDM) needs to be enabled manually.  Otherwise, the text-based
login console will still be presented after system boot.

```console
# systemctl enable gdm.service
```

If `gdm.service` has already been enabled, but after rebooting the system, the
GNOME login screen is still not shown, then please try explicitly setting
systemd's default target to `graphical.target`:

```console
# systemctl set-default graphical.target
```

## Enable Additional systemd Units for GNOME Settings

There are some systemd units that need to be enabled if the user wants to
adjust computer settings via the GNOME Settings app (a.k.a.
`gnome-control-center`).

- To manage network connections from GNOME Settings, enable
  `NetworkManager.service`.  This enables NetworkManager, which is capable of
  managing the system's network connections.  If `systemd-networkd` is also
  enabled, it is a good idea to disable `systemd-networkd.service` to avoid any
  conflict between these two services.
- To access Bluetooth settings, enable `bluetooth.service`.
- To enable printing settings, enable `cups.service`.

```console
# systemctl enable NetworkManager.service
# systemctl disable systemd-networkd.service
# systemctl enable bluetooth.service
# systemctl enable cups.service
```

## Allow Modification of Network Settings Without Authentication

By default, superuser privileges are required to modify network settings from
GNOME Settings, so users might be asked to authenticate when they connect to a
new Wi-Fi network or change network settings, as shown below:

![Authentication dialog shown when network settings are being
changed]({{< static-path img polkit-nm.png >}})

To allow every user account to modify network settings, create a `*.rules` file
under `/etc/polkit-1/rules.d`, and add a rule which permits so to the file:

```js
/* /etc/polkit-1/rules.d/10-networkmanager.rules */

// Allow any user to manage network connections via NetworkManager
polkit.addRule(function (action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.local) {
        return polkit.Result.YES;
    }
});
```

Then, restart systemd unit `polkit.service` to apply the new rule:

```console
# systemctl restart polkit.service
```

## Allow Users in `wheel` Group to Use Their Own Credentials for Authentication in GNOME

[The `wheel` user group][wheel-group] is often used as the group for system
administrators on a Unix system.  As a common idiom, utilities like `sudo` are
configured to let users in the `wheel` group execute commands with superuser
privileges and authenticate with *their own* password instead of the `root`
account's password.

When GNOME needs to execute a task with superuser privileges, like mounting a
partition of an internal hard disk, it can ask for authentication in a GUI
dialog.  However, without proper configuration, it requires credentials for the
`root` account, which is unlike `sudo`.

![Authentication dialog asking for the root account's
credentials]({{< static-path img polkit-root.png >}})

To mimic `sudo`'s behavior of asking for the user's own password, create a
`*.rules` file under `/etc/polkit-1/rules.d`, and add the following rule:

```js
/* /etc/polkit-1/rules.d/49-wheel.rules */

// Allow users in the 'wheel' group to use their own password instead of the
// root password in authentication pop-ups of GNOME
polkit.addAdminRule(function (action, subject) {
    return ["unix-group:wheel"];
});
```

After restarting the systemd unit `polkit.service`, the user's own credentials
will be requested for authentication instead, provided the user is in the
`wheel` group:

![Authentication dialog asking for the user's
credentials]({{< static-path img polkit-wheel.png >}})

[wheel-group]: https://en.wikipedia.org/wiki/Wheel_(computing)

## Enable WebRTC Screen Sharing Based on PipeWire in Web Browsers

Enabling WebRTC-based screen sharing from web browsers on Wayland -- which is
the default display server protocol used by GNOME -- is a tricky thing many
users have asked about.  The solution to this problem is fairly simple, which
is to ensure `xdg-desktop-portal-gtk` is installed.

On Gentoo, `sys-apps/xdg-desktop-portal-gtk` is guaranteed to be installed with
`gnome-base/gnome-shell` because the latter package indirectly depends on the
former package.  However, WebRTC screen sharing requires additional
configurations to be functional:

- The `screencast` USE flag needs to be enabled at the global level, so
  packages can be compiled with PipeWire's screencast portal support.

- The systemd socket for PipeWire -- `pipewire.socket` -- needs to be manually
  enabled because it is disabled by default.

The detailed steps are:

1. Enable the `screencast` USE flag at the global level.  The Gentoo Handbook
   covers [one way of doing this][handbook-use] via modifying
   `/etc/portage/make.conf`; alternatively, users can add the USE flag into
   `/etc/portage/package.use` as follows:

   ```sh
   # /etc/portage/package.use

   # Enable screencast portal using PipeWire
   */* screencast
   ```

2. Rebuild existing packages with the new USE flag settings:

   ```console
   # emerge --ask --newuse --deep @world
   ```

3. Enable PipeWire's systemd socket:

   ```console
   # systemctl --global enable pipewire.socket
   ```

4. Reboot the system.

According to [ArchWiki][archwiki-webrtc], FireFox has WebRTC PipeWire support
enabled by default, whereas on Chromium/Google Chrome, the following
experimental flag for this feature needs to be enabled:

```
chrome://flags/#enable-webrtc-pipewire-capturer
```

To test whether screen sharing has been correctly configured, the *screen
capture* test in [this test page][screen-capture-test] can be used.  After
selecting what to share from the dialog, the screen sharing content should be
visible on the page, and an orange screen share icon should be in the top bar.

![Screen is being shared from Google Chrome]({{< static-path img screen-share.png >}})

### Limitations

- Screen shares from Google Chrome do not have sound.

[handbook-use]: https://wiki.gentoo.org/wiki/Handbook:AMD64/Working/USE#Declare_permanent_USE_flags
[archwiki-webrtc]: https://wiki.archlinux.org/index.php/PipeWire#WebRTC_screen_sharing
[screen-capture-test]: https://mozilla.github.io/webrtc-landing/gum_test.html
