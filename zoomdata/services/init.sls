{%- from 'zoomdata/map.jinja' import zoomdata -%}

include:
{%- if not zoomdata['bootstrap'] %}
  - zoomdata.backup.layout
  - zoomdata.backup.state
  # Stop services only when doing upgrade and services metadata backup
  - zoomdata.services.stop
  {%- if zoomdata['erase'] %}
  # Drop packages which do not being defined for installation.
  # Usually takes effect when switching releases.
  - zoomdata.remove
  {%- endif %}
  - zoomdata.backup.metadata
  - zoomdata.backup.retension
{%- endif %}
  - zoomdata.services.install
  - zoomdata.services.start
