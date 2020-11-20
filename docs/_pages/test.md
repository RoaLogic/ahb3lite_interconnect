---
title: Test & Debug
permalink: /test/
---
# {{page.title}}

## GitHub Metadata Test

Owner: {{site.github.owner_name}}

Public Repos:
{% for repository in site.github.public_repositories %}
  * [{{ repository.name }}]({{ repository.html_url }})
{% endfor %}

---
