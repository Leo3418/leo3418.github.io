---
title: "Firewall Rule on PC"
ordinal: 414
level: 4
lang: en
---
{% include img-path.liquid %}

The method to make a Solo Public Session by right-clicking on the title bar
introduced in the [last
article](solo-public-sessions#right-clicking-on-the-title-bar) cannot
completely prevent other players from joining your session. I am going to
introduce another method on PC that typically guarantees no one can join your
session, which uses the firewall in your operating system to block peer-to-peer
connections between you and other players.

## Effects

- No players can join the session you are currently in at all (with only one
  known exception explained in the "Limitations" section below).

- When you join a Public Session, you will always find yourself being the only
  player in the session.

## Limitations

- You cannot join other players' sessions either. This will prevent you from
  entering multiplayer Jobs, such as Heists.

- Players who are in your Local Area Network (LAN) might still be able to join
  your session. If you are playing at home, unless there's anyone in your
  family who will grief your goods, this should not be a problem; if you play
  in a public network, such as your school's Wi-Fi, then please keep this
  limitation in mind.

## Recommended Use Cases

- You need a Solo Public Session for a long time, like when you are trying to
  grind a full large Warehouse of Special Cargo.

- You want to grind with your friends together in a Public Session that only
  contains yourselves. See the "Advanced Usage" section below for details.

## Method

### Configuring the Firewall Rule

The following steps configure a firewall rule that blocks connections between
players on Windows 10.

1.  Open Windows Defender Firewall with Advanced Security. You may find it by
    searching "firewall".

    ![Searching "firewall"]({{ img_path_l10n }}/01-search.png)

2.  Select "Outbound Rules" in the leftmost view, and click on "New Rule" in
    the rightmost view.

    ![Outbound rules]({{ img_path_l10n }}/02-new-rule.png)

3.  For the rule type, choose "Custom".

    ![Choose rule type]({{ img_path_l10n }}/03-type.png)

4.  For programs, choose "All programs".

    ![Choose programs]({{ img_path_l10n }}/04-programs.png)

5.  For protocol and ports, configure as the following:
    - Protocol type: UDP
    - Local port: Specific Ports, 6672
    - Remote port: All Ports

    ![Choose protocol and ports]({{ img_path_l10n }}/05-protocol-and-ports.png)

6.  For the scope, make sure "Any IP address" is selected for both options.

    ![Choose scope]({{ img_path_l10n }}/06-scope.png)

7.  For the action, choose "Block the connection".

    ![Choose action]({{ img_path_l10n }}/07-action.png)

8.  For the profile, make sure every checkbox is selected.

    ![Choose profile]({{ img_path_l10n }}/08-profile.png)

9.  Give any name and description you like for the firewall rule.

    ![Give a name]({{ img_path_l10n }}/09-name.png)

10. The rule should be added and enabled.

    ![The rule has been created]({{ img_path_l10n }}/10-created.png)

### Toggling the Firewall Rule

When the firewall rule is enabled, you cannot join other people's sessions or
Jobs. If you want to join one later, you need to disable the rule by clicking
on "Disable Rule" in the above screenshot.

If you need a safe Solo Public Session later, you can enable it again at the
same place. This ensures no new players can join your session but does not
guarantee that players already in your session will "leave". If this happens,
you just need to do the right-click on title bar method, or find a new session.

## Advanced Usage

At the moment when you enable the firewall rule, it will start blocking new
connections that match the rule you have set, but it looks like it won't cut
off any existing connections, even if they meet the criteria. This explains why
enabling the rule when you are already in a session does not "kick" other
players, but new players can't join.

Exploiting this behavior of the Windows Defender Firewall effectively allows
you to use the firewall rule as a lock of your session that limits the players
to the ones who have already joined. So, you can grind with your friends
without disturbance.

### Steps

1. Make a Solo Public Session.

2. Make sure the firewall rule is disabled, and invite anyone you want to play
   with to the session.

3. After everyone is in, enable the firewall rule immediately to lock the
   session.

### Limitations

- If anyone in your session leaves and wants to come back, you need to disable
  the firewall rule to let them rejoin, and enable it again after they have
  spawned.

- If some other friend wants to join your session when it is locked in this
  way, you need to disable the rule to let them join as well, and re-enable it
  afterwards.

- If and only if you are the only one who has the firewall rule enabled, other
  people will be able to join the session once you leave. Players who are still
  in the session after you left should be aware of this.
