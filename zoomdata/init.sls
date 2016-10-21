{%- from 'zoomdata/map.jinja' import zoomdata with context %}

{%- set packages = [] %}
{%- set services = zoomdata.services|default([], true) %}

{%- for install in (zoomdata, zoomdata.get('edc')) %}

  {%- for package in install.packages|default([], true) %}

    {%- if loop.first and not packages %}

include:
  - zoomdata.repo

    {%- endif %}

    {%- do packages.append(package) %}

{{ package }}_package:
  pkg.installed:
    - name: {{ package }}
    {%- if install.get('version') %}
    - version: {{ install.version }}
    {%- endif %}
    - skip_verify: True
    - require:
      - sls: zoomdata.repo

  {%- endfor %}

{%- endfor %}

{%- for service, config in zoomdata.config|default({}, true)|dictsort() %}

  {%- if config.get('path') and packages %}

{{ service }}_config:
  file.managed:
    - name: {{ config.path }}
    - user: {{ zoomdata.user }}
    - group: {{ zoomdata.group }}
    - mode: 640
    - makedirs: True
    {%- if config.get('properties') %}
    - contents:
      {%- for k, v in config.properties|default({}, true)|dictsort() %}
      - {{ (k, v)|join('=')|indent(8) }}
      {%- endfor %}
    {%- endif %}
    {%- if service in packages %}
    - require:
      - pkg: {{ service }}_package
    {%- endif %}
    {%- if service in services %}
    - watch_in:
      - service: {{ service }}_service
    {%- endif %}

  {%- endif %}

{%- endfor %}

{%- for service in packages %}

  {%- set service_function = 'running' %}
  {%- set service_requisite = 'watch' %}

  {%- if service not in services %}
    {%- set service_function = 'dead' %}
    {%- set service_requisite = 'require' %}
  {%- endif %}

{{ service }}_service:
  service.{{ service_function }}:
    - name: {{ service }}
    - enable: True
    - {{ service_requisite }}:
      - pkg: {{ service }}_package

{%- endfor %}
