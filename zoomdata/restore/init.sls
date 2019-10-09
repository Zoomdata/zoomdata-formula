{%- do salt['grains.set']('zoomdata:bootstrap', true) %}

include:
  - zoomdata.restore.metadata
  - zoomdata.remove
  - zoomdata.services.install
  - zoomdata.services.start

zoomdata-completed:
  grains.absent:
    - name: 'zoomdata:bootstrap'
    - require:
      - sls: zoomdata.services.start
