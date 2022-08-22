---
title: "Tune LUKS Parameters for Unlock Speed in GRUB"
weight: 340
---

When GRUB unlocks the LUKS partition, it is very likely that the unlock
operation takes about half a minute to complete; whereas on a normal running
operating system, the same partition may just take a few seconds to unlock.
This is because the cryptographic libraries GRUB uses for unlocking are less
efficient than `cryptsetup`.  In particular, hardware accelerations for
unlocking are generally unavailable in GRUB since it runs at a still quite
early stage of the boot process.

If such an unlock speed is unbearable, the LUKS partition's parameters can be
tuned for faster unlocks with less performance requirements and also **less
security**.

## LUKS and Argon2id Parameters' Impact on Unlock Speed

For a key whose corresponding key slot on the LUKS partition uses Argon2id as
the PBKDF, the following parameters have the most significant impact on the
unlock speed:
- Time cost for the unlock operation (i.e. number of iterations)
- Size of memory required in unlocking computation
- Number of parallel threads to use in unlocking computation

The required unlock time is directly proportional to each of time cost and
memory size, given that each of these parameters is tuned individually while
other parameters are constant.

The following parameters are known to **not** have a substantial impact on the
unlock speed:
- SHA-256 vs. SHA-512 for both a key slot's AF hash and the digest's hash
- The number of iterations for the *digest*

Each parameter's value can be found in the output of command `cryptsetup
luksDump`.  The memory size's unit is kilobytes according to the
`cryptsetup(8)` manual page.

```console {hl_lines=["26-28","32","42-44","48","55-56"]}
# cryptsetup luksDump /dev/sda2
LUKS header information
Version:       	2
Epoch:         	4
Metadata area: 	16384 [bytes]
Keyslots area: 	16744448 [bytes]
UUID:          	b8360e90-66e4-4ff5-84d1-c8e2174bf007
Label:         	(no label)
Subsystem:     	(no subsystem)
Flags:       	(no flags)

Data segments:
  0: crypt
	offset: 16777216 [bytes]
	length: (whole device)
	cipher: aes-xts-plain64
	sector: 512 [bytes]

Keyslots:
  0: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  12
	Memory:     1048576
	Threads:    4
	Salt:       61 c0 5d 29 03 43 ba 16 a2 6d fb 9c 4f 95 38 8d
	            b9 e5 eb 03 a8 cc a3 b9 c4 dd ac ae e4 62 0b b8
	AF stripes: 4000
	AF hash:    sha512
	Area offset:32768 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
  1: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  12
	Memory:     1048576
	Threads:    4
	Salt:       14 2a 04 d0 30 a7 bb 00 8a 1b 93 a1 db 47 9c 05
	            97 c5 0d 0d f5 82 30 36 75 02 ab aa 77 a6 42 3d
	AF stripes: 4000
	AF hash:    sha512
	Area offset:290816 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
Tokens:
Digests:
  0: pbkdf2
	Hash:       sha512
	Iterations: 138407
	Salt:       85 14 07 10 20 72 7b e2 0b 7a 52 d8 ed ae b6 08
	            d0 15 00 01 71 d8 3e 93 44 8e a0 56 1d 68 c0 6d
	Digest:     63 4b 4b 8f f5 3d 85 b5 81 6f 26 b2 53 f2 e0 4a
	            17 3f f9 33 7b f0 72 93 fe 39 a1 4c aa af 20 af
	            d9 c8 e6 e4 ae e5 45 c0 23 78 b5 47 e7 0f 85 f4
	            a4 96 bf e5 61 3d 2e 4d 50 2a c5 61 67 f9 a8 f0
