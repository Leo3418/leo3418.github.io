---
title: "在 OpenWrt 上默认启用 Wi-Fi"
tags:
  - OpenWrt
categories:
  - 教程
toc: true
---

OpenWrt 在配备有线网口的路由器上默认是禁用 Wi-Fi 的；官方文档对此的解释是“出于安全原因”[^owrt-quick-start-basic_wifi]。要启用 Wi-Fi 的话，用户就需要暂时先使用有线网连接路由器，从而能够进入路由器后台调整 Wi-Fi 设置。

[^owrt-quick-start-basic_wifi]: <https://openwrt.org/zh/docs/guide-quick-start/basic_wifi>

这样必然是没有大多数路由器的原厂固件方便。大部分路由器的机身上都会有个贴纸，上面写有唯一属于该路由器的出厂默认 Wi-Fi 名称及密码；用户在首次设置路由器时，就可以使用贴纸上的信息，以无线的方式连接路由器，不必使用有线网。不过，OpenWrt 确实难以为用户配置与提供默认的 Wi-Fi 网络参数。使用固定的、在所有 OpenWrt 设备上都相同的初始 Wi-Fi 密码的话，确实会带来安全风险；随机密码安全性更高，但与路由器厂商能在路由器机身贴纸不同，OpenWrt 没有能在用户连接到路由器前告知用户随机密码的方式。因此，默认禁用 Wi-Fi 确实是适合 OpenWrt 的提高安全性的手段。

如果刷了 OpenWrt 的路由器使用 U-Boot 引导，就可以让 OpenWrt 在首次启动时默认启用 Wi-Fi，并且使用由用户配置的默认 Wi-Fi 名称与密码。默认 Wi-Fi 名称和密码的配置不会因恢复出厂设置或固件更新而失效。

默认在首次启动路由器时启用 Wi-Fi，适合有时需要恢复 OpenWrt 出厂设置、并且将路由器放置于不易触及位置的用户，以及手边经常没有配备有线网口设备的用户。此外，对于想向他人出售或转交预装 OpenWrt 的路由器的人群而言，这也是十分有用的：默认启用 Wi-Fi 后，就无需再指导新机主先通过有线网连接路由器、再修改 OpenWrt 配置以启用 Wi-Fi，而是可以直接将路由器机身贴纸上的 Wi-Fi 名称及密码设为 OpenWrt 的默认 Wi-Fi 参数，然后只需告诉新机主连接贴纸上所示的 Wi-Fi 网络即可。

## 检查路由器是否使用 U-Boot

一种粗浅但简便的检查刷了 OpenWrt 的路由器是否使用 U-Boot 的方式，是查看路由器上的 OpenWrt 系统中是否有 `/etc/fw_env.config` 文件；该文件中存储的是 [U-Boot 环境数据][openwrt-uboot.config]的位置。

1. [通过 SSH 连接到路由器][openwrt-sshadministration]。

2. 检查路由器上是否有 `/etc/fw_env.config` 文件：
   ```console
   # cat /etc/fw_env.config
   ```

   - 如果该命令输出 `cat: can't open '/etc/fw_env.config': No such file or directory`，就说明路由器**不使用** U-Boot。遇到此输出的用户仍然可以尝试[其它方法]，但**不应**采用下一小节中介绍的方法。

   - 如果该命令输出其它内容，那么路由器使用 U-Boot，用户即可遵循下一小节的步骤。

[openwrt-uboot.config]: https://openwrt.org/docs/techref/bootloader/uboot.config
[openwrt-sshadministration]: https://openwrt.org/zh/docs/guide-quick-start/sshadministration
[其它方法]: #其它方法

## 默认启用 Wi-Fi

1. 将以下命令中的占位符替换为合适的值，然后运行该命令：
   - `${SSID}`：默认的 Wi-Fi 名称，即 SSID。
   - `${PASSWORD}`：默认的 Wi-Fi 密码。
   - `${COUNTRY}`：默认的 [Wi-Fi 国家代码]，即代表路由器运行时所处国家的 [ISO 3166-1 二位字母代码]；此外，也可以指定代表全世界通用的特殊代码 `00` 。OpenWrt 需要该国家代码才能启用路由器上的 Wi-Fi 设备。

   ```console
   # fw_setenv --script /dev/stdin << EOF
   owrt_ssid ${SSID}
   owrt_wifi_key ${PASSWORD}
   owrt_country ${COUNTRY}
   EOF
   ```

   此命令会向 U-Boot 环境写入命令中指定的值。OpenWrt 在首次启动时，会读取 U-Boot 环境，用其中的值来初始化 Wi-Fi 网络参数。

   此命令并不会修改 OpenWrt 当前的 Wi-Fi 网络配置；其只会影响之后恢复出厂设置后的默认 Wi-Fi 配置。

2. 如果之前运行 `cat /etc/fw_env.config` 命令时，该命令输出了两行文本，那就说明路由器有两份 U-Boot 环境作为冗余[^u-boot-fw_env]。由于 `fw_setenv` 命令只会修改一份环境，在有两份环境的情况下，用户可以选择再运行一次同样的 `fw_setenv` 命令，以在另一份环境中应用同样的修改。这样做并不是必须的：因为 U-Boot 会始终使用最后修改的环境，所以只修改一份环境就够了。不过，如果在两份环境上都应用修改，就可以确保在即使有一份环境损坏时，OpenWrt 仍然会在首次启动时启用 Wi-Fi。

   如果 `cat /etc/fw_env.config` 命令只输出了一行文本，那就说明路由器只有一份 U-Boot 环境，这种情况下就完全无需再次运行 `fw_setenv` 命令了，因为没有其它冗余环境需要修改。

