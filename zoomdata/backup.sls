{%- from 'zoomdata/map.jinja' import zoomdata %}

{%- set postgre_conn_properties = (
  (
    'spring.datasource.url',
    'spring.datasource.username',
    'spring.datasource.password'
  ),
  (
    'upload.destination.params.jdbc_url',
    'upload.destination.params.user_name',
    'upload.destination.params.password'
  ),
) %}

{%- set backup_dir = salt['file.join'](
  zoomdata.backup['destination'],
  salt['status.time'](zoomdata.backup['strptime'])
) %}

{#- No destination, no backups #}
{%- if zoomdata.backup['destination'] and
    (zoomdata.backup['services'] or zoomdata.backup['state']) -%}

  {%- if zoomdata.backup['services'] %}

zoomdata_backup_compressor:
  pkg.installed:
    - name: {{ zoomdata.backup['compressor'] }}

  {%- endif %}

zoomdata_backup_dir:
  file.directory:
    - name: {{ backup_dir }}
    - user: root
    - group: root
    - mode: 0755
    - makedirs: True

  {%- if zoomdata.backup['state'] %}

    {%- do zoomdata.local.update({'backup': zoomdata.backup}) %}
    {%- do zoomdata.restore.update({'dir': backup_dir}) %}
    {%- do zoomdata.local.update({'restore': zoomdata.restore}) %}

zoomdata_dump_state:
  file.serialize:
    - name: {{ salt['file.join'](backup_dir, zoomdata.backup['state']) ~ '.sls' }}
    - dataset: {{ {'zoomdata': zoomdata.local}|yaml }}
    - formatter: yaml
    - user: root
    - group: root
    # Will contain passwords!
    - mode: 0600
    - onchanges:
      - file: zoomdata_backup_dir
    - onchanges_in:
      - file: zoomdata_backup_retension

  {%- endif %}
{%- endif %}

{%- for service in zoomdata.backup['services'] %}
  {%- set config = {} %}
  {%- if service in zoomdata['packages'] %}

    {#- Read service config to retrieve DB connection details later #}
    {%- set config = zoomdata.config.get(service, {}).properties|
                     default(config, true) %}

{#-
Detect if the service configured for backup would be upgraded
during zoomdata.install SLS run. This will trigger the backup process.
Nothing would happen if nothing to upgrade.
If called directly as ``state.apply zoomdata.backup``, always do the backup.
#}

{#- The service supposed to be started back by applying ``zoomdata`` or
    ``zoomdata.install`` SLS. #}

{{ service }}_stop:
  service.dead:
    - name: {{ service }}
    - onchanges:
      - file: zoomdata_backup_dir

  {%- endif %}

  {%- for properties in postgre_conn_properties %}
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
      - PGUSER: {{ user }}
      - PGPASSWORD: {{ password }}
    - onchanges:
      - file: zoomdata_backup_dir
    - onchanges_in:
      - file: zoomdata_backup_retension
    - require:
      - service: {{ service }}_stop
      - file: zoomdata_backup_dir
      - pkg: zoomdata_backup_compressor
    # Stop highstate execution if backup has failed
    - failhard: True

      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endfor %}

{%- if zoomdata.backup['destination'] and zoomdata.backup['retention'] %}

zoomdata_backup_retension:
  file.retention_schedule:
    - name: {{ zoomdata.backup['destination'] }}
    - retain:
        most_recent: {{ zoomdata.backup['retention'] }}
    - strptime_format: "{{ zoomdata.backup['strptime'] }}"

{%- endif %}
