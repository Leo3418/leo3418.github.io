---
title: "{{ replace .File.ContentBaseName `-` ` ` | title }}"
url: 'collections/{{ .File.ContentBaseName }}'
---

{{- /*
To create a new collection using this archetype, please
run this command under this site's root directory:
    hugo new content collections/<collection-name>
*/}}
