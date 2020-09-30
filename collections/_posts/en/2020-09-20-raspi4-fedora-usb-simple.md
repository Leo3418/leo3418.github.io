---
title: "USB Issue on Raspberry Pi 4 Running Fedora - Simple Solution"
lang: en
tags:
  - Raspberry Pi
  - Fedora
categories:
  - Tutorial
toc: true
---

When Fedora runs on Raspberry Pi 4B 4GB/8GB RAM models, the USB ports might not
be working out-of-box as of Fedora 32 and Linux kernel 5.8. In this post, I
will introduce a very simple solution to this problem that only requires you to
add one line to a configuration file.

## Notes and Caveats

- If you are using the 2GB model, then rest assured - the USB ports should work
  out-of-box, and you do not need to do anything. This issue exists only on the
  4GB and 8GB models.

- This method will **limit the amount of RAM available to the operating system
  to 3 GiB**. If this will affect your workloads, please consider using a [more
  complex solution](/2020/09/21/raspi4-fedora-usb-complex.html) that requires
  more steps but does not decrease the amount of available RAM.

## Symptoms

The USB ports of your Raspberry Pi are working on other operating systems,
including Raspberry Pi OS, but they fail on Fedora. The `dmesg | grep xhci_hcd`
command gives you the following messages:

```console
$ dmesg | grep xhci_hcd
[   19.961404] xhci_hcd 0000:01:00.0: xHCI Host Controller
[   19.974551] xhci_hcd 0000:01:00.0: new USB bus registered, assigned bus number 1
[   29.988717] xhci_hcd 0000:01:00.0: can't setup: -110
[   30.000126] xhci_hcd 0000:01:00.0: USB bus 1 deregistered
[   30.021077] xhci_hcd 0000:01:00.0: init 0000:01:00.0 fail, -110
[   30.033104] xhci_hcd: probe of 0000:01:00.0 failed with error -110
```

## Steps

1. Turn off your Raspberry Pi and remove the SD card, then insert the card into
   a computer.

2. On the computer, open up your SD card's boot partition (which should be the
   first partition with size of 600 MiB), then edit `config.txt`. Add the
   following line to the file:

   ```
   total_mem=3072
   ```

3. Save the file and safely eject the SD card. Insert it back into the
   Raspberry Pi and boot it up.

And that's it; this method is as simple as that. Try running `dmesg | grep
xhci_hcd` again, and the error messages should disappear. Insert a USB device,
it should start to work.

As suggested by the option name itself, `total_mem=3072` limits the memory to
3072 MiB. Depending on how you use your Raspberry Pi, this amount of memory
might be more than enough; but, if you do need more memory than that, and you
want to use USB devices on Raspberry Pi, please use another solution I
introduce in [a separate post](/2020/09/21/raspi4-fedora-usb-complex.html),
which takes more steps but does not decrease available memory.

## References

This solution was adapted from [a bug ticket for
Ubuntu](https://bugs.launchpad.net/ubuntu/+source/linux-raspi2/+bug/1848790).
In the solution posted there, the line is added to another file `usercfg.txt`.
I have tried it, and it did not work for Fedora. Nevertheless, adding the line
to `config.txt` works and should have the same effect.
