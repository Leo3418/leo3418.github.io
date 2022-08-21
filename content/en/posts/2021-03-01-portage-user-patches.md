---
title: "A Patchy System -- Applying Patches with Portage to Fix Upstream Bugs"
tags:
  - Gentoo
  - GNU/Linux
categories:
  - Blog
toc: true
lastmod: 2021-03-01
---

For many free software projects, there is usually some delay between the
initial annoucement of a bug fix or an enhancement and the moment when you
finally get the software update that ships it.  As a user, you need to wait for
the patch to get reviewed and accepted by the project, wait for the change to
be tested and integrated, wait for the new version containing the change to be
released by the upstream, and finally, wait for your distribution to ship the
new release.  Suppose there is a bug fix that will be included in the upcoming
GNOME 40 release, which will probably be available in March 2021.  If you are
using Fedora Workstation, you must wait until the end of April to get that bug
fix with Fedora 34.  For Gentoo users, I would not expect the arrival of that
bug fix until the second half of this year, because all recent GNOME updates
took about half a year to land in Gentoo.

It sounds like all you can do as an end user boils down to these four letters:
W, A, I, T.  And the wait can last for months.  If the bug fix you are waiting
for addresses a crucial issue that seriously degrades your system's
functionality, you probably cannot afford the waiting time.

But, if you use Gentoo, the most famous source-based GNU/Linux distribution
where almost all packages are shipped in their original source code and the
users need to build them on their own, then you can apply those patches to the
source code when building and installing the package, and have the bug resolved
on your system even before the upstream version containing the bug fix becomes
available in Gentoo's software repository.  Thanks to Portage's [user
patch][user-patch] support, applying changes to a program's source code is very
easy and hassle-free.

When I was doing my regular weekly system update on my Gentoo system last
Friday, I got issues with three different packages in a single upgrade!  All of
those issues already had a patch that actually could successfully fix the issue
from the developers, but for the reasons mentioned above, it would take weeks
or even months for me to get new upstream releases containing the fixes.  In
this article, I will use those three issues as examples to demonstrate applying
those patches with Portage, so you no longer need to pray that your
distribution can ship the new upstream releases in time.

[user-patch]: https://wiki.gentoo.org/wiki//etc/portage/patches

## Failing `systemd-rfkill` Unit

- Affected Software: [`sys-apps/systemd`][systemd-gentoo]
- Bug Ticket: <https://github.com/systemd/systemd/issues/18677>
- Proposed Fix: <https://github.com/systemd/systemd/pull/18679>

This issue had probably been in my system for a while, but I had never noticed
it until systemd was upgraded from 246 to 247, because I caught a failed
systemd unit in the systemd boot log.  The failing unit was
`systemd-rfkill.service`:

![systemd-rfkill.service status on Linux 5.11]({{< static-path img rfkill-5.11.png >}})

I tried to roll back to systemd 246 but was still getting the same issue, so it
was probably not a regression in systemd but caused by other related components
that had been changed recently.  I thought about the kernel, because I had just
switched from 5.10 to 5.11.  Since I was keeping an old kernel from the Linux
5.10 series, I decided to boot up the system using Linux 5.10.17 and
systemd 247.  `systemd-rfkill.service` would no longer fail, but when I looked
at its status, there were still some error messages, which was why the issue
might have been there for a while but did not catch my attention.

![systemd-rfkill.service status on Linux 5.10]({{< static-path img rfkill-5.10.png >}})

I searched the error messages online and found the GitHub issue linked above,
which looked like the exact same issue I was getting.  Luckily though, a merged
pull request was associated with the issue, so I decided to try out the patch
contained in the pull request in the hope to fix this problem.

How could I get a patch out of a GitHub pull request?  As luck would have it, a
tip giving the exact answer to this question was shown at the bottom of the
page, which was to append `.patch` to the end of the pull request's URL:

![Tip for getting a patch from a GitHub pull
request]({{< static-path img github-pr-to-patch.jpg >}})

```diff
- https://github.com/systemd/systemd/pull/18679
+ https://github.com/systemd/systemd/pull/18679.patch
```

The patch for the `sys-apps/systemd` package should be put under
`/etc/portage/patches/sys-apps/systemd`.  Optionally, you can also indicate
that the patch should only be applied to systemd 247 by [adding a version
specifier][patch-specific-ver] to the directory name.  Because this patch is
compatible with both systemd 246 and 247, I did not add the version suffix.
However, this means I will need to delete this patch when a new upstream
release of systemd with this patch already applied is available in Gentoo's
software repository.

{{< asciicast poster="data:text/plain,Add user patch from command-line" >}}
{{< static-path res portage-add-patch.cast >}}
{{< /asciicast >}}

After the patch has been placed under the correct directory, the package needs
to be rebuilt so the patch can be applied:

```console
# emerge --ask --oneshot sys-apps/systemd
```

Look for the "User patches applied" message in the output of `emerge`, which
indicates that the patch was successfully applied:

{{< asciicast poster=`data:text/plain,Rebuild the package

Note: I used the '--quiet' option to truncate screen output,
which is completely optional` >}}
{{< static-path res emerge-patch-applied.cast >}}
{{< /asciicast >}}

