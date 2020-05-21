---
title: "Solo Public Sessions"
ordinal: 413
level: 3
lang: en
---
{% include img-path.liquid %}

Alternative types of session can keep strangers away from you. Unfortunately,
because Rockstar wants to foster PvP and other types of competition between
players, it does not allow you to grind without worries about other unfriendly
players in those sessions. So, if you want to manage your businesses, you have
to join a Public Session. Is there a way to join a Public Session with only
yourself? Luckily, there is!

This kind of session is usually known as a Solo Public Session. "Solo Public"
is not a session type, but a description that specifically refers to a Public
Session with only yourself in it.

Since the Public Session only contains yourself, you can do any kind of
missions in it without disturbance from others (at least for a while).

![A Solo Public Session]({{ img_path }}/a-solo-public-session.png)

## Limitations

- There is no effective way to completely prevent other players from joining
  your session without external networking tools. Once you have made a Solo
  Public Session, other players would not be matched into your session for a
  while. But after some time, the game might add one or a few players to the
  session. When your session has at least three players (including yourself),
  GTA Online's matching system will make its best effort to put more and more
  players into your session, and the lobby will populate very quickly.

## Recommended Use Cases

- You need to do some critical activities that must be done in a Public
  Session, such as selling goods from your businesses.

## Methods

Solo Public Sessions are not officially provided by the game; a networking
glitch is required to create a Solo Public Session.

### Mechanism

The basic mechanism of the glitch is to exploit GTA Online's behavior upon a
network disconnection. If you are disconnected briefly, GTA Online will try to
re-establish the connections to Rockstar's servers and other players. Yes,
there are direct network connections between you and other players in the same
session, as GTA Online uses peer-to-peer connections for player movements and
actions. The game also maintains a separate connection to Rockstar for player
stats, cloud saves, and transactions.

If you don't get back online until after a few seconds, then GTA Online can
reconnect you to Rockstar, but not to other players who were in the same
session. In this case, you will observe that all other players have left the
session; but the real situation was that you have left the session you were in.
GTA Online handles such disconnections in a special way: you won't receive an
alert for being disconnected but still stay in the game, so your gaming
experience is uninterrupted. The original session can keep running without
other players on your machine, hence a Solo Public Session is created.

![Making a Solo Public Session]({{ img_path }}/make-a-solo-public-session.png)

### Basic Method for Any Platform

Thanks to how GTA Online gracefully handles brief network disconnections, you
can deliberately disconnect your machine from the Internet for a short moment
to make a Solo Public Session. **Disconnect for about 10 seconds**, which is
neither too short so that the peer-to-peer connections can be re-established
nor too long to make the game think you are really offline.

For both PCs and consoles, you can unplug the cable from your router to create
a disconnection. After 10 seconds, plug it back in, and you should see things
similar to what the screenshot above shows in a moment.

For PCs, you can also unplug the cable from your computer. If you are using
Wi-Fi, you can turn it off for 10 seconds or use the Airplane Mode if your
operating system provides the functionality.

For PS4 and Xbox One, I have seen [people
saying](https://www.reddit.com/r/gtaonline/comments/4nngle/ps4_solo_public_session/)
unplugging the cable from the console itself does not work. I can't verify this
because I don't own a console, but please keep this in mind if you encounter
any failure.

Of course, reaching out to routers and cables every time when you need a Solo
Public Session might not be an optimal solution, and there are some other
platform-specific methods below.

### Methods for PCs

There are two methods I often use on PC to make a Solo Public Session:
right-clicking on the title bar, and using a firewall rule.

#### Right-clicking on the Title Bar

This is the fastest way to create a Solo Public Session, but is also subject to
the limitation mentioned above.

1. Change the game to windowed mode if it is not already windowed. If the game
   is currently in full screen, you can press Alt-Enter; or, you can adjust it
   in the game settings.

2. Hold Alt-Tab and move your cursor around to get it out of the game window.
   Right click on the window's title bar, and leave the pop-up menu open for
   about 10 seconds.

   When the menu is shown, the game's process suspends, and its network
   connections are also blocked. So, this method effectively causes a temporary
   disconnection. However, don't leave the menu there for too long, or the game
   will crash!

   ![Right click on title bar and wait for 10
   seconds]({{ img_path }}/right-click-on-title-bar.png)

3. Left click in the game window to dismiss the menu. In a moment, you should
   see other players "leaving" the session. The game might behave as if the
   right mouse button is stuck, which can be resolved with a right click.

#### Using a Firewall Rule

This method can completely block peer-to-peer connections between you and other
players. It uses a different mechanism from other methods and should also be
used differently. Because there are many details to cover, I have placed
information about this method in a [dedicated page](firewall-rule-on-pc).

### Methods for Consoles

Since I don't have a console, I cannot offer any instructions for PS4 or Xbox
One, but I'm glad to refer you to some methods shared by community members on
the [GTA Online Subreddit](https://www.reddit.com/r/gtaonline/):

- [*Solo Session Tips n'
  Tricks*](https://www.reddit.com/r/gtaonline/comments/5d2mtj/solo_session_tips_n_tricks/),
  for both Xbox One and PS4
- [The MTU method for
  PS4](https://www.reddit.com/r/gtaonline/comments/6pezoq/ps4_solo_session/dkou48w/)
- [The NAT test method for Xbox
  One](https://www.removeddit.com/r/gtaglitches/comments/7mqgf0/glitch_creating_a_solo_public_session_on_the_xbox/)

## Will I be Banned?

I have not heard of anyone who is banned for making Solo Public Sessions yet,
so I would assume it is safe to do.
