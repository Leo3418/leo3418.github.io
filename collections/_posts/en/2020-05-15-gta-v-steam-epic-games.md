---
title: "Share GTA V Game Files Between Steam and Epic Games"
lang: en
---
{% include img-path.liquid %}

After Epic Games announced that it would give away free copies of GTA V for a
week, many people started to claim this gift on that game platform. Even some
existing GTA V players who have already purchased the game on Steam had decided
to get another free copy so they could have two or more GTA Online accounts.

It appears that if you have already installed GTA V via Steam, you still need
to download a full copy of the game files via Epic Games. However, by doing
some tricks, you can let Epic Games and Steam share the same set of GTA V game
files to avoid downloading the game again and thus save disk space. We will use
the `MKLINK` command on Windows, which is not well-known, to create a link to
the existing game files. The link works as if the linked files and folders are
exactly there, but it occupies very little space.

Because I believe almost all people who wants to let the apps of these two game
platforms share the same game files have already downloaded GTA V from Steam
rather than Epic Games, the following instructions will create a link to
Steam's copy of GTA V files under Epic Games' installation path.

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
    and remember the path shown in the file explorer.

    ![]({{ img_path }}/06-1-steam-game-properties.png)

    ![]({{ img_path }}/06-2-steam-gta-v-files.png)

7.  Copy `GTA5.exe` and `PlayGTAV.exe` in Steam's GTA V installation to
    somewhere else, and clearly label them as game files downloaded from
    *Steam*.  For example, I would put those files in a folder with name
    `Steam`.

    ![]({{ img_path }}/07-copy-executables.png)

8.  Start command prompt as administrator.

    ![]({{ img_path }}/08-start-cmd.png)

9.  Run command `mklink /J "<Epic Games Path>" "<Steam Path>"` to create a link
    to Steam's game files for Epic Games. Fill in the paths with values you got
    in step 1 and step 6 respectively. Remember to wrap the values in double
    quotes.

    ![]({{ img_path }}/09-1-mklink.png)

    After running the command, you should see the link created in Epic Games'
    game installation path.

    ![]({{ img_path }}/09-2-link-created.png)

10. Move the `.egstore` folder in step 4 back into GTAV.

    ![]({{ img_path }}/10-restore-egstore.png)

11. Start Epic Games Launcher. You should see it verifying files for GTA V,
    which indicates success! Wait until it completes.

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
copy downloaded from Steam saying that, when they launch GTA V through Epic
Games Launcher, the new copy of the game is activated for their original Social
Club account, so they failed to make a brand new account for GTA Online. If you
want to have a new Social Club account and activate the copy of GTA V you
obtained on Epic Games for it, make sure you sign out your old Social Club
account from Rockstar Games Launcher.

## What to Do in GTA Online This Week

This week, there is a discount on Bunkers, and Bunker sales are giving double
rewards. This is a great opportunity for new players to get a head start.

The copy of GTA V you claim on Epic Games comes with the Criminal Enterprise
Starter Pack, which includes GTA$1,000,000 and the Paleto Forest Bunker.
**Don't use that Bunker!** It is too far away from Los Santos, selling Goods
from it will definitely be a torture. Instead, purchase a Bunker closer to the
city while they are on sale, such as Chumash or Farmhouse Bunker. Then, try to
get enough money to purchase the Equipment Upgrade and the Staff Upgrade on the
laptop inside your Bunker. Don't spend money on the Security Upgrade yet. You
are now ready to start profiting from your Bunker!

## One More Thing...

I guess a lot of new players will flood into GTA Online on PC starting this
week. If you are one of them, then there is some extra thing coming for you! I
have been writing a collection of GTA Online guides at the start of May. It is
planned as a very big project, and so far only about 20% of all planned
contents are finished. But I had already decided to release those guides in
several phases even before this promotion on Epic Games, and this event has
just gave me one more reason to release what I have already completed.

This weekend, I will release the first batch of articles I have written for the
collection. These articles will give an overview on what you should do to build
up your GTA Online career, how to protect yourself from other players' attacks,
and how to get some start-up cash and RP. Once released, they will be available
under the "Collections" section of this site's home page. Stay tuned!
