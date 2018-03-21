{%- from 'zoomdata/map.jinja' import zoomdata -%}

{%- if 'tools' in zoomdata.repositories|default([], true) -%}

include:
  - zoomdata.repo

  {%- if zoomdata.tools.packages|default([]) %}

zoomdata-tools:
  pkg.installed:
    - pkgs: {{ zoomdata.tools.packages }}
    - version: {{ zoomdata.tools.version|default(none, true) }}
    - skip_verify: {{ zoomdata.gpgkey|default(none, true) is none }}
    - require:
      - sls: zoomdata.repo
    
  {%- endif %}

{%- endif %}
