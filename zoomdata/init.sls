{%- from 'zoomdata/map.jinja' import zoomdata with context -%}

{%- set func = 'installed' %}
{%- if zoomdata.version == 'latest' %}
  {%- set func = zoomdata.version %}
{%- elif zoomdata.version  %}
  {%- set version = zoomdata.version %}
{%- endif -%}


include:
  - zoomdata.repo

zoomdata-pkgs:
  pkg.{{ func }}:
    - pkgs: {{ zoomdata.services }}
    {%- if version is defined %}
    - version: {{ version }}
    {%- endif %}
    - refresh: True
    - skip_verify: True
    - watch:
      - file: zoomdata-repo

{%- for service in zoomdata.services %}

  {%- if service in zoomdata.config %}

    {%- set path = zoomdata['config'][service]['path'] %}
    {%- set prop = zoomdata['config'][service]['properties'] %}

{{ service }}-config:
  file.managed:
    - name: {{ path }}
    - user: {{ zoomdata.user }}
    - group: {{ zoomdata.group }}
    - mode: 640
    - makedirs: True
    - contents:
    {%- for k, v in prop|dictsort() %}
      - {{ (k, v)|join('=')|indent(8) }}
    {%- endfor %}
    - require:
      - pkg: zoomdata-pkgs
    - watch_in:
      - service: {{ service }}-service

  {%- endif %}

{{ service }}-service:
  service.running:
    - name: {{ service }}
    - enable: True
    - require:
      - pkg: zoomdata-pkgs

{%- endfor %}
