{%- from 'zoomdata/map.jinja' import zoomdata with context -%}

{%- set pkg_function = 'installed' %}
{%- if zoomdata.version == 'latest' %}
  {%- set pkg_function = zoomdata.version %}
{%- elif zoomdata.version  %}
  {%- set version = zoomdata.version %}
{%- endif %}

{%- set packages = zoomdata.packages|default([], true) -%}
{%- set services = zoomdata.services|default([], true) -%}


include:
  - zoomdata.repo

zoomdata-pkgs:
  pkg.{{ pkg_function }}:
    - pkgs: {{ packages }}
    {%- if version is defined %}
    - version: {{ version }}
    {%- endif %}
    - refresh: True
    - skip_verify: True
    - require:
      - pkgrepo: zoomdata-repo

{%- for service, config in zoomdata.config|dictsort() %}

{{ service }}-config:
  file.managed:
    - name: {{ config.path }}
    - user: {{ zoomdata.user }}
    - group: {{ zoomdata.group }}
    - mode: 640
    - makedirs: True
    - contents:
  {%- for k, v in config.properties|dictsort() %}
      - {{ (k, v)|join('=')|indent(8) }}
  {%- endfor %}
    - require:
      - pkg: zoomdata-pkgs
  {%- if service in services %}
    - watch_in:
      - service: {{ service }}-service
  {%- endif %}

{%- endfor %}

{%- for service in packages %}

  {%- set service_function = 'running' %}
  {%- set service_requisite = 'watch' %}

  {%- if service not in services %}
    {%- set service_function = 'dead' %}
    {%- set service_requisite = 'require' %}
  {%- endif %}

{{ service }}-service:
  service.{{ service_function }}:
    - name: {{ service }}
    - enable: True
    - {{ service_requisite }}:
      - pkg: zoomdata-pkgs

{%- endfor %}
