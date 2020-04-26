---
title: "Restarting This Personal Site"
lang: en
---

I have been planning to repurpose my personal website on GitHub Pages as a blog
for jotting down how I play around with different technologies. When I try
something new, I usually spend some time reading tutorials, help articles, and
blog posts about it. But of course, my reading is not limited to a single
resource; instead, I often combine knowledge and steps across multiple
resources and produce something not described by any single existing webpage.
It would be very helpful if I write an article describing everything I've done,
so just in case the same task needs to be performed again, the resources I
would need could reduce from several different webpages to a single article,
which is great.

For example, in 2018, I decided to install a GNU/Linux distribution on my
laptop to ditch virtual machines. My laptop has a dedicated NVIDIA GPU, which
brought more harm than good on GNU/Linux. nouveau, the video driver shipped
with Fedora, which is the distribution I chose, consumed a lot of battery
power, so I replaced it with Bumblebee using the steps described by a Fedora
Project Wiki article. Since then, every time after the lid is closed, the
laptop would wake up immediately after it goes to sleep, with dedicated GPU,
Bluetooth, and touchpad all stopped working. I searched on the Internet for a
solution. Luckily for me, the ArchWiki has a workaround command for this issue,
but it must be run every time after the system resumes from sleep. Well, at
least the problem had been reduced to "how to run a script after system
resumes", and a Google search directed me to use `systemd-suspend.service`.
Problem solved! But before reaching this stage, I had read at least three
articles. In the future, if the driver would need to be reinstalled, then I
would have to pull out all the three webpages to recall the steps.

Creating a perfect Fedora installation on my laptop was complicated and uneasy.
There were numerous nontrivial steps, and I feared for being unable to
reproduce the original perfect installation when I would have to reinstall the
operating system; chances are I can't find all the webpages I consulted, or I
just completely forget to do a step.

The idea of writing articles that describe what I had done came to my mind.
When I need to redo something, I could just read and follow my own blog posts.
What's more, other people can benefit from what I share in the posts, too.
Ideally, they could be posted on my personal website hosted on GitHub Pages. It
was a site I started very soon after my day 1 on GitHub, in 2015. I was a high
school student then, knowing a little about HTML and CSS and almost nothing
about Markdown and Jekyll. The way I created posts on the website was to copy
an existing HTML file, rename it for the new post, and modify the HTML body
directly to include the contents. This is definitely stupid; however, it was
the only thing I could do due to my lack of knowledge. It is also tiresome and
boring, which is partly why I stopped creating new posts after making a few
webpages.

Besides, I have been playing around with many other things, including Minecraft
Forge mod development, RPM packaging, Docker, and even GTA Online. In fact, I
am planning to start a collection of GTA Online tips! As an experienced player
who has played for 2000+ hours, I see new players making common mistakes and
have a lot of things to share with the player community. Topics to write about
and inspirations keep popping up in my mind, and it is time to reconstruct my
personal site as a platform to post all these ideas.

This time, I decide to use Jekyll. Being proficient in Markdown now, there is
no reason for me to give it up and keep hardcoding my post in HTML. With site
generation from Markdown and support from GitHub Pages, Jekyll has no
competitors in serving my purpose. In addition, I wish to offer my posts in
both English and Chinese, the languages I speak, whenever appropriate. Jekyll
has multilingual plugins which free me from manually handling navigation
between different language versions of my site.

In two days, I successfully set up a multilingual Jekyll site and migrated the
posts from the old personal site. Because GitHub Pages does not support
installing new plugins, I needed to push all files required to generate a
complete Jekyll site to GitHub, build the site in a GitHub Actions environment,
and upload the generated files to the `master` branch of the repository for
this site. Now, the site you are currently viewing is online. Finally, it is
time to relax and type in the ideas I have been trying not to forget.
