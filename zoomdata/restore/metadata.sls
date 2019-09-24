{%- from 'zoomdata/map.jinja' import zoomdata, postgres with context %}

{%- if zoomdata.restore['dir']
   and (not postgres['connection_uri']
        or (postgres['connection_uri'] and postgres['password'])
       ) %}

include:
  - zoomdata.services.stop

  {%- for service in zoomdata.backup['services'] %}
    {%- set config = zoomdata.config.get(service, {}).properties|
                     default({}, true) %}

    {%- for properties in postgres.zoomdata_properties %}
      {#- The full set of properties: url, user and pw need to be configured #}
      {%- set has_properties = [true] %}
      {%- for property in properties %}
        {%- if property not in config %}
          {%- do has_properties.append(false) %}
        {%- endif %}
      {%- endfor %}

      {%- if has_properties|last() %}
        {%- set user = config[properties[1]] %}
        {%- set password = config[properties[2]] %}

{{ service }}_{{ properties[1] }}:
  postgres_user.present:
    - name: {{ user }}
    - password: {{ password }}
    - user: {{ zoomdata.restore['user'] }}

      {%- endif %}
    {%- endfor %}

  {%- endfor %}

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
        {{ zoomdata.restore['bin'] }} {{ postgres.connection_uri }}
    - cwd: "{{ zoomdata.restore['dir'] }}"
    - runas: {{ zoomdata.restore['user'] }}
      {#- The password is required for remote connections #}
      {%- if postgres.password %}
    - env:
      - PGUSER: {{ postgres.user|yaml() }}
      - PGPASSWORD: {{ postgres.password|yaml() }}
      {%- endif %}
    - require:
      - sls: zoomdata.services.stop
      - pkg: zoomdata_backup_decompressor

    {%- endif %}
  {%- endfor %}

{%- else %}

zoomdata_restore:
  test.fail_without_changes:
   - name: 'Please define `zoomdata:restore:dir` Pillar value.'
   - failhard: True

{%- endif %}