After I finished up rebuilding systemd, I restarted my system, and
`systemd-rfkill.service` could start normally without any kinds of errors.

[systemd-gentoo]: https://packages.gentoo.org/packages/sys-apps/systemd
[patch-specific-ver]: https://wiki.gentoo.org/wiki//etc/portage/patches#Adding_user_patches

## 2-Minute Power Off Delay with GNOME and systemd User Units

- Affected Software: [`gnome-base/gnome-session`][gnome-session-gentoo]
- Bug Ticket: <https://gitlab.gnome.org/GNOME/gnome-session/-/issues/74>
- Proposed Fix: <https://gitlab.gnome.org/GNOME/gnome-session/-/merge_requests/55>

The unit that failed during system start-up did not cause observable degrade in
system functionality, so even if I could not resolve it, I could still live
with it.  But another problem emerged in the shut down process: the system
would spend 2 minutes waiting for a stop job to complete.  The job would never
finish in the time allotted, effectively adding a two-minute delay to the power
off process.  This was an issue that could significantly affect my workflow, so
it must be resolved in some way.

![The system hangs at a stop job during shut
down]({{< static-path img poweroff-delay.jpg >}})
{.half}

Unlike the failing unit issue which was not a regression in systemd, this power
off delay did not happen after I rolled back to systemd 246, so it was very
likely that systemd 247 had something to do with it.  Therefore, I did another
search with query *"systemd 247 a stop job is running for user manager for
uid"* and found the issue on GNOME GitLab linked above.  The discussion in that
ticket suggested that the problem would occur to GNOME users who run a [systemd
user unit][systemd-user-unit] and was caused by a behavior change in systemd
247, though the issue's fix was done in GNOME rather than systemd.

And there was a merge request (GitLab's synonym for GitHub's pull request)
related to the issue too.  GitLab makes the feature for downloading the patch
for a merge request more discoverable by putting a download button onto the web
page.  Both "Email patches" and "Plain diff" are accepted by Portage as a legal
user patch, but I would prefer the email patch because it contains the Git
commit message for the merge request, which can help you recall what the patch
does after you have forgotten about it in the future.

![Downloading the patch for a GitLab merge
request]({{< static-path img gitlab-mr-to-patch.png >}})

The patch can be installed with the same method introduced in the previous
section.  The first system shut down after rebuilding the
`gnome-base/gnome-session` still had the delay, but after that, the power off
process would complete smoothly without any issues.

How long would it take if I did not apply the patch through Portage myself and
decided to wait for GNOME 40 to receive the bug fix?  Well, the latest GNOME
release as of now, which is GNOME 3.38, is still not in Gentoo's software
repository yet.  The newest GNOME version Gentoo offers at this point, which is
3.36, was stabilized by the end of August 2020, about 5 months after its
availability from the upstream.  Therefore, I would not expect to get this bug
fix until at least September, which would imply that for at least the next 6
months, I would need to tolerate the 2-minute power off process of my system.

[gnome-session-gentoo]: https://packages.gentoo.org/packages/gnome-base/gnome-session
[systemd-user-unit]: https://wiki.archlinux.org/index.php/systemd/User

## Laptop with AMD Ryzen 4000 Series CPU Automatically Turning Back On After Powering Off on Linux 5.11

- Affected Software: The Linux kernel
- Bug Ticket: <https://gitlab.freedesktop.org/drm/amd/-/issues/1499>
- Proposed Fix: <https://gitlab.freedesktop.org/drm/amd/uploads/b7b5a131c5df5143cb37cc6f9b784871/0001-drm-amdgpu-fix-shutdown-with-s0ix.patch>

To be honest, if I was not able to resolve the 2-minute power off delay, I
might be able to get along with it by using the waiting time to stand up, relax
and take a break.  But the nightmare did not end here: after the system
completely shuts down and my laptop's power light goes off, it turns back on of
its own accord after a few seconds!

The symptom was reproducible only on Linux 5.11: it would not happen when I
switched back to kernel 5.10.  Again, I was able to find a bug report for a
related issue.  The reporter observed hanging shutdown process and automatic
reboots after turning off their Acer SF314-42 laptop with Ryzen 5 4500U running
Linux 5.11, although I was using an HP Envy x360 13-ay0000 with Ryzen 7 4700U,
and I saw only reboots.  Besides the kernel version, an important factor we had
in common was our CPUs, which were both from the Ryzen 4000 series laptop CPU
product line (a.k.a.  "Renoir").  The reporter also tried to find which change
included in kernel 5.11 caused the issue, and it was a Git commit for the [s0ix
support][amd-s0ix-update][^1] on AMD chips including Renoir CPUs.  Sadly, as
many users have been reporting [here][amd-s0ix-issue], the changes included in
Linux 5.11 not only failed to fix the long-existing s0ix issue on the Renoir
platform I have been facing and hoping to get resolved by Linux 5.11, but made
things even worse.

