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

{%- endif -%}


zoomdata-repo:
  file.managed:
    - name: {{ zoomdata.repo_file }}
    - source: {{ repo_file_source }}
    - user: root
    - group: root
    - mode: 644
    - skip_verify: True
