---
title: "Enable Wi-Fi by Default on OpenWrt"
tags:
  - OpenWrt
categories:
  - Tutorial
toc: true
---

On routers with an Ethernet port, OpenWrt has Wi-Fi disabled on the first boot
"for security reasons."[^owrt-quick-start-basic_wifi]  To enable Wi-Fi, users
need to first connect a device to the router via Ethernet, so they can access
the router in a wired manner and change its configuration to set up Wi-Fi.

[^owrt-quick-start-basic_wifi]: <https://openwrt.org/docs/guide-quick-start/basic_wifi>

This is more inconvenient than most routers' stock firmware.  These routers
come with a unique default SSID and password printed on a sticker affixed to
the router, and for the initial setup, users can connect to the router
*wirelessly* using these credentials; Ethernet is not required.  OpenWrt,
however, cannot easily make use of default Wi-Fi credentials.  Constant initial
Wi-Fi password in the default configuration (which would be common for every
OpenWrt device on the first boot) is certainly a security risk; randomized
passwords are more secure, but there is no means to inform users of the random
password before the users have connected to the router, unlike what router
manufacturers can do with the sticker.  Therefore, disabling Wi-Fi by default
on OpenWrt does improve security.

On routers where OpenWrt uses U-Boot as the bootloader, it is possible to
enable Wi-Fi by default on the first boot on OpenWrt and set a user-configured
default SSID and password.  The default SSID and password settings will persist
through configuration resets and system upgrades.

Enabling Wi-Fi on the first boot is suitable for users who need to reset
OpenWrt configuration sometimes and put their router at a place not very
physically reachable or do not always have a device with an Ethernet port at
hand.  It is also very useful for those who want to sell or give others a
router with OpenWrt already installed.  There will be no need to tell the new
owner to connect to the router via Ethernet and change OpenWrt configuration to
enable Wi-Fi; instead, the current owner can set the credentials printed on the
router's sticker as OpenWrt's default Wi-Fi credentials and just tell the new
owner to use them.

## Check If Router Uses U-Boot

One crude way to conveniently check if a router running OpenWrt uses U-Boot as
the bootloader is see if the OpenWrt system on the router has file
`/etc/fw_env.config`, a configuration file storing locations of [U-Boot's
environment][openwrt-uboot.config].

1. [Connect to the router via SSH][openwrt-sshadministration].

2. Check if file `/etc/fw_env.config` exists on the router:
   ```console
   # cat /etc/fw_env.config
   ```

   - If this command prints `cat: can't open '/etc/fw_env.config': No such file
     or directory`, then the router does **not** use U-Boot.  Users who see
     this output can still try an [alternative method] mentioned below; they
     should **not** follow the next section's instructions.

   - Otherwise, the router uses U-Boot, and users can follow the next section's
     instructions.

[openwrt-uboot.config]: https://openwrt.org/docs/techref/bootloader/uboot.config
[openwrt-sshadministration]: https://openwrt.org/docs/guide-quick-start/sshadministration
[alternative method]: #alternative-methods

## Enable Wi-Fi by Default

1. In the following command, replace these placeholders with their desired
   value, then run the command:
   - `${SSID}`: The default SSID.
   - `${PASSWORD}`: The default key.
   - `${COUNTRY}`: The default [Wi-Fi country code].  This is a two-letter [ISO
     3166-1 alpha-2] code that represents the country where the router is
     expected to operate; special code `00` is also supported for the world
     regulatory domain.  The country code must be set to let OpenWrt enable the
     router's Wi-Fi devices.

   ```console
   # fw_setenv --script /dev/stdin << EOF
   owrt_ssid ${SSID}
   owrt_wifi_key ${PASSWORD}
   owrt_country ${COUNTRY}
   EOF
   ```

   This command sets these values in the U-Boot environment.  Upon the first
   boot, OpenWrt will read the U-Boot environment and use these values to
   initialize the Wi-Fi network.

   Note that this command does not modify the Wi-Fi settings in the current
   OpenWrt configuration.  It will only affect subsequent configuration resets.

2. If the `cat /etc/fw_env.config` command run previously printed two lines,
   then the router has two redundant copies of the U-Boot
   environment[^u-boot-fw_env], and because each `fw_setenv` command updates
   only one copy, users may optionally choose to run the same `fw_setenv`
   command again to set the values in the other copy as well.  This is not
   necessary: U-Boot always tries to use the most recently updated redundant
   copy, so changing one copy is enough.  However, setting the values in both
   copies helps ensure that, when one copy is corrupt, Wi-Fi is still enabled
   by default on the first boot.

   If the `cat /etc/fw_env.config` command printed just one line, then the
   router has only one copy of the U-Boot environment, so there is absolutely
   no need to run the `fw_setenv` command again because there is no other
   redundant copy of the environment to update.