```

If a parameter's value was not specified when the LUKS partition was
initialized or a key file was added, then it would be determined by the
`cryptsetup` program either from the compiled-in defaults or based on ad-hoc
benchmarks.  In particular, the time cost and memory size are usually
determined via benchmarking:

1. The number of threads is first fixed at 4 if the system's CPU has a
   sufficient number of CPU threads; otherwise, it is lowered accordingly.
2. The memory size is fixed at 1 GiB if the system has enough memory.
3. With these constraints set, `cryptsetup` runs the benchmark to determine the
   number of iterations that can be run within 2 seconds (the most common
   compiled-in default duration; can be overridden using the `--iter-time`
   option of `cryptsetup`).  If the result is greater than or equal to 4, then
   it will be used as the time cost.
4. If the number of iterations in the benchmark was less than 4, then
   `cryptsetup` would fix the time cost at 4 and find the memory size that
   allows the unlock operation to complete within 2 seconds (again, controlled
   by `--iter-time`).

This is not necessarily how `cryptsetup` exactly implements parameter decision,
but empirically, this is how one may predict the parameters selected by
`cryptsetup`.

Because the benchmarks were run when an operating system was fully loaded and
running normally, all factors that might help speed up the unlock operation,
including concurrency and hardware acceleration, were present.  Therefore, the
set of parameters that would yield a 2-second unlock time in this situation
could cost GRUB half a minute due to those factors' absence.

## Change the Parameters

`cryptsetup luksConvertKey` can be used to update a key slot's parameters.  If
the `--key-file` option is not included in its invocation, then `cryptsetup`
asks for the passphrase and applies the new settings to any key slot that can
be unlocked using the passphrase; otherwise, the new settings are applied to
any key slot that can be unlocked using the specified key file.

The following commands set the number of iterations (i.e. time cost) to 4 and
memory requirement to 128 MiB, which, at least on a dual core Intel Core
i5-7200U dated from 2017, allow the LUKS partition to be unlocked in about 2
seconds from GRUB and should still grant reasonable security:

```console
# cryptsetup luksConvertKey /dev/sda2 --pbkdf-force-iterations 4 --pbkdf-memory 131072
# cryptsetup luksConvertKey /dev/sda2 --pbkdf-force-iterations 4 --pbkdf-memory 131072 --key-file /etc/cryptsetup-keys.d/gentoo.key
```

These commands update the parameters for both key slots together.  Although
only the key slot associated with the passphrase is used by GRUB, for the sake
of ensuring the fastest unlock speed, the passphrase key slot's last
modification time **must be earlier than** that of the key slot associated with
the key file.  Based on my testing, GRUB seems to try out the key slots in the
order of their modification times, from oldest to newest.  So, if the
passphrase key slot's modification time is the earliest, GRUB will be able to
attempt it first; otherwise, GRUB would waste time trying the incorrect key
slot.

Even though achieving a faster unlock speed in GRUB does not require tuning
down the parameters of the key slot for the key file since this key slot is not
intended for GRUB at all, keeping its parameters in sync with the passphrase
key slot does not worsen the LUKS partition's security and may even expedite
systemd's automatic unlock.  After all, as long as the key file has been
properly created and secured, its corresponding key slot is more secure than
the passphrase key slot when all parameters are identical since a key file
cannot be guessed, brute-forced or phished as easily as a passphrase.

To test the new unlock speed in GRUB, reboot the system and observe how long
GRUB takes to unlock the LUKS partition after the passphrase is supplied.  If
the new unlock speed is faster than desired, then these parameters can be tuned
up to enhance security.  Remember, the unlock time is directly proportional to
each parameter independently.

If the new unlock speed is still quite low, here are some suggestions:

- It *might* be sensible to tune the memory size a little further down, and use
  a passphrase with high [entropy][wikipedia-entropy-info-theory] to offset the
  parameters' security impact.  Usually, the more randomized a passphrase is,
  the higher entropy it has.  Randomization here means absence of dictionary
  words, use of different characters, reasonable length, etc.  Avoid making the
  memory size *too* low: the LUKS partition might become so insecure that even
  a robust passphrase might not be able to compensate the weakened security.

- In workflows where security is pivotal, compromising security for speed is
  rarely wise or acceptable, so users would have to set the parameters to the
  minimal acceptable values to trade speed for security.

[wikipedia-entropy-info-theory]: https://en.wikipedia.org/wiki/Entropy_(information_theory)
