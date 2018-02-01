{%- from 'zoomdata/map.jinja' import zoomdata, postgres %}

{%- if zoomdata.restore['dir'] %}

  {%- for service in zoomdata.backup['services'] %}
    {%- set config = zoomdata.config.get(service, {}).properties|
                     default({}, true) %}

    {%- for properties in postgres.properties %}
      {#- The full set of properties: url, user and pw need to be configured #}
      {%- set has_properties = [true] %}
      {%- for property in properties %}
        {%- if property not in config %}
          {%- do has_properties.append(false) %}
        {%- endif %}
      {%- endfor %}

      {%- if has_properties|last %}
        {%- set user = config[properties[1]] %}
        {%- set password = config[properties[2]] %}

{{ service }}_{{ properties[1] }}:
  postgres_user.present:
    - name: {{ user }}
    - password: {{ password }}
    - user: {{ zoomdata.restore['user'] }}
    - require_in:
      - test: zoomdata_services_stopped

      {%- endif %}
    {%- endfor %}

{{ service }}_stop:
  service.dead:
    - name: {{ service }}
    - require_in:
      - test: zoomdata_services_stopped

  {%- endfor %}

# Verify that all services have been stop before executing SQL scripts

zoomdata_services_stopped:
  test.succeed_without_changes

zoomdata_backup_decompressor:
  pkg.installed:
    - name: {{ zoomdata.backup['compressor'] }}

  {%- for dump in salt['file.readdir'](zoomdata.restore['dir']) %}
    {%- if dump.endswith(zoomdata.backup['comp_ext']) %}

zoomdata_restore_{{ salt['file.basename'](zoomdata.restore['dir']) }}_{{ dump }}:
  cmd.run:
    - name: >-
        {{ zoomdata.backup['compressor'] }}
        --decompress --stdout {{ zoomdata.backup['comp_opts'] }}
        {{ dump }} |
        {{ zoomdata.restore['bin'] }}
    - cwd: "{{ zoomdata.restore['dir'] }}"
    - runas: {{ zoomdata.restore['user'] }}
    - require:
      - test: zoomdata_services_stopped
      - pkg: zoomdata_backup_decompressor

    {%- endif %}
  {%- endfor %}

{%- else %}

zoomdata_restore:
  test.show_notification:
   - text: |
      Nothing to restore.
      Please define `zoomdata:restore:dir` Pillar value.

{%- endif %}