3. 验证是否已成功修改 U-Boot 环境。如果以下命令输出了之前 `fw_setenv` 命令中所设的值，就说明 U-Boot 环境修改成功。

   ```console
   # fw_printenv owrt_ssid owrt_wifi_key owrt_country
   owrt_ssid=<Wi-Fi 名称>
   owrt_wifi_key=<Wi-Fi 密码>
   owrt_country=<国家代码>
   ```

[Wi-Fi 国家代码]: https://openwrt.org/docs/guide-user/network/wifi/wifi_countrycode
[ISO 3166-1 二位字母代码]: https://zh.wikipedia.org/zh-cn/ISO_3166-1%E4%BA%8C%E4%BD%8D%E5%AD%97%E6%AF%8D%E4%BB%A3%E7%A0%81
[^u-boot-fw_env]: <https://github.com/u-boot/u-boot/blob/v2026.07/tools/env/fw_env.c#L1874>

## 原理

OpenWrt 从 24.10.0 版本起，会在首次启动时运行[一脚本][openwrt-git-fw_defaults]，从 U-Boot 环境读取 `owrt_ssid`、`owrt_wifi_key`、`owrt_country`、以及其它一些 `owrt_*` 变量，然后将读取到的值写入到 `/etc/board.json` 文件中。OpenWrt 在首次启动时，会创建 `/etc/board.json` 文件以用于存储路由器特定硬件信息，例如路由器有多少有线网口、Wi-Fi 设备、和 LED 指示灯。随后，OpenWrt 会使用该文件中的信息初始化配置。例如，OpenWrt 的 [Wi-Fi 脚本][openwrt-git-mac80211.uc]如果在 `/etc/board.json` 中找到了 Wi-Fi 名称和密码信息，就会使用该信息来初始化 Wi-Fi 参数，并启用 Wi-Fi。

由于恢复出厂设置和固件更新均不会擦除 U-Boot 环境，在 U-Boot 环境中设置的 Wi-Fi 参数不会受这些操作影响。

[openwrt-git-fw_defaults]: https://github.com/openwrt/openwrt/blob/v25.12.5/package/boot/uboot-tools/uboot-envtools/files/fw_defaults
[openwrt-git-mac80211.uc]: https://github.com/openwrt/openwrt/blob/v25.12.5/package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc#L88

## 撤销变动

使用以下命令即可让 OpenWrt 恢复在首次启动时禁用 Wi-Fi 的默认行为。在 `fw_setenv` 命令中，只要不为某一变量指定值，即可从 U-Boot 环境中删除该值。

```console
# fw_setenv --script /dev/stdin << EOF
owrt_ssid
owrt_wifi_key
owrt_country
EOF
```

此命令并不会清除 OpenWrt 当前的 Wi-Fi 网络配置；其只会影响之后恢复出厂设置后的默认 Wi-Fi 配置。

## 限制

许多路由器支持多频段，但并不能通过修改 U-Boot 环境的方式来为不同频段设置不同的 Wi-Fi 名称及密码；这种修改 U-Boot 环境来默认启用 Wi-Fi 的方法只能让所有频段都使用同样的默认名称和密码。如果想为不同频段应用不同的设置，就需要使用下一小节提及的其它方法。

## 其它方法

OpenWrt 文档中还介绍了[另一种][openwrt-wifi_enabled_on_first_boot]在首次启动时启用 Wi-Fi 的方法。该方法要求使用[映像构建器（Image Builder）]来制作自定义 OpenWrt 固件映像。用户编写脚本来设置默认 Wi-Fi 名称和密码，然后将该脚本添加到自定义固件的 [`/etc/uci-defaults` 目录][openwrt-uci-defaults]下。OpenWrt 在首次启动时，会运行一次该目录下的所有脚本。

这种方法确实有效；其实笔者在发现修改 U-Boot 环境的方法前，一直采用的就是这种方法。然而这种方法也有一些缺点。每次 OpenWrt 发布新版本时，如果还想保持默认启用 Wi-Fi 的效果，就必须再次运行 Image Builder 构建新版本固件的映像，并且向固件中添加同样的脚本。这样一来，其中一个后果就是路由器的用户无法使用[值守式系统升级功能]，因为值守式系统升级在构建固件映像时，不支持添加自定义的 `/etc/uci-defaults` 脚本。此外，拥有好几台同型号路由器的用户，如果想在不同路由器上使用不同的默认 Wi-Fi 名称和密码，就需要为每台路由器单独构建一份映像，并在制作每份映像时都使用不同的 `/etc/uci-defaults` 脚本，以设置不同的 Wi-Fi 名称和密码。这种情况下，即使路由器的型号都一样，也无法只构建一份通用映像。

如果路由器支持多频段，在脚本中为每个频段重复 `uci set` 命令，即可为所有频段设置 Wi-Fi 名称和密码，如以下示例所示。可以为不同的频段使用不同的名称和密码。
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
[映像构建器（Image Builder）]: https://openwrt.org/zh/docs/guide-user/additional-software/imagebuilder
[openwrt-uci-defaults]: https://openwrt.org/zh/docs/guide-developer/uci-defaults#%E9%9B%86%E6%88%90%E8%87%AA%E5%AE%9A%E4%B9%89%E8%AE%BE%E7%BD%AE
[值守式系统升级功能]: https://openwrt.org/docs/guide-user/installation/attended.sysupgrade
