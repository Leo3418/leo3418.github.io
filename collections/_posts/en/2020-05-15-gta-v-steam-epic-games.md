---
title: "Share GTA V Game Files Between Steam and Epic Games"
lang: en
tags:
  - GTA Online
categories:
  - Tutorial
toc: true
last_modified_at: 2020-12-27
---
{% include img-path.liquid %}
After Epic Games announced that it would give away free copies of GTA V for a
week, many people started to claim this gift on that game platform. Even some
existing GTA V players who have already purchased the game on Steam had decided
to get another free copy so they could have two or more GTA Online accounts.

It appears that if you have already installed GTA V via Steam, you still need
to download a full copy of the game files via Epic Games. However, by doing
some tricks, you can let Steam and Epic Games share the same set of GTA V game
files to avoid downloading the game again and thus save disk space. We will use
the `MKLINK` command on Windows, which is not well-known, to create a link to
the existing game files. The link works as if the linked files and folders are
exactly there, but it occupies very little space.

Because I believe almost all people who want to let the apps of these two game
platforms share the same game files have already downloaded GTA V from Steam
rather than Epic Games, the following instructions will create a link to
Steam's copy of GTA V files under Epic Games' installation path.

## Steps

1.  Download GTA V in Epic Games.

    ![]({{ img_path }}/01-1-download-gta-v-in-epic-games.png)

    You will be prompted to choose an installation path. Select whichever path
    you want to use, and remember it.

    ![]({{ img_path }}/01-2-choose-path.png)

2.  Then, immediately pause download.

    ![]({{ img_path }}/02-pause-download.png)

3.  Quit Epic Games Launcher. Ignore the warning about cancelling installation.

    ![]({{ img_path }}/03-quit-epic-games.png)

4.  Go to the GTA V installation path set in step 1, and move the `.egstore`
    folder to somewhere else. In this demo, I moved it to the parent folder.

    ![]({{ img_path }}/04-move-egstore.png)

5.  Then, delete the `GTAV` folder.

    ![]({{ img_path }}/05-delete-epic-games-gtav-folder.png)

6.  Find out where Steam stored GTA V game files. Open up game properties for
    GTA V in Steam, click on "Browse Local Files" under the "Local Files" tab,
    and remember the path shown in the file explorer. You may click on the
    address bar to copy the full path.

    ![]({{ img_path }}/06-1-steam-game-properties.png)

    ![]({{ img_path }}/06-2-steam-gta-v-files.png)

7.  Copy `GTA5.exe` and `PlayGTAV.exe` in Steam's GTA V installation to
    somewhere else, and clearly label them as game files downloaded from
    *Steam*.  For example, I would put those files in a folder with name
    `Steam`.

    ![]({{ img_path }}/07-copy-executables.png)

8.  Start command prompt as administrator.

    ![]({{ img_path }}/08-start-cmd.png)

9.  Run command `mklink /D "<Epic Games Path>" "<Steam Path>"` to create a link
    to Steam's game files for Epic Games. Fill in the paths with values you got
    in step 1 and step 6 respectively. Remember to wrap the values in double
    quotes.

    ![]({{ img_path }}/09-1-mklink.png)

    After running the command, you should see the link created in Epic Games'
    game installation path.

    ![]({{ img_path }}/09-2-link-created.png)

10. Move the `.egstore` folder in step 4 back into `GTAV`.

    ![]({{ img_path }}/10-restore-egstore.png)

11. Start Epic Games Launcher. If the download progress is paused, resume it
    manually. Then, you should see it verifying files for GTA V, which
    indicates success! Wait until it completes.

    ![]({{ img_path }}/11-epic-games-verifies.png)

12. Once GTA V is ready to play from Epic Games, visit the folder storing GTA V
    game files again, copy `GTA5.exe` and `PlayGTAV.exe` similarly as in step
    7, but label them as game files downloaded from *Epic Games* this time.

    ![]({{ img_path }}/12-two-copies-of-executables.png)

In the future, if you want to launch GTA V via Steam, make sure the executables
you copied in step 7, which are the ones you labeled *Steam*, are in the GTA V
game files folder. If you want to launch it via Epic Games, then you should put
the files copied in step 12, labeled *Epic Games* by you, back to the game
files folder. These two files, `GTA5.exe` and `PlayGTAV.exe`, are the only two
critical files that differ between the copies of GTA V downloaded from Steam
and Epic Games.

## Sign Out Your Old Social Club Account!

I've heard from some people who have been already playing this game using the
copy downloaded from Steam saying that, when they launched GTA V through Epic
Games Launcher, the new copy of the game was activated for their original
Social Club account, so they failed to make a brand new account for GTA Online.
If you want to have a new Social Club account and activate the copy of GTA V
you obtained on Epic Games for it, make sure you sign out your old Social Club
account from Rockstar Games Launcher.

## Steps to Do Upon Game Update

If an update for GTA V is available after you have used the above steps to
share the game files, then please perform the following steps for the new
update:

1.  Update GTA V from one game platform (either Steam or Epic Games). We will
    denote this platform as *Platform A*.

2.  Copy `GTA5.exe` and `PlayGTAV.exe` under the game's installation path to
    somewhere else, and clearly label them as game files downloaded from
    *Platform A*.

3.  Next, update GTA V from the other platform, which will be denoted as
    *Platform B*.

4.  Again, copy `GTA5.exe` and `PlayGTAV.exe` under the game's installation
    path to somewhere else, but label them as game files downloaded from
    *Platform B* this time.

Now, you should be able to launch GTA V and switch between Steam and Epic Games
back and forth again as before.
