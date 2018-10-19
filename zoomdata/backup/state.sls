{%- from 'zoomdata/map.jinja' import zoomdata %}

{%- if zoomdata.backup['destination'] and zoomdata.backup['state'] -%}
  {%- set backup_dir = salt['file.join'](zoomdata.backup['destination'],
                                         salt['grains.get']('zoomdata:backup:latest', 'latest')) %}
  {%- set state_file = zoomdata.backup['state'] ~ '.sls' %}
  {%- do zoomdata.local.update({'backup': zoomdata.backup}) %}
  {%- do zoomdata.restore.update({'dir': backup_dir}) %}
  {%- do zoomdata.local.update({'restore': zoomdata.restore}) %}

zoomdata_dump_state:
  file.serialize:
    - name: {{ salt['file.join'](backup_dir, state_file) }}
    - dataset: {{ {'zoomdata': zoomdata.local}|yaml() }}
    - formatter: yaml
    - user: root
    - group: root
    # Will contain passwords!
    - mode: 0600
    # FIXME: subscribe on changes in repository settings
    - onchanges:
      - file: zoomdata_backup_dir

{%- endif %}
