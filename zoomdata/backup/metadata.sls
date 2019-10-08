{%- from 'zoomdata/map.jinja' import postgres, zoomdata %}

{%- if zoomdata.backup['destination'] and zoomdata.backup['services'] -%}

  {%- set backup_dir = salt['file.join'](zoomdata.backup['destination'],
                                         salt['grains.get']('zoomdata:backup:latest', 'latest')) %}
zoomdata_backup_compressor:
  pkg.installed:
    - name: {{ zoomdata.backup['compressor'] }}
    - onchanges:
      - file: zoomdata_backup_dir

  {%- for service in zoomdata.backup['services'] %}
    {#- Read service config to retrieve DB connection details later #}
    {%- set config = zoomdata.local.config.get(service, {}).properties|
                     default({}, true) %}

{#-
Detect if the service configured for backup would be upgraded
during ``zoomdata.services`` SLS run. This will trigger the backup process.
Nothing would happen if nothing to upgrade.
If called directly as ``state.apply zoomdata.backup``, always do the backup.
#}

    {%- for properties in postgres['zoomdata_properties'] %}
      {#- The full set of properties: url, user and pw need to be configured #}
      {%- set has_properties = [true] %}
      {%- for property in properties %}
        {%- if property not in config %}
          {%- do has_properties.append(false) %}
        {%- endif %}
      {%- endfor %}

      {%- if has_properties|last %}
        {%- set connection_uri = config[properties[0]]|replace('jdbc:', '', 1) %}
        {%- set database = connection_uri.split('/')|last %}
        {%- set user = config[properties[1]] %}
        {%- set password = config[properties[2]] %}

        {#- Backup all DBs configured for the service,
           or only those which explicitly defined. #}
        {%- if zoomdata.backup['databases']|default(none) == [] or
               database in zoomdata.backup['databases']|default([], true) %}

{{ database }}_db_backup:
  cmd.run:
    - name: >-
        {{ zoomdata.backup['bin'] }}
        {{ connection_uri }} |
        {{ zoomdata.backup['compressor'] }}
        --stdout {{ zoomdata.backup['comp_opts'] }} >
        {{ salt['file.join'](backup_dir, database ~ zoomdata.backup['comp_ext']) }}
    - env:
      - PGUSER: {{ user|yaml() }}
      - PGPASSWORD: {{ password|yaml() }}
    # Files should be owned by user
    # who would be able to read them on restoration.
    - runas: {{ zoomdata.restore['user'] }}
    - require:
      - pkg: zoomdata_backup_compressor
    - onchanges:
      - file: zoomdata_backup_dir
    # Stop highstate execution if backup has failed
    - failhard: True

        {%- endif %}
      {%- endif %}
    {%- endfor %}
  {%- endfor %}
{%- endif %}
