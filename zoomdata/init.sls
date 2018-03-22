{%- from 'zoomdata/map.jinja' import zoomdata -%}

include:
  {%- if zoomdata['erase'] and not zoomdata['bootstrap'] %}
  # Drop packages which do not being defined for installation.
  # Usually takes effect when switching releases.
  - zoomdata.remove
  {%- endif %}
  - zoomdata.install
  - zoomdata.tools

{%- if zoomdata['bootstrap'] %}

# Entering special "Bootstrap Zoomdata" mode:
# make sure that initial installation has been completed when
# bypassing state enforcement (``enforce: False`` Pillar setting).
#
# If the ``bootstrap`` key (or grain value) is present, it means
# that we should still apply configured setting from Pillar.

zoomdata-bootstrap:
  grains.present:
    - name: zoomdata:bootstrap
    - value: {{ zoomdata['bootstrap'] }}
    {%- if grains['saltversioninfo'] >= [2017, 7, 2, 0] %}
    - require_in:
      # The requisite type and full sls name is mandatory here.
      # Relative names do not work with ``require_in``.
      - sls: zoomdata.install
    {%- else %}
    # The ``require_in`` requisite for a whole sls is
    # not supported in older Salt versions
    - order: 1
    {%- endif %}

zoomdata-completed:
  grains.absent:
    - name: zoomdata:bootstrap
    - require:
      - sls: zoomdata.install

{%- endif %}
