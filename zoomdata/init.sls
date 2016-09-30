{%- from 'zoomdata/map.jinja' import zoomdata with context -%}

{%- if grains['os_family'] == 'Debian' %}

  {%- set repo_file_source = (zoomdata.repo_url,
                              zoomdata.release,
                              'apt',
                              grains['os'] | lower(),
                              ('zoomdata', zoomdata.release, grains['oscodename'] ~ '.list') | join('-'))
                              | join('/') %}

{%- elif grains['os_family'] == 'RedHat' %}

  {%- set repo_file_source = (zoomdata.repo_url,
                              zoomdata.release,
                              'yum',
                              grains['os_family'] | lower(),
                              grains['osmajorrelease'],
                              grains['osarch'],
                              'zoomdata' ~ '-' ~ zoomdata.release ~ '.repo')
                              | join('/') %}

{%- endif %}

{%- set func = 'installed' %}
{%- if zoomdata.version == 'latest' %}
  {%- set func = zoomdata.version %}
{%- elif zoomdata.version  %}
  {%- set version = zoomdata.version %}
{%- endif -%}


zoomdata-repo:
  file.managed:
    - name: {{ zoomdata.repo_file }}
    - source: {{ repo_file_source }}
    - user: root
    - group: root
    - mode: 644
    - skip_verify: True

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
