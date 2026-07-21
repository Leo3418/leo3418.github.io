---
title: "在 OpenWrt 上创建暴露于公网的 IPv6 子网"
tags:
  - OpenWrt
categories:
  - 教程
toc: true
---

有些家庭宽带用户有将他们家庭网络中的部分设备开放给公网访问、并同时阻止公网访问其它设备需求。例如，家里的服务器可以允许公网访问，但手机、工作站之类的设备则应隔离于公网。实现这种需求的一种方法就是为开放给公网访问的设备专门建立一个子网，将该子网暴露在公网之下，而其它不希望公网访问的设备则继续连接默认的局域网子网，受防火墙保护，屏蔽公网访问。这种暴露于公网的子网，英文叫 demilitarized zone (DMZ)，字面意思是“非军事区”，而在计算机网络的语境中也被称为“[对外网络][wikipedia-dmz]”。

如果运营商提供 IPv6，且分配了前缀长度不超过 */63* 的 IPv6 路由前缀，那就可以通过创建两个 IPv6 子网来实现这种需求。由于 IPv4 地址已经枯竭，在公网中创建 IPv4 子网对家庭宽带用户而言根本不现实：能有一个公网 IPv4 地址就不错了，更何况很多人都没有，只能依赖运营商级 NAT。不过，随着 IPv6 日渐普及，有条件的用户可以转向基于 IPv6 子网的方案（只要运营商并非只给了一个 */64* 前缀或者单个 */128* 地址）。即使是只有一个 */64* 前缀或 */128* 地址的用户，以及根本没有 IPv6 的用户，但凡能拿到公网 IPv4 地址，也可以考虑借助 6in4 隧道来开启 IPv6，比如 [Hurricane Electric 的 IPv6 隧道](https://tunnelbroker.net/)；有些隧道会慷慨地提供一个 */48*。（依赖 IPv6 组建公网的缺点是，在只有 IPv4，没有 IPv6 的网络环境中无法访问 DMZ 中的设备。例如，如果宾馆 Wi-Fi 没有 IPv6，就没法在宾馆访问家里的服务器。）

本教程将介绍在 OpenWrt 上创建 IPv6 DMZ 的步骤。当前版本教程的内容已在 OpenWrt 25.12.5 上通过验证。

[wikipedia-dmz]: https://zh.wikipedia.org/zh-cn/DMZ

## 通过 SSH 连接到路由器

本教程中的步骤将指引网络管理员（即负责配置路由器的人员）通过 SSH 在路由器上运行命令来配置路由器。如需具体了解如何通过 SSH 连接路由器，可参考 [OpenWrt 文档的相关说明（英文内容）][openwrt-sshadministration]。

虽然可以通过 LuCI 网页端界面达到同样的配置效果，但考虑到以下原因，本教程提供适用于命令行的操作步骤：
- 并非所有 OpenWrt 刷机包里都有 LuCI：预发行快照版本和低配置设备（4 MB 存储空间和/或 32 MB 内存）的刷机包就不自带 LuCI。而命令行环境则是任何情况下都能使用的。
- 针对 LuCI 的操作步骤相对更容易因为 OpenWrt 新版本对网页端界面的改动而失效。

[openwrt-sshadministration]: https://openwrt.org/docs/guide-quick-start/sshadministration

## 为 DMZ 组件设置 Shell 变量

通过 SSH 连接到路由器后，运行以下命令，设置在后续步骤中会用到的 shell 变量：

```console
# DMZ_DEVICE_NAME=br-dmz
# DMZ_INTERFACE=dmz
```

`DMZ_DEVICE_NAME` 将会用作 DMZ 网络设备的名称，而 `DMZ_INTERFACE` 将成为网络接口的名称。以上命令中使用的名称是遵循 OpenWrt 命名风格的名称；网络管理员可选择使用其它名称。

在完成 DMZ 配置前，每次通过 SSH 重连路由器继续配置 DMZ 时，都应重新运行以上命令，以重新设置变量。以上命令设置的变量仅在当前 shell 内有效，因此在重新连接、进入新 shell 时，需要重新设置变量。
{.notice--warning}

## 创建 DMZ

DMZ 本质上是个子网，而在 OpenWrt 上，每个子网都需要一个网络设备以及一个网络[接口][openwrt-interface]。

[openwrt-interface]: https://openwrt.org/docs/guide-user/base-system/clarifying_interface_usage

### 为 DMZ 创建设备

1. 添加新设备配置。以下命令在创建配置的同时，输出 OpenWrt 为新配置[自动生成的 ID][openwrt-uci-sections_naming]。下列的示例输出可能与实际输出不同；这是正常现象。

   ```console
   # DMZ_DEVICE=$(uci add network device); echo ${DMZ_DEVICE}
   cfg070f15
   ```

2. 将设备类型设为网桥设备。

   ```console
   # uci set network.${DMZ_DEVICE}.type=bridge
   ```

3. 指定设备名。以下命令使用 shell 变量 `DMZ_DEVICE_NAME` 的值作为设备名。

   ```console
   # uci set network.${DMZ_DEVICE}.name=${DMZ_DEVICE_NAME}
   ```

4. 建议启用“允许启动空网桥”选项，以确保通过无线方式连接 DMZ 的主机能从 DHCP 服务器获取 IPv6 地址。截至 OpenWrt 25.12.5 版本，如果未启用此选项，且所有主机都通过 Wi-Fi 连接 DMZ 的话，那么每当路由器刚刚重启时，DMZ 主机就可能获取不到 IPv6 地址，只被分配 IPv4 地址。

   ```console
   # uci set network.${DMZ_DEVICE}.bridge_empty='1'
   ```

5. 检查待应用的配置。

   ```console
   # uci changes
   network.cfg070f15='device'
   network.cfg070f15.type='bridge'
   network.cfg070f15.name='br-dmz'
   network.cfg070f15.bridge_empty='1'
   ```

6. 如果看起来没有问题，就应用配置，以创建设备。
   ```console
   # uci commit
   ```

[openwrt-uci-sections_naming]: https://openwrt.org/docs/guide-user/base-system/uci#sections_naming

### 规划子网

这一步要作的一个决定是 DMZ 子网和默认的局域网（LAN）子网的 IPv6 前缀长度（LAN 就是应受到防火墙保护、不暴露于公网的子网）。而子网前缀长度则取决于运营商分配的路由前缀有多长。

以下命令可获取运营商分配的前缀。第一个命令输出前缀所对应的地址块中的首个地址，而第二个命令输出前缀的长度。

```console
# ifstatus wan6 | jsonfilter -e '@["ipv6-prefix"][0].address'
2001:db8:85a3:1200::
# ifstatus wan6 | jsonfilter -e '@["ipv6-prefix"][0].mask'
56
```

此示例中，运营商分配的 IPv6 地址块的前缀是 `2001:db8:85a3:1200::`，前缀长度则为 */56*。此前缀通常写作 `2001:db8:85a3:1200::/56`。

这种情况下，有多种子网规划可供选择，包括但不限于：

- 将整个地址块平分为两个子网；在此示例中，两个子网将会是 `2001:db8:85a3:1200::/57` 和 `2001:db8:85a3:1280::/57`。如果未来没有继续与这两个子网并列创建其它子网的计划，就可以采取此种规划。但是，如果未来可能并列创建新子网，例如访客 Wi-Fi 子网，就不应采取此种规划了，因为将整个地址块都给这两个子网分配完后，就没有任何富余留给新子网了。

- 为 DMZ 和 LAN 各自分配一个 */64* 子网，例如 `2001:db8:85a3:1200::/64` 和 `2001:db8:85a3:1201::/64`。如果未来要创建更多与 DMZ 和 LAN 并列的子网的话，这样可以最大化将来能创建的子网数量。然而，因为 */64* 子网无法再分成更小的子网，所以在 DMZ 和 LAN 子网*之下*都无法再嵌套创建更多小子网了。这意味着，如果要在主路由器后面再接一个路由器，那么后面的路由器就无法获取其专属的 IPv6 子网了，而是需要依赖 NAT 才能实现 IPv6 访问，直接破坏了 IPv6 的端对端设计理念。

- 折中选择前缀长度，并为两个子网选择相同的前缀长度，例如 */60*。这样所得到的子网就诸如  `2001:db8:85a3:1200::/60` 和 `2001:db8:85a3:1210::/60`。这样一来，以后既可以继续创建更多与 DMZ 和 LAN 并列的子网，也可以在 DMZ 和 LAN 之下再嵌套创建小子网。网络管理员可根据实际需求选择合适的前缀长度，平衡取舍。

- 为两个子网选择不同的前缀长度。如果未来在 DMZ 中可能嵌套创建的子网数量与在 LAN 中嵌套的不同的话，就可以采取此种规划。例如，如果不准备将 DMZ 继续划分为更小的嵌套子网，但未来可能会将 LAN 继续划分为两个嵌套子网，那就可以将 DMZ 弄成 */64*，并将 LAN 弄成 */63* 以允许其将来继续被分为两个 */64* 子网。这样一来，DMZ 子网就可以是 `2001:db8:85a3:1200::/64`，而 LAN 子网可以是 `2001:db8:85a3:1202::/63`。

在规划子网、评估选项、计算子网前缀时，可使用 [IPv6 子网计算器]辅助决策。

{{<div class="notice--success">}}
**技巧：** OpenWrt 的默认配置可能会让运营商分配的 IPv6 地址块规模小于客户实际可取得的最大地址块。例如，默认配置可能导致路由器只获取到一个 */64* 地址块，但实际上运营商最大可以提供 */56*。有时候，默认配置甚至可能导致路由器拿不到 IPv6 地址。无论是这其中哪种情况，都可以尝试在配置中更改请求 IPv6 前缀长度来解决。例如，如果想将长度改为 */48*，运行下列命令：

```console
# uci set network.wan6.reqprefix=48
# uci commit
# /etc/init.d/network reload
```

建议先从最大的地址块规模（*/48*）开始尝试，因为据说有的运营商在已经给客户分配了较小的地址块后，无论客户把前缀长度改成多少，都不会再分配更大的地址块了。

如果请求的地址块大小超出了运营商愿意分配的最大规模，那么路由器可能拿不到 IPv6 地址。这种情况下，可尝试上调前缀长度，以缩小请求的地址块（前缀越长，地址块越小）。
{{</div>}}

于此同时，为了让 DMZ 对 LAN 中的主机同时开放 IPv4 和 IPv6 访问（即双栈），可为 DMZ 创建 IPv4 内网子网，与 LAN 的 IPv4 内网子网并列。（IPv4 内网子网只能解决 LAN 通过 IPv4 访问 DMZ 的问题；公网主机在只有 IPv4 的情况下依然无法访问 DMZ。）先使用以下命令查询 LAN 的 IPv4 子网：

```console
# uci get network.lan.ipaddr
192.168.1.1/24
```

DMZ 的 IPv4 子网可使用同样的前缀长度。并起始于下一个可用的 IPv4 地址，例如 `192.168.2.1/24`。网络管理员可以自由选择不同的子网和前缀长度，只要和已有的子网不冲突即可。

[IPv6 子网计算器]: https://www.site24x7.com/zhcn/tools/ipv6-subnetcalculator.html

### 为 DMZ 创建接口

1. 添加新接口配置，使用静态地址协议，并指定设备为刚刚为 DMZ 创建的设备。

   ```console
   # uci set network.${DMZ_INTERFACE}=interface
   # uci set network.${DMZ_INTERFACE}.proto=static
   # uci set network.${DMZ_INTERFACE}.device=${DMZ_DEVICE_NAME}
   ```

2. 配置 DMZ 和 LAN 的 IPv6 子网。每个子网需要两项设置。`ip6assign` 选项的意义相对简单，就是子网的 IPv6 前缀长度。

   另一个选项 `ip6hint` 就需要多解释一下。这个选项影响的就是子网前缀的数值了。该选项的值使用十六进制指定（毕竟 IPv6 地址一般也使用十六进制书写），这样在计算子网前缀的数值时，就可以将该选项的值与运营商分配的前缀中最高的 64 位进行加法数学运算，得到的结果即为子网前缀（如果运营商分配的前缀长度不足 */64*，那么在计算时，会将其长度视为 */64*）。例如：

   - 如果运营商分配了前缀 `2001:db8:85a3:1200::/56`，`ip6assign` 设为 `60`，`ip6hint` 设为 `10`，那么子网前缀将是 `2001:db8:85a3:1210::/60`，即 `ip6hint` 的值 `10` 与运营商分配的前缀之和：`2001:db8:85a3:1200 + 10 = 2001:db8:85a3:1210`。

   - 如果运营商分配了前缀 `2001:db8:85a3:1200::/56`，`ip6assign` 设为 `60`，`ip6hint` 设为 `0`，那么子网前缀将是 `2001:db8:85a3:1200::/60`：虽然两个前缀看起来数值是一样的，但因为长度不同，它们实际上仍是不同的前缀。

   - 如果运营商分配了前缀 `2001:db8:85a3::/48`，`ip6assign` 设为 `49`，`ip6hint` 设为 `0`，那么子网前缀将是 `2001:db8:85a3::/49`。虽然 */49* 意味着地址中的第四组数位中的第一比特成为了前缀的一部分，但在表达该前缀时，第四组数依然可以省略。该前缀的完整写法是 `2001:0db8:85a3:0000:0000:0000:0000:0000/49`，但多组连续的零可以直接用两个冒号（`::`）替代，以实现简写。

   - 如果运营商分配了前缀 `2001:db8:85a3::/48`，`ip6assign` 设为 `49`，`ip6hint` 设为 `8000`，那么子网前缀将是 `2001:db8:85a3:8000::/49`。首先，如果运营商分配的前缀长度不足 */64*，那么在计算时，会将其视为 */64* 前缀，即 `2001:db8:85a3:0000`。接着，将 `ip6hint` 与运营商分配的前缀相加，得出 `2001:db8:85a3:0000 + 8000 = 2001:db8:85a3:8000`。

     值得注意的是，这个子网前缀的表示形式比 `2001:db8:85a3::/49` 的要长，即便两个前缀之间只差一比特。当两个前缀表示形式长度不同时，**推荐将表示形式较短的前缀分配给 DMZ，将较长的分配给 LAN**：这是因为 DMZ 中的主机会被更频繁地访问，而地址表示形式越短，输入起来越快，访问 DMZ 主机也就相对越方便。

   - 如果运营商分配了前缀 `2001:db8:85a3:1248::/61`，`ip6assign` 设为 `62`，`ip6hint` 设为 `4`，那么子网前缀将是 `2001:db8:85a3:124c::/62`，因为 `2001:db8:85a3:1248 + 4 = 2001:db8:85a3:124c`。

   以下示例中的命令为 DMZ 和 LAN 各创建一个 */60* 子网；如果运营商分配了前缀 `2001:db8:85a3:1200::/56`，那么 DMZ 子网的前缀将是 `2001:db8:85a3:1200::/60`，而 LAN 子网的前缀则将是 `2001:db8:85a3:1210::/60`。

   ```console
   # uci set network.${DMZ_INTERFACE}.ip6assign=60
   # uci set network.${DMZ_INTERFACE}.ip6hint=0
   # uci set network.lan.ip6assign=60
   # uci set network.lan.ip6hint=10
   ```

   以下示例为 DMZ 和 LAN 各创建一个 */49* 子网；如果运营商分配了前缀 `2001:db8:85a3::/48`，那么 DMZ 子网的前缀将是 `2001:db8:85a3::/49`，而 LAN 子网的前缀则将是 `2001:db8:85a3:8000::/49`。此番设置遵循前面的推荐，将表示形式较短的前缀分配给 DMZ。

   ```console
   # uci set network.${DMZ_INTERFACE}.ip6assign=49
   # uci set network.${DMZ_INTERFACE}.ip6hint=0
   # uci set network.lan.ip6assign=49
   # uci set network.lan.ip6hint=8000
   ```

   在计算选项的值时，可参考 [IPv6 子网计算器]的结果。

3. 配置 DMZ 的 IPv4 子网。以下命令将其设为 `192.168.2.1/24`。

   ```console
   # uci add_list network.${DMZ_INTERFACE}.ipaddr=192.168.2.1/24
   ```

4. 检查待应用的配置。

   ```console
   # uci changes
   network.dmz='interface'
   network.dmz.proto='static'
   network.dmz.device='br-dmz'
   network.dmz.ip6assign='60'
   network.dmz.ip6hint='0'
   network.lan.ip6assign='60'
   network.lan.ip6hint='10'
   network.dmz.ipaddr+='192.168.2.1/24'
   ```

5. 如果看起来没有问题，就应用配置，以创建接口。

   ```console
   # uci commit
   # /etc/init.d/network reload
   ```

### 在 DMZ 接口上启用 DHCP

在接口上启用 DHCP 后，OpenWrt 就会为每台连接到 DMZ 的主机分配一个公网 IPv6 地址和一个内网 IPv4 地址。以下 `uci batch` 命令批量将 OpenWrt 的默认 DHCP 设置应用于 DMZ 上。

```console
# uci batch << EOF
set dhcp.${DMZ_INTERFACE}=dhcp
set dhcp.${DMZ_INTERFACE}.interface=${DMZ_INTERFACE}
set dhcp.${DMZ_INTERFACE}.start=100
set dhcp.${DMZ_INTERFACE}.limit=150
set dhcp.${DMZ_INTERFACE}.leasetime=12h
set dhcp.${DMZ_INTERFACE}.dhcpv4=server
set dhcp.${DMZ_INTERFACE}.dhcpv6=server
set dhcp.${DMZ_INTERFACE}.ra=server
add_list dhcp.${DMZ_INTERFACE}.ra_flags=managed-config
add_list dhcp.${DMZ_INTERFACE}.ra_flags=other-config
EOF
```

检查待应用的配置。

```console
# uci changes
dhcp.dmz='dhcp'
dhcp.dmz.interface='dmz'
dhcp.dmz.start='100'
dhcp.dmz.limit='150'
dhcp.dmz.leasetime='12h'
dhcp.dmz.dhcpv4='server'
dhcp.dmz.dhcpv6='server'
dhcp.dmz.ra='server'
dhcp.dmz.ra_flags+='managed-config'
dhcp.dmz.ra_flags+='other-config'
```

如果看起来没有问题，就应用配置，以启用 DHCP。

```console
# uci commit
# /etc/init.d/dnsmasq reload
# /etc/init.d/odhcpd reload
```

## 为 DMZ 配置防火墙

为了允许从公网访问 DMZ 中的主机，需要修改 OpenWrt 的防火墙设置。此外，还可以允许 LAN 主机访问 DMZ 主机，就可以支持诸如让 LAN 中的电脑往 DMZ 中的家庭服务器上传数据备份的应用场景。与此同时，由于 DMZ 暴露在公网当中，应对 DMZ 进行保护，采取诸如禁止从 DMZ 访问 LAN 的措施。

### 为 DMZ 创建并配置防火墙区域

1. 添加 DMZ 防火墙区域配置，指定其入站、出站、和区域内转发策略。[OpenWrt 官方文档（英文内容）][openwrt-firewall_configuration-zones]中有对这三种流量的含义有说明，以下解释也可以参考：

   入站（`input`）
   : 指定该如何处理从 DMZ 中的主机到路由器的流量。也包括从 DMZ 到其它防火墙区域（例如 LAN、以及代表公网的 WAN）的流量，毕竟这些流量离开 DMZ 后需要先经过路由器，然后路由器才能将它们转发到目的地区域。此处应使用“接受”（`ACCEPT`），以允许 DMZ 主机访问公网，完成诸如下载软件更新的任务。

   出站（`output`）
   : 指定该如何处理从路由器到 DMZ 中的主机的流量。也包括从其它防火墙区域到 DMZ 的流量，毕竟这些流量需要先从其它区域发到路由器，然后路由器才能将它们转发到 DMZ 区域。此处应使用“接受”（`ACCEPT`），以允许其它区域中的主机访问 DMZ 主机。

   区域内转发（`forward`）
   : 指定该如何处理从 DMZ 区域中的某网络接口到 DMZ 区域中的另一网络接口的流量。此教程中所配置的 DMZ 只需要一个网络接口，因此实际上不会有区域内转发流量，此设置的值也就没有实际意义，故可以选取任何策略。以下命令使用“拒绝”（`REJECT`）策略，不向流量赋予不必要的权限，以保障最高安全性。

   ```console
   # DMZ_ZONE=$(uci add firewall zone); echo ${DMZ_ZONE}
   cfg0edc81
   # uci batch << EOF
   set firewall.${DMZ_ZONE}.name=${DMZ_INTERFACE}
   set firewall.${DMZ_ZONE}.input=ACCEPT
   set firewall.${DMZ_ZONE}.output=ACCEPT
   set firewall.${DMZ_ZONE}.forward=REJECT
   add_list firewall.${DMZ_ZONE}.network=${DMZ_INTERFACE}
   EOF
   ```

2. 添加允许 WAN 转发至 DMZ 的转发策略，从而让公网上的主机可以访问 DMZ 中的主机。

   ```console
   # FORWARDING_WAN_DMZ=$(uci add firewall forwarding); echo ${FORWARDING_WAN_DMZ}
   cfg0fad58
   # uci set firewall.${FORWARDING_WAN_DMZ}.src=wan
   # uci set firewall.${FORWARDING_WAN_DMZ}.dest=${DMZ_INTERFACE}
   ```

3. 添加允许 DMZ 转发至 WAN 的转发策略，从而让 DMZ 主机可以上公网。

   ```console
   # FORWARDING_DMZ_WAN=$(uci add firewall forwarding); echo ${FORWARDING_DMZ_WAN}
   cfg10ad58
   # uci set firewall.${FORWARDING_DMZ_WAN}.src=${DMZ_INTERFACE}
   # uci set firewall.${FORWARDING_DMZ_WAN}.dest=wan
   ```

4. 添加允许 LAN 转发至 DMZ 的转发策略，从而让 LAN 中的主机可以访问 DMZ 中的主机。

   ```console
   # FORWARDING_LAN_DMZ=$(uci add firewall forwarding); echo ${FORWARDING_LAN_DMZ}
   cfg11ad58
   # uci set firewall.${FORWARDING_LAN_DMZ}.src=lan
   # uci set firewall.${FORWARDING_LAN_DMZ}.dest=${DMZ_INTERFACE}
   ```

5. 检查待应用的配置。

   ```console
   # uci changes
   firewall.cfg0edc81='zone'
   firewall.cfg0edc81.name='dmz'
   firewall.cfg0edc81.input='ACCEPT'
   firewall.cfg0edc81.output='ACCEPT'
   firewall.cfg0edc81.forward='REJECT'
   firewall.cfg0edc81.network+='dmz'
   firewall.cfg0fad58='forwarding'
   firewall.cfg0fad58.src='wan'
   firewall.cfg0fad58.dest='dmz'
   firewall.cfg10ad58='forwarding'
   firewall.cfg10ad58.src='dmz'
   firewall.cfg10ad58.dest='wan'
   firewall.cfg11ad58='forwarding'
   firewall.cfg11ad58.src='lan'
   firewall.cfg11ad58.dest='dmz'
   ```

6. 如果看起来没有问题，就应用配置，以完成防火墙区域的配置。
   ```console
   # uci commit
   ```

由于并没有添加 DMZ 转发至 LAN 的转发策略，DMZ 主机无法访问 LAN 主机。这样有助于加强网络安全：即便公网上有攻击者成功黑进 DMZ 中的主机，OpenWrt 的防火墙依然会阻止攻击者通过 DMZ 主机访问 LAN，从而为 LAN 提供最大程度的保护。

[openwrt-firewall_configuration-zones]: https://openwrt.org/docs/guide-user/firewall/firewall_configuration#zones

### 阻止 DMZ 访问路由器

如果不继续配置防火墙，DMZ 中的主机就可以访问路由器本身，从而导致路由器被暴露在公网当中（即使是间接的）。这样不利于网络安全，因为路由器在网络安全中起到关键作用，不应允许公网上的任何人访问。假如有攻击者利用漏洞已经攻破 DMZ 中的某台主机上的 SSH 服务端，可以通过 SSH 登录该设备了，那攻击者就可以使用该主机尝试访问路由器，继续通过同样或类似的漏洞攻破路由器的 SSH 服务端，从而取得对路由器的完整访问，因而获得对整个网络的控制能力。

因此，DMZ 对路由器的访问应被阻止，以保障最高安全性。路由器只应对 DMZ 开放 DMZ 主机正常运行必需的端口，即 DNS 和 DHCP 的相关端口。

1. 添加允许 DMZ 主机访问路由器上的 DNS 服务器的通信规则。

   ```console
   # RULE_DNS=$(uci add firewall rule); echo ${RULE_DNS}
   cfg1292bd
   # uci batch << EOF
   set firewall.${RULE_DNS}.name=Allow-DMZ-DNS
   set firewall.${RULE_DNS}.src=${DMZ_INTERFACE}
   set firewall.${RULE_DNS}.dest_port=53
   set firewall.${RULE_DNS}.target=ACCEPT
   EOF
   ```

2. 添加允许 DMZ 主机访问路由器上的 DHCPv4 服务器的通信规则，从而让 DMZ 主机能够获得 IPv4 地址。

   ```console
   # RULE_DHCP=$(uci add firewall rule); echo ${RULE_DHCP}
   cfg1392bd
   # uci batch << EOF
   set firewall.${RULE_DHCP}.name=Allow-DMZ-DHCP
   set firewall.${RULE_DHCP}.family=ipv4
   add_list firewall.${RULE_DHCP}.proto=udp
   set firewall.${RULE_DHCP}.src=${DMZ_INTERFACE}
   set firewall.${RULE_DHCP}.dest_port=67
   set firewall.${RULE_DHCP}.target=ACCEPT
   EOF
   ```

3. 添加允许 DMZ 主机访问路由器上的 DHCPv6 服务器的通信规则，从而让 DMZ 主机能够获得 IPv6 地址。

   ```console
   # RULE_DHCPV6=$(uci add firewall rule); echo ${RULE_DHCPV6}
   cfg1492bd
   # uci batch << EOF
   set firewall.${RULE_DHCPV6}.name=Allow-DMZ-DHCPv6
   set firewall.${RULE_DHCPV6}.family=ipv6
   add_list firewall.${RULE_DHCPV6}.src_ip=fc00::/6
   add_list firewall.${RULE_DHCPV6}.dest_ip=fc00::/6
   add_list firewall.${RULE_DHCPV6}.proto=udp
   set firewall.${RULE_DHCPV6}.src=${DMZ_INTERFACE}
   set firewall.${RULE_DHCPV6}.dest_port=547
   set firewall.${RULE_DHCPV6}.target=ACCEPT
   EOF
   ```

4. 添加阻止 DMZ 主机到路由器的其它流量的通信规则。

   ```console
   # RULE_DENY=$(uci add firewall rule); echo ${RULE_DENY}
   cfg1592bd
   # uci batch << EOF
   set firewall.${RULE_DENY}.name=Deny-DMZ-To-Router
   set firewall.${RULE_DENY}.src=${DMZ_INTERFACE}
   set firewall.${RULE_DENY}.target=REJECT
   EOF
   ```

5. 检查待应用的配置。

   ```console
   # uci changes
   firewall.cfg1292bd='rule'
   firewall.cfg1292bd.name='Allow-DMZ-DNS'
   firewall.cfg1292bd.src='dmz'
   firewall.cfg1292bd.dest_port='53'
   firewall.cfg1292bd.target='ACCEPT'
   firewall.cfg1392bd='rule'
   firewall.cfg1392bd.name='Allow-DMZ-DHCP'
   firewall.cfg1392bd.family='ipv4'
   firewall.cfg1392bd.proto+='udp'
   firewall.cfg1392bd.src='dmz'
   firewall.cfg1392bd.dest_port='67'
   firewall.cfg1392bd.target='ACCEPT'
   firewall.cfg1492bd='rule'
   firewall.cfg1492bd.name='Allow-DMZ-DHCPv6'
   firewall.cfg1492bd.family='ipv6'
   firewall.cfg1492bd.src_ip+='fc00::/6'
   firewall.cfg1492bd.dest_ip+='fc00::/6'
   firewall.cfg1492bd.proto+='udp'
   firewall.cfg1492bd.src='dmz'
   firewall.cfg1492bd.dest_port='547'
   firewall.cfg1492bd.target='ACCEPT'
   firewall.cfg1592bd='rule'
   firewall.cfg1592bd.name='Deny-DMZ-To-Router'
   firewall.cfg1592bd.src='dmz'
   firewall.cfg1592bd.target='REJECT'
   ```

6. 如果看起来没有问题，就应用配置，以创建通信规则。

   ```console
   # uci commit
   # /etc/init.d/firewall reload
   ```

## 将有线网口和 Wi-Fi 接入点与 DMZ 关联

DMZ 和 LAN 上的主机都可以连接到同一台路由器上。DMZ 和 LAN 主机的隔离，可通过将路由器上的任何有线网口以及/或者新的 Wi-Fi 接入点与 DMZ 关联来实现。完成此番配置后，如果想将一台主机连到 DMZ，将该主机连接到与 DMZ 关联的有线网口或 Wi-Fi 接入点即可；LAN 主机则继续连接到其它有线网口或原有的 Wi-Fi 接入点。

### 有线网口

默认配置下，路由器所有的有线网口都是和 LAN 关联的。网络管理员可将任意有线网口改为与 DMZ 关联，随后只要将主机连到与 DMZ 关联的有线网口上，该主机就将加入 DMZ，而接到其它有线网口则会让该主机加入 LAN。

1. 查询 LAN 和 DMZ 的网络设备的 ID，并将结果保存到 shell 变量中，以便之后使用。

   ```console
   # LAN_DEVICE=$(uci show network | grep "name='br-lan'" | cut -d. -f2); echo ${LAN_DEVICE}
   @device[0]
   # DMZ_DEVICE=$(uci show network | grep "name='${DMZ_DEVICE_NAME}'" | cut -d. -f2); echo ${DMZ_DEVICE}
   @device[1]
   ```

2. 查询局域网有线网口的名称列表。

   ```console
   # uci show network.${LAN_DEVICE}.ports
   network.cfg030f15.ports='lan1' 'lan2' 'lan3' 'lan4'
   ```

   此示例中的输出表明，路由器总共有 4 个局域网口，分别命名为 `lan1`、`lan2`、`lan3`、和 `lan4`。

3. 若要将某个有线网口关联的子网从 LAN 改为 DMZ，应将该有线网口的名称从 LAN 的配置的 `ports` 列表中删除，然后将其添加至 DMZ 相应的 `ports` 列表。例如，以下命令将 `lan1` 接口与 DMZ 关联。

   ```console
   # uci del_list network.${LAN_DEVICE}.ports=lan1
   # uci add_list network.${DMZ_DEVICE}.ports=lan1
   ```

4. 检查待应用的配置。

   ```console
   # uci changes
   network.cfg030f15.ports-='lan1'
   network.cfg070f15.ports+='lan1'
   ```

5. 如果看起来没有问题，就应用配置，以改变有线网口的关联。

   ```console
   # uci commit
   # /etc/init.d/network reload
   ```

### Wi-Fi 接入点

网络管理员可创建任意数量的 Wi-Fi 接入点与 DMZ 关联。当主机连接到与 DMZ 关联的接入点时，该主机就将加入 DMZ，而将其连接到原有的接入点则会让其加入 LAN。

1. 查询路由器的 Wi-Fi 设备的名称。支持多频段的 Wi-Fi 路由器通常有多个 Wi-Fi 设备，每个设备对应一个频段。

   ```console
   # uci show wireless | grep wifi-device
   wireless.radio0=wifi-device
   wireless.radio1=wifi-device
   ```

   此示例的输出表明，路由器有 2 个 Wi-Fi 设备，分别命名为 `radio0` 和 `radio1`。

   至于每个 Wi-Fi 设备对应哪个频段，可通过使用 `uci get wireless.<设备名>.band` 命令查询该设备的 `band` 选项的值得出：

   ```console
   # uci get wireless.radio0.band
   2g
   # uci get wireless.radio1.band
   5g
   ```

   以上输出显示，`radio0` 对应 2.4 GHz 频段，而 `radio1` 对应 5 GHz 频段。

2. 为每个想要给 DMZ 使用的 Wi-Fi 频段的设备创建接入点。

   1. 为方便后续步骤，先设置几个 shell 变量，用于存储 Wi-Fi 设备的名称和新接入点的配置名称。以下命令指定 `radio0` 为新接入点的设备，并使用遵循 OpenWrt 命名风格的配置名称。网络管理员可根据实际需求修改任何变量的值。

      ```console
      # WIFI_DEVICE=radio0
      # WIFI_IFACE=dmz_${WIFI_DEVICE}
      ```

   2. 添加新 Wi-Fi 接口，将模式设为接入点（AP），并指定 DMZ 接口作为该 Wi-Fi 关联的网络。

      ```console
      # uci set wireless.${WIFI_IFACE}=wifi-iface
      # uci set wireless.${WIFI_IFACE}.device=${WIFI_DEVICE}
      # uci set wireless.${WIFI_IFACE}.mode=ap
      # uci set wireless.${WIFI_IFACE}.network=${DMZ_INTERFACE}
      ```

   3. 指定接入点的安全性，包括 SSID（也就是 Wi-Fi 名称）、加密协议、以及密码。SSID 应与已有的关联于 LAN 的接入点不同。

      ```console
      # uci set wireless.${WIFI_IFACE}.ssid=OpenWrt-DMZ
      # uci set wireless.${WIFI_IFACE}.encryption=sae-mixed
      # uci set wireless.${WIFI_IFACE}.key=password
      ```

   4. 若要让 DMZ 运行于更多频段上，为每个频段重复以上步骤。Shell 变量 `WIFI_DEVICE` 的值应改为新频段对应的 Wi-Fi 设备的名称。

      新频段的接入点的安全性可以跟前面已经为 DMZ 创建的接入点相同，也可以不同。如果相同，DMZ 主机使用同样的 SSID 和密码就可以连接任意频段，并且可以在频段之间自动切换。

      ```console
      # WIFI_DEVICE=radio1
      # WIFI_IFACE=dmz_${WIFI_DEVICE}
      # uci set wireless.${WIFI_IFACE}=wifi-iface
      # uci set wireless.${WIFI_IFACE}.device=${WIFI_DEVICE}
      # uci set wireless.${WIFI_IFACE}.mode=ap
      # uci set wireless.${WIFI_IFACE}.network=${DMZ_INTERFACE}
      ```
      ```console
      # uci set wireless.${WIFI_IFACE}.ssid=OpenWrt-DMZ
      # uci set wireless.${WIFI_IFACE}.encryption=sae-mixed
      # uci set wireless.${WIFI_IFACE}.key=password
      ```

3. 检查待应用的配置。

   ```console
   # uci changes
   wireless.dmz_radio0='wifi-iface'
   wireless.dmz_radio0.device='radio0'
   wireless.dmz_radio0.mode='ap'
   wireless.dmz_radio0.network='dmz'
   wireless.dmz_radio0.ssid='OpenWrt-DMZ'
   wireless.dmz_radio0.encryption='sae-mixed'
   wireless.dmz_radio0.key='password'
   wireless.dmz_radio1='wifi-iface'
   wireless.dmz_radio1.device='radio1'
   wireless.dmz_radio1.mode='ap'
   wireless.dmz_radio1.network='dmz'
   wireless.dmz_radio1.ssid='OpenWrt-DMZ'
   wireless.dmz_radio1.encryption='sae-mixed'
   wireless.dmz_radio1.key='password'
   ```

4. 如果看起来没有问题，就应用配置，以创建 Wi-Fi 接入点。

   ```console
   # uci commit
   # wifi reload
   ```
