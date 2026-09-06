---
title: "Resolve `git am` Merge Conflicts"
categories:
- Tutorial
tags:
- Git
toc: true
---

**TL;DR:** After `git am` encounters a merge conflict, the output of `git
status` and the working tree's state do not show any sign of conflict like a
`git pull`, `git merge`, or `git rebase` conflict does, which can be very
confusing.  To get an experience that is at least somewhat similar to those
other Git commands, use `git am --reject`.

## Problem

When `git am` is used to apply patches and encounters a merge conflict, it will
print a message like this:

```
Applying: hello, world and foobar
error: patch failed: hello.txt:1
error: hello.txt: patch does not apply
Patch failed at 0001 hello, world and foobar
hint: Use 'git am --show-current-patch=diff' to see the failed patch
hint: When you have resolved this problem, run "git am --continue".
hint: If you prefer to skip this patch, run "git am --skip" instead.
hint: To restore the original branch and stop patching, run "git am --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
```

Perhaps most Git users have encountered merge conflicts with `git pull`,
`git merge`, `git rebase`, and so on.  With these Git commands, the user can
run `git status` to see the names of the conflicting files.

With `git am`, however, `git status` does not print any filenames or any other
useful information about the conflict, which is not very helpful:

```
On branch master
You are in the middle of an am session.
  (fix conflicts and then run "git am --continue")
  (use "git am --skip" to skip this patch)
  (use "git am --abort" to restore the original branch)

nothing to commit, working tree clean
```

When users open the conflicting files (by finding them on their own), they will
not find any conflict markers, i.e.,`<<<<<<<`, `=======`,  and `>>>>>>>`.
Instead, they will see the files clean in their pre-merge states.  After all,
the `git status` output says "working tree clean" too.

## Example

Suppose there is a Git repository with two commits, as demonstrated by the
patch below.  The first commit (`f0c7480`) creates a file `hello.txt` with
one line of text `hello` and another file `foobar.txt` with text `foo`.  The
second commit (`882b2a9`) adds a line `git` below that line in `hello.txt`.

{{< patch.inline "example-repo.patch" >}}
{{- highlight (partial "static-path.html" (dict
    "page" .Page
    "type" "res"
    "file" (.Get 0)
) | printf "static%s" | readFile) "patch" -}}
{{< /patch.inline >}}

Readers may follow this example by creating the same repository setup with
these commands:
```console
$ git init test
$ cd test
$ curl {{< static-path res example-repo.patch abs >}} | git am
```

Now, the following patch is to be applied.  It contains a commit whose parent
is the repository's first commit (`f0c7480`).  It adds a line `world` below
`hello` in `hello.txt`, and `bar` below `foo` in `foobar.txt`.  The change to
`hello.txt` leads to a conflict with the second commit already checked into the
repository (`882b2a9`) because both commits modify the same position in the
file in different ways.

{{< patch.inline "incoming.patch" />}}

Readers may run this command in the repository to reproduce the conflict:
```console
$ curl {{< static-path res incoming.patch abs >}} | git am
```

After witnessing it, readers can restore to the previous repository state:
```console
$ git am --abort
```

## Solution

When using `git am` to apply patches, add the `--reject` option to the command,
such as:
```console
$ curl {{< static-path res incoming.patch abs >}} | git am --reject
```

This lets `git am` still apply those changes from the patch that can be applied
without a conflict, making the behavior of `git am` the same as that of `git
pull`, `git merge`, `git rebase`, etc in this aspect.  Conflicting changes will
be saved to `*.rej` files, unlike those other commands.

With `git am --reject`, `git status` will show applied changes as "Changes not
staged for commit" and list the `*.rej` files as untracked files.  With the
above example, the change to `foobar.txt` in the commit `769c420` in the patch
can be applied because no other commits make a change at the same place, so it
shows up as a change not staged for commit.  `hello.txt.rej` file will be
produced because of the merge conflict.
```
On branch master
You are in the middle of an am session.
  (fix conflicts and then run "git am --continue")
  (use "git am --skip" to skip this patch)
  (use "git am --abort" to restore the original branch)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   foobar.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	hello.txt.rej

no changes added to commit (use "git add" and/or "git commit -a")
```

Now, to resolve the conflict:
1. Manually edit the conflicting files to apply the patch's changes.
2. Delete the `*.rej` files.
3. Use `git add <file>...` to mark resolution.
4. Run `git am --continue` to continue.

This experience is similar to the typical conflict resolution experience with
`git pull`, `git merge`, `git rebase` and so on, except that the users find the
conflicting changes in `*.rej` files instead of in the files being changed
themselves, and they should remove the `*.rej` files manually after resolving
the conflicts.

## Extras

Look at how Google Search's AI Overview could get this very wrong...  The truth
is, with `git am`, the conflict markers will not be in the conflicting files at
all.

![Google Search's AI Overview displaying incorrect information]({{< static-path img google-ai-overview.png >}})
