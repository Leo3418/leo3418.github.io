---
title: "Fedora 在树莓派 4 上的 USB 问题的简易解决方法"
lang: zh
tags:
  - 树莓派
  - Fedora
categories:
  - 教程
toc: true
---

截至 Fedora 32 和 Linux 5.8，在树莓派 4B 4GB/8GB 内存型号上使用 Fedora 会出现 USB 接口无法使用的情况。在这篇帖子中，我将介绍一种十分简单的解决方法，简单到只需要给一个配置文件加一行选项。

## 注意事项

- 树莓派 4B 2GB 内存型号的用户不需要担心这个问题，USB 接口在 Fedora 上应该是可以直接用的。4GB 和 8GB 型号的用户才可能遇到这个问题。

- 使用此帖中介绍的这个方法后，**系统将只能使用 3 GiB 内存**。如果您需要更多的内存的话，就得用另一种[稍复杂的方法](/2020/09/21/raspi4-fedora-usb-complex.html)了。虽然它的步骤比这种简单方法多，但是不会减少可用内存。

## 症状

树莓派的 USB 接口在官方的树莓派 OS 和其它系统上能用，但是在 Fedora 上无法使用。运行 `dmesg | grep xhci_hcd` 会出现下列信息：

```console
$ dmesg | grep xhci_hcd
[   19.961404] xhci_hcd 0000:01:00.0: xHCI Host Controller
[   19.974551] xhci_hcd 0000:01:00.0: new USB bus registered, assigned bus number 1
[   29.988717] xhci_hcd 0000:01:00.0: can't setup: -110
[   30.000126] xhci_hcd 0000:01:00.0: USB bus 1 deregistered
[   30.021077] xhci_hcd 0000:01:00.0: init 0000:01:00.0 fail, -110
[   30.033104] xhci_hcd: probe of 0000:01:00.0 failed with error -110
```

## 步骤

1. 关闭树莓派，取出 SD 卡，然后将 SD 卡插到一台电脑上。

2. 在电脑上找到 SD 卡上的启动分区（一般是第一个分区，大小 600 MiB），然后编辑文件 `config.txt`，添加下面一行：

   ```
   total_mem=3072
   ```

3. 保存文件，安全弹出 SD 卡，插回树莓派上，然后通电开机。

只需要改这一个文件，加这么一行，就可以解决 USB 接口不能用的问题了。再运行 `dmesg | grep xhci_hcd`，不应再出现同样的错误信息了。插入的 USB 设备也可以识别并正常使用了。

熟悉英语的朋友应该能注意到，`total_mem=3072` 这个选项本身的意思无非就是将内存限制到 3072 MB。也许对于很多人来说，因为在树莓派上跑的东西的内存开销不大，3 GiB 的内存也绰绰有余，所以即使有限制也无所谓；但是，如果 3 GiB 内存对您不够用的话，就只能使用我的[另一篇帖子](/2020/09/21/raspi4-fedora-usb-complex.html)里的更复杂的方法了，步骤更多，但不会减少可用内存容量。

## 参考资料

这个方法是我从 [Ubuntu 的一个 bug 报告](https://bugs.launchpad.net/ubuntu/+source/linux-raspi2/+bug/1848790)里提到的解决方法中受启发得来的。这个 bug 报告里说是在 `usercfg.txt` 里加 `total_mem=3072` 选项，我在 Fedora 上试了一下，不管用。好在在 `config.txt` 里加上这个选项也能解决这个问题，效果是一样的。
