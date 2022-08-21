---
_build:
  list: 'local'
  render: 'link'
---

This file creates a headless section in the directory it is in.  The landing
page of a headless section will not be rendered by Hugo, but all the descendant
pages in the section will.

This file can be used to build a hierarchy of children pages for a page without
turning that parent page into a section landing page (i.e. a page whose kind is
`section`).  Because Hugo treats `section` pages differently from `page` pages,
letting the parent page have the `section` kind might not always be desirable.
To do this, create a directory structure like the following:

```
.
├── parent.md
└── parent (Directory whose name matches the parent page's URL path)
    ├── _index.md (This file)
    ├── child-1.md
    ├── child-2.md
    ├── ...
    └── child-n.md
```
