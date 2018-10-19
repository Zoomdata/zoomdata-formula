{%- from 'zoomdata/map.jinja' import zoomdata %}

{%- if zoomdata.backup['destination'] and (
       zoomdata.backup['state'] or zoomdata.backup['services']) %}

  {%- set timestamp = salt['status.time'](zoomdata.backup['strptime']) %}
  {%- do salt['grains.set']('zoomdata:backup:latest', timestamp) %}
  {%- set backup_dir = salt['file.join'](zoomdata.backup['destination'], timestamp) %}
  {%- set state_file = zoomdata.backup['state'] ~ '.sls' %}

zoomdata_backup_dir:
  file.directory:
    - name: {{ backup_dir }}
    - user: root
    - group: {{ zoomdata.restore['user']|default('root', true) }}
    - mode: 0775
    - makedirs: True

zoomdata_backup_latest:
  file.symlink:
    - name: {{ salt['file.join'](zoomdata.backup['destination'], 'latest') }}
    - target: {{ timestamp|yaml() }}
    - force: True
    - onchanges:
      - file: zoomdata_backup_dir

zoomdata_dump_readme:
  file.managed:
    - name: {{ salt['file.join'](zoomdata.backup['destination'], 'README') }}
    - contents: |
        This directory contains Zoomdata databases and state backups. If there
        is a file called {{ state_file }} in any of subdirectories, you may
        copy it to the Salt Pillar directory (usually at /srv/pillar/zoomdata)
        on Salt Master or Salt Masterless Minion and optionally edit the Pillar
        top file (/srv/pillar/top.sls) to enable it. That would allow to do
        full restoration of backed up Zoomdata installation including package
        versions and running services by executing command

          sudo salt-call state.apply zoomdata.restore

        on target host.
    - user: root
    - group: root
    - mode: 0644
    - onchanges:
      - file: zoomdata_backup_dir

{%- endif %}
