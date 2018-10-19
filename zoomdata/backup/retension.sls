{%- from 'zoomdata/map.jinja' import zoomdata %}

{%- if zoomdata.backup['destination'] and zoomdata.backup['retention'] %}

zoomdata_backup_retension:
  file.retention_schedule:
    - name: {{ zoomdata.backup['destination'] }}
    - retain:
        most_recent: {{ zoomdata.backup['retention'] }}
    - strptime_format: {{ zoomdata.backup['strptime']|yaml() }}
    {%- if not zoomdata['bootstrap'] and (
           zoomdata.backup['state'] or zoomdata.backup['services']) %}
    # Subscribe on changes only when any backup type is going to be made
    - onchanges:
      - file: zoomdata_backup_dir
    {%- else %}
    # FIXME: the state is really not stateful
    - onlyif: test -d "{{ zoomdata.backup['destination'] }}"
    {%- endif %}

{%- endif %}
