{%- from 'zoomdata/map.jinja' import zoomdata %}

{%- if zoomdata.backup['destination'] and (
       zoomdata.backup['state'] or zoomdata.backup['services']) %}

include:
  - zoomdata.backup.layout
  - zoomdata.backup.state
  - zoomdata.services.stop
  - zoomdata.backup.metadata
  - zoomdata.backup.retension
  - zoomdata.services.start

{%- else %}

zoomdata-backup:
  test.show_notification:
    - name: The backup has been disabled
    - text: |
        To make a backup of Zoomdata installation state or metadata you must
        set ``zoomdata:backup:state`` or ``zoomdata:backup:services`` Pillar
        values respectively.

{%- endif %}