The patch linked in the bug ticket by a kernel developer worked: the shut down
behavior returned to normal when I ran a kernel with the patch applied.  s0ix
suspend support was still broken just like on Linux 5.9 and 5.10, but at least
there was no more regression after the patch, so I had nothing to complain
about except having to wait for probably 5.13 to see the next attempt for s0ix
support on Renoir.

I expect to see the patch being merged into the Linux 5.11 source tree very
soon.  So far, the patch has [appeared][patch-5.12-rc1] in the change list of
Linux 5.12-rc1.  It has not been added to 5.11 series yet, which means on
5.11.1 and 5.11.2, the issue still persists.  However, judging from the fact
that it has been merged into the RC kernel, it should be ported to the stable
kernel in very short time.

Because Gentoo provides multiple kernel packages, the exact path under which
the patch should be copied to varies depending on which specific package you
use.  I am using the [`sys-kernel/vanilla-kernel`][vanilla-kernel] package, so
the patch should be copied to `/etc/portage/patches/sys-kernel/vanilla-kernel`.
If you are using a different kernel package, you should put the patch under a
different path accordingly.  If you are using the prebuilt binary distribution
kernel [`sys-kernel/gentoo-kernel-bin`][gentoo-kernel-bin], then you have to
switch to a sourced-based package for the ability to apply user patches to the
kernel.

[^1]:
    s0ix is a new system sleep mechanism promoted by Microsoft as "[Modern
    Standby][modern-standby]".  Its aim is to let laptops sleep more like
    smartphones.

    For the past 20-25 years, laptops and many desktop PCs have been using the
    [ACPI S3 state][acpi-s3] for system standby, which turns off the CPU,
    network interface card (NIC) and other hardware, but keeps the power of RAM
    to preserve data in system memory.  This prevents a laptop from behaving
    like a smartphone, because smartphones can keep doing some tasks, like
    listening to push notifications and playing music, after they go to sleep;
    for a laptop, if its CPU and NIC are powered off, then it obviously cannot
    continue to receive notifications.  On the contrary, under s0ix state, the
    CPU will not be switched off and may just enter a low-power state instead,
    and other relevant hardware like the NIC might still be left active too,
    which allows the laptop to stay connected to the Internet and continue to
    get push notifications.

    As a standard emerged decades ago, Linux has been supporting the ACPI S3
    suspend very well.  The s0ix suspend is relatively new, and it is mainly
    developed like a Microsoft proprietary standard instead of a generic
    specification everyone knows and can use well.  Thus, Linux has been
    struggling to properly support s0ix.

    What makes things even worse is that s0ix is not compatible with S3 by
    design.  Many laptop manufacturers have joined Microsoft's Modern Standby
    campaign and been implementing s0ix on their laptop products, and due to
    the mutual exclusion between s0ix and S3, those products usually do not
    support S3 suspend at all.  This has caused very much inconvenience to
    GNU/Linux users.  Some manufacturers have been kind enough to leave an
    option that allows the user to switch between S3 and s0ix in the BIOS
    firmware, but not every OEM is doing this.  So, if you happen to get a
    laptop that implements s0ix and does not provide such an option in its
    firmware as I do, then you need to live with the immature sleep support on
    Linux.

[amd-s0ix-update]: https://www.phoronix.com/scan.php?page=news_item&px=AMD-S2idle-ACPI-Linux-5.11
[amd-s0ix-issue]: https://gitlab.freedesktop.org/drm/amd/-/issues/1230
[modern-standby]: https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby
[acpi-s3]: https://en.wikipedia.org/wiki/Advanced_Configuration_and_Power_Interface#Global_states
[patch-5.12-rc1]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=b092b19602cfd47de1eeeb3a1b03822afd86b136
[vanilla-kernel]: https://packages.gentoo.org/packages/sys-kernel/vanilla-kernel
[gentoo-kernel-bin]: https://packages.gentoo.org/packages/sys-kernel/gentoo-kernel-bin

## Summary

The last system upgrade has really introduced a lot of instability as I had to
apply additional patches to three different packages to undo the harm.
Although I am now getting a patchy system as a result, at least the bugs can be
mitigated right now, without waiting for either the upstream or the
distribution.  If I were using a normal, binary-based GNU/Linux distribution, I
would depend on my distribution's maintainers to release updates with those
patches applied to get rid of those bugs, because it would be hard for me to
incorporate my own patches into software packages provided by the distribution.
But on Gentoo, Portage's user patch feature allows me to modify programs
installed on my system through the package manager, which is very easy and
streamlined.

This post should give you a clue about how to find and download patches for
free software projects hosted at different places.  First, you might want to
pinpoint the software package and version causing the issue you are getting.
Is it in the kernel, the init system, or any other user-space program?  Could
going back to the previous version help?  Then, search for your problem online
by using the package name, problematic version, and a few words that summarize
the problem as keywords.  If it is a common issue, you should be able to find
existing bug tickets for it.  Now, you can look for any patch/{pull,merge}
request associated with the bug.  Each of the three example issues I have
covered in this post shows you how to download a patch from a GitHub pull
request, GitLab merge request, or a plain web URL to the patch itself
respectively.
