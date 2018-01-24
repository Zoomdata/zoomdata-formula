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

{%- if zoomdata.backup is not mapping %}
  {#- Reload defaults if the ``backup`` dictionary is messy #}
  {%- import_yaml 'zoomdata/defaults.yaml' as defaults %}
  {%- do zoomdata.update({'backup': defaults.zoomdata.backup}) %}
{%- endif %}

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
    - name: pxz

  {%- endif %}

zoomdata_backup_dir:
  file.directory:
    - name: {{ backup_dir }}
    - user: root
    - group: root
    - mode: 0755
    - makedirs: True

  {%- if zoomdata.backup['state'] %}

zoomdata_dump_state:
  file.serialize:
    - name: {{ salt['file.join'](backup_dir, zoomdata.backup['state']) ~ '.yaml' }}
    - dataset: {{ zoomdata.local|yaml }}
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

{{ service }}_backup:
  test.succeed_with_changes

{#- The service supposed to be started back by applying ``zoomdata`` or
    ``zoomdata.install`` SLS. #}

{{ service }}_stop:
  service.dead:
    - name: {{ service }}
    - onchanges:
      - test: {{ service }}_backup

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
      {%- set database = config[properties[0]].split('/')|last %}
      {%- set user = config[properties[1]] %}
      {%- set password = config[properties[2]] %}

      {#- Backup all DBs configured for the service,
         or only those which explicitly defined. #}
      {%- if zoomdata.backup['databases']|default(none) == [] or
             database in zoomdata.backup['databases']|default([], true) %}

{{ database }}_db_backup:
  cmd.run:
    - name: >-
        pg_dump
        --no-password --clean --if-exists --create
        {{ connection_uri }}
        | pxz --compress --to-stdout --threads {{ salt['status.nproc']() }} >
        {{ salt['file.join'](backup_dir, database) }}_postgre.sql.xz
    - env:
      - PGUSER: {{ user }}
      - PGPASSWORD: {{ password }}
    - onchanges:
      - test: {{ service }}_backup
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
