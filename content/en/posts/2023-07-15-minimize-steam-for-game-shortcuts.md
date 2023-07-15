---
title: "Minimize Steam When Launching a Game Shortcut on Windows"
categories:
  - Tutorial
toc: true
---

The recent Steam client major update has brought predominant user interface
changes as well as a regression in user experience: if the Steam client is not
running, and the user launches a Steam game from its desktop or Start menu
shortcut, then the Steam client window will show up before the game launches;
prior to the update, Steam would start minimized in this case, thus the window
would not show up on its own.

This behavior is very disruptive to users who like to launch Steam games from
their shortcuts instead of in the Steam client and do not want to start Steam
when the system boots -- they now have to manually close the Steam client
window after launching a game if they do not want to keep the window open.

This article introduces a solution that effectively reverts this behavior
change for the new Steam client on Microsoft Windows.  To summarize, the
solution involves modification to the Windows Registry that alters the Steam
client launch options for game shortcuts.

## Requirements

- This article's instructions only apply to Microsoft Windows.

- The Steam client must have been launched at least once before following this
  article's instructions.

## Modify Registry

### Launch Registry Editor

Open up the *Run* dialog box (which can be done by pressing Windows key+R),
type `regedit`, and press Enter.

![Launching Registry Editor from the Run dialog box]({{< static-path img
01-regedit-launch.png l10n >}})

If the *User Account Control* dialog box shows up to ask for confirmation or
administrator password, choose "Yes" or enter the password.

![User Account Control dialog box when launching Registry Editor]({{<
static-path img 02-uac.png l10n >}})

### Change Registry Value

In Registry Editor, navigate to path
`HKEY_CLASSES_ROOT\steam\Shell\Open\Command`.

![The registry value to change in Registry Editor]({{< static-path img
03-reg-original.png l10n >}})

Registry Editor should only show a `(Default)` value under this path.  Edit it
(which can be done by double clicking the value's entry), and add `-silent`
with a trailing space in front of the double hyphens (`--`).  For example:

```diff
- "C:\Program Files (x86)\Steam\steam.exe" -- "%1"
+ "C:\Program Files (x86)\Steam\steam.exe" -silent -- "%1"
```

![Edit the registry value]({{< static-path img 04-reg-edit-value.png l10n >}})

**Explanation:** The `HKEY_CLASSES_ROOT\steam\Shell\Open\Command` registry path
stores the program and program arguments that Windows should use to open
`steam://` URLs.  Since each Steam game shortcut uses a `steam://` URL to
specify that it launches a Steam game (e.g. the shortcut for *Portal* has URL
`steam://rungameid/400` as shown below), modifying the value under the said
registry path affects how Windows opens Steam game shortcuts.  The added
[`-silent` option][steam-launch-options] lets Steam start minimized to the
system tray.  Therefore, when a Steam game shortcut is launched, Steam starts
with the `-silent` option, hence minimized.

![The shortcut to Portal that Steam creates]({{< static-path img
steam-game-shortcut.png l10n >}})

[steam-launch-options]: https://help.steampowered.com/en/faqs/view/0188-6BB7-D467-08E1

## Prevent Steam from Overwriting Registry

Unfortunately, the Steam client may overwrite the changed registry value and
restore it to default.  To prevent this, modify the registry value's permission
to block Steam client's changes to it.

1. Open permission settings for `HKEY_CLASSES_ROOT\steam\Shell\Open\Command`,
   which can be done by right-clicking on the said path's entry in the
   navigation pane and then selecting "Permissions" in the menu.

   ![Opening permission settings from the navigation pane]({{< static-path img
   05-perm-menu.png l10n >}})

2. Click the "Advanced" button.

   ![The "Advanced" button in the permission settings window]({{< static-path
   img 06-perm-advanced.png l10n >}})

3. The *Advanced Security Settings* window will show up.  Click the "Disable
   inheritance" button in it.

   ![The "Disable inheritance" button in the Advanced Security Settings
   window]({{< static-path img 07-perm-disable-inherit.png l10n >}})

4. Select "Convert inherited permissions into explicit permissions on this
   object" in the *Block Inheritance* dialog box.

   ![The Block Inheritance dialog box]({{< static-path img 08-perm-convert.png
   l10n >}})

5. In the *Advanced Security Settings* window, select the current user account
   under *permission entries*, then click the "Edit" button.

   ![The current user being selected and the "Edit" button in the Advanced
   Security Settings window]({{< static-path img 09-perm-edit.png l10n >}})

6. The *Permission Entry* window will show up.  Click "Show advanced
   permissions".

   ![The "Show advanced permissions" option in the Permission Entry window]({{<
   static-path img 10-perm-show-advanced.png l10n >}})

7. Deselect "Set Value" in *advanced permissions*, then click the "OK" button
   to close the *Permission Entry* window.

   ![Deselecting "Set Value" in advanced permissions]({{< static-path img
   11-perm-no-set-value.png l10n >}})

8. Click the "OK" button to close the *Advanced Security Settings* window.

   ![Closing the Advanced Security Settings window]({{< static-path img
   12-perm-close.png l10n >}})

**Explanation:** After the above permission change, the current user account no
longer has the privilege to change registry values under the registry path in
question.  Because Steam is typically run as current user (rather than
administrator), Steam does not have the privilege to change those registry
values either.  However, the current user account can still modify those
registry values via Registry Editor since Registry Editor is always run as
administrator, and the administrator account's permission is unchanged and thus
remains at full.

## Honorable Mentions of Alternative Solutions

Before coming up with this solution, I searched online for existing solutions
to the user experience issue in question, but none of the solutions I could
find were perfect.

### Start Steam on Boot

Letting Steam start when the system boots helps mitigate this issue but with
limitations.

When Steam starts on boot, it automatically minimizes itself (the initial
public release of the new client would show the client window when started on
boot, but a later update has fixed this); launching a Steam game shortcut when
the Steam client is running minimized will not cause the client window to show
up.

The limitations of this solution are:

- It forces users to let Steam start on boot, even if some of them do not want
  to.  After all, not everyone uses their computer only to play games.  When
  the user does not plan to play any Steam games, starting the Steam client in
  the background when the system boots does no good and only wastes system
  resources.

  - It would increase the time that the operating system takes to completely
    start up as well as the time taken to power off if the user has not
    manually closed Steam before shutting down the system.

  - The Steam client unnecessary consumes memory when it is running in the
    background.

- If the user closes Steam and then launches a Steam game shortcut, the client
  window will still show up.

### Modify Every Game Shortcut's URL

The registry modification that this article describes is a global fix, which
works for every Steam game shortcut, existing or created later.  Alternatively,
the `-silent` Steam client launch option can be set for each shortcut
individually by adding `" -silent` (i.e. a double quote, a space, followed by
`-silent`) to the end of the shortcut's URL, such as:

```diff
- steam://rungameid/400
+ steam://rungameid/400" -silent
```

![Modifying a Steam game shortcut to let Steam start minimized]({{< static-path
img modify-game-shortcut.png l10n >}})

This solution is not viable for people who have a lot of Steam game shortcuts
or in the long term since it requires repeating the modification for every
existing shortcut as well as new shortcut created in the future.
