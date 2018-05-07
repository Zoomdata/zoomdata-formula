{%- from 'zoomdata/map.jinja' import zoomdata %}

{%- if zoomdata.backup['destination'] and zoomdata.backup['retention'] %}

zoomdata_backup_retension:
  file.retention_schedule:
    - name: {{ zoomdata.backup['destination'] }}
    - retain:
        most_recent: {{ zoomdata.backup['retention'] }}
    - strptime_format: {{ zoomdata.backup['strptime']|yaml() }}
    - onchanges:
      - file: zoomdata_backup_dir

{%- endif %}