3. Verify that the values have been successfully set in the U-Boot environment.
   The following command should print the same values set by the previous
   `fw_setenv` command.

   ```console
   # fw_printenv owrt_ssid owrt_wifi_key owrt_country
   owrt_ssid=<SSID>
   owrt_wifi_key=<password>
   owrt_country=<country code>
   ```

[Wi-Fi country code]: https://openwrt.org/docs/guide-user/network/wifi/wifi_countrycode
[ISO 3166-1 alpha-2]: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements
[^u-boot-fw_env]: <https://github.com/u-boot/u-boot/blob/v2026.07/tools/env/fw_env.c#L1874>

## How This Works

Since version 24.10.0, OpenWrt installs [a script][openwrt-git-fw_defaults]
that, on the first boot, reads `owrt_ssid`, `owrt_wifi_key`, `owrt_country`,
and a few other `owrt_*` variables from the U-Boot environment.  The script
adds any found values for these variables to file `/etc/board.json`, which is a
file created on the first boot to store hardware information specific to the
router's model, like lists of Ethernet ports, Wi-Fi devices, and LEDs.  OpenWrt
uses this information to initialize its configuration.  For example, [one of
OpenWrt's Wi-Fi scripts][openwrt-git-mac80211.uc] reads `/etc/board.json`, and
if it finds default Wi-Fi credentials in the JSON file, it sets the credentials
in the OpenWrt configuration accordingly and ensures Wi-Fi is enabled on the
first boot.

Because the U-Boot environment is not erased on a configuration reset or a
system upgrade, the default Wi-Fi credentials set in the U-Boot environment
survive these events.

[openwrt-git-fw_defaults]: https://github.com/openwrt/openwrt/blob/v25.12.5/package/boot/uboot-tools/uboot-envtools/files/fw_defaults
[openwrt-git-mac80211.uc]: https://github.com/openwrt/openwrt/blob/v25.12.5/package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc#L88

## Revert the Change

The following command lets OpenWrt keep Wi-Fi disabled on the first boot.  Not
including a value after a variable name lets `fw_setenv` delete the variable
from the U-Boot environment.

```console
# fw_setenv --script /dev/stdin << EOF
owrt_ssid
owrt_wifi_key
owrt_country
EOF
```

This command does not erase any Wi-Fi settings in the current OpenWrt
configuration.  It will only affect subsequent configuration resets.

## Limitation

On multi-band routers, the U-Boot environment cannot be used to set different
Wi-Fi credentials for different bands; instead, all bands must share the same
default credentials.  To use different credentials for different bands, use an
alternative method introduced below.

## Alternative Methods

OpenWrt documentation introduces [another
method][openwrt-wifi_enabled_on_first_boot] to enable Wi-Fi by default on the
first boot.  This method requires using the [Image Builder] to build a custom
OpenWrt image.  Users create a script that sets the default Wi-Fi credentials
and include the script in their custom image under [the `/etc/uci-defaults`
directory][openwrt-uci-defaults].  On the first boot, OpenWrt runs all scripts
under this directory once.

This method works; in fact, the author used this method before discovering the
U-Boot environment method.  However, this method has a few drawbacks.  Each
time OpenWrt has a new release, to not lose default Wi-Fi enablement on the
first boot, the Image Builder must be used again to build an image for the new
release with the same script included.  One ramification is that the router's
user cannot use [attended sysupgrade] because it does not support including
custom `/etc/uci-defaults` scripts in the image built.  Also, for users who own
several routers of the same model, if they want to use different default Wi-Fi
credentials on them, then they need to build a separate image for each router
and, in each image, include a unique version of the script that uses a unique
set of credentials.  They cannot use a unified image on these routers even
though they are the same model.

For a multi-band router, to set Wi-Fi credentials for all the bands, in the
script, repeat the `uci set` lines for each band as demonstrated in the
following example.  Different credentials can be set for different bands.
```console {hl_lines=["7-11"]}
# cat << "EOF" > /etc/uci-defaults/xxx_config
uci set wireless.@wifi-device[0].disabled="0"
uci set wireless.@wifi-iface[0].disabled="0"
uci set wireless.@wifi-iface[0].ssid="OpenWrt"
uci set wireless.@wifi-iface[0].key="changemeplox"
uci set wireless.@wifi-iface[0].encryption="psk2"
uci set wireless.@wifi-device[1].disabled="0"
uci set wireless.@wifi-iface[1].disabled="0"
uci set wireless.@wifi-iface[1].ssid="OpenWrt-5G"
uci set wireless.@wifi-iface[1].key="changemeplox"
uci set wireless.@wifi-iface[1].encryption="psk2"
uci commit wireless
EOF
```

[openwrt-wifi_enabled_on_first_boot]: https://openwrt.org/docs/guide-user/installation/flashing_openwrt_with_wifi_enabled_on_first_boot
[Image Builder]: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
[openwrt-uci-defaults]: https://openwrt.org/docs/guide-developer/uci-defaults#integrating_custom_settings
[attended sysupgrade]: https://openwrt.org/docs/guide-user/installation/attended.sysupgrade
