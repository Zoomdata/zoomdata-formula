{%- from 'zoomdata/map.jinja' import zoomdata with context %}

{%- set packages = [] %}
{%- set versions = {} %}

{%- for install in (zoomdata, zoomdata.edc, zoomdata.microservices) %}
  {%- for package in install.packages|default([], true) %}
    {%- if package and package not in packages %}
      {%- do packages.append(package) %}
      {%- do versions.update({package: install.get('version')}) %}
    {%- endif %}
  {%- endfor %}
{%- endfor %}

{%- set jdbc = zoomdata.edc.jdbc|default({}, true) %}

include:
  - zoomdata.repo

{%- for package in packages %}

  {%- set version = versions[package] %}
  {%- if version and version != 'latest' and '-' not in version and
         grains['saltversioninfo'] >= [2017, 7, 0, 0] and
         grains['os_family'] == 'Debian' %}
    {#- pkg state on Ubuntu allows wildcards instead of
        specifying the full version #}
    {%- set version = version ~ '-*' %}
  {%- endif %}

{{ package }}_package:
  {%- if package == 'zoomdata-edc-all' %}
  zoomdata.edc_installed:
  {%- else %}
  pkg.installed:
  {%- endif %}
    - name: {{ package }}
    {%- if version %}
    - version: {{ version }}
    {#- Update local package metadata only on the first state.
        This speed ups execution during upgrades. #}
    - refresh: {{ loop.index == 1 }}
    {%- endif %}
    - skip_verify: {{ zoomdata.gpgkey|default(none, true) is none }}
    {%- if not zoomdata['bootstrap']
       and not zoomdata['upgrade']
       and package in zoomdata.local['services'] %}
    - prereq_in:
      - service: {{ package }}_stop_disable
      {%- if zoomdata.backup['destination'] and (
             zoomdata.backup['state'] or
             package in zoomdata.backup['services']|default([], true)) %}
      - file: zoomdata_backup_dir
      {%- endif %}
    {%- endif %}
    {%- if package in zoomdata['services'] %}
    - watch_in:
      - {{ package }}_start_enable
    {%- endif %}

{%- endfor %}

{%- if 'zoomdata-consul' in packages %}

# The Consul data dir needs to be purged on upgrades

zoomdata-consul_data_dir:
  file.directory:
    # This assumes default installation location
    - name: {{ salt['file.join'](zoomdata['prefix'], 'data/consul') }}
    - clean: True
    - onchanges:
      - pkg: zoomdata-consul_package

{%- endif %}

{%- if jdbc['install']|default(false) %}

  {%- for package in zoomdata.edc['packages']|default([], true) %}

{{ package }}_libs:
  zoomdata.libraries:
    - name: {{ package }}
    {#- Check if EDC JDBC driver URLs have been configured #}
    - urls: {{ jdbc.drivers[package|replace('zoomdata-edc-', '', 1)]|default([], true) }}
    - require:
      - {{ package }}_package
    {%- if package in zoomdata['services'] %}
    - watch_in:
      - {{ package }}_start_enable
    {%- endif %}

  {%- endfor %}

{%- endif %}

{%- if zoomdata.limits|default({}) and packages %}

  {%- if salt['test.provider']('service') == 'systemd' %}

# Provision systemd limits Zoomdata services

    {%- for service in packages %}

{{ service }}_systemd_limits:
  file.managed:
    - name: /etc/systemd/system/{{ service }}.service.d/limits.conf
    - source: salt://zoomdata/templates/systemd_unit_override.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    - defaults:
        header: {{ zoomdata.header|default('', true)|yaml() }}
        sections:
          Service:
          {%- for item, limit in zoomdata.limits|default({}, true)|dictsort() %}
            {%- if 'hard' in limit|default({}, true) %}
            Limit{{ item|upper() }}: >-
                {{ (limit.get('soft', none), limit.hard)|reject("none")|join(":") }}
            {%- endif %}
          {%- endfor %}
    - require:
      - pkg: {{ service }}_package
    - watch_in:
      - module: systemctl_reload
      {%- if service in zoomdata['services'] %}
      - {{ service }}_start_enable
      {%- endif %}

    {%- endfor %}

  {%- else %}

# Provision global system limits for Zoomdata user

zoomdata-user-limits-conf:
  file.managed:
    - name: /etc/security/limits.d/30-zoomdata.conf
    - source: salt://zoomdata/templates/limits.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - defaults:
        header: {{ zoomdata.header|default('', true)|yaml() }}
        limits: {{ zoomdata.limits|yaml() }}
        user: {{ zoomdata.user|default('root', true) }}
    - require:
      - pkg: {{ packages|first() }}_package
    {%- if zoomdata['services'] %}
    - watch_in:
      {%- for service in zoomdata['services'] %}
      - {{ service }}_start_enable
      {%- endfor %}
    {%- endif %}

  {%- endif %}

{%- endif %}

# Configure Zoomdata environment

{%- for service, environment in zoomdata.environment|default({}, true)|dictsort() %}

  {%- if environment['path']|default('') and service in packages %}

{{ service }}_environment:
  file.managed:
    - name: {{ environment.path }}
    {%- if environment.get('variables') %}
    - source: salt://zoomdata/templates/env.sh
    - template: jinja
    - defaults:
        header: {{ zoomdata.header|default('', true)|yaml() }}
        environment: {{ environment['variables']|yaml() }}
    {%- else %}
    - replace: False
    {%- endif %}
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    {%- if service in packages %}
    - require:
      - pkg: {{ service }}_package
    {%- endif %}
    {%- if service in zoomdata['services'] %}
    - watch_in:
      - {{ service }}_start_enable
    {%- endif %}
    # Prevent `test=True` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

{%- endfor %}

# Configure Zoomdata services

{%- for service, config in zoomdata.config|default({}, true)|dictsort() %}

  {%- if config.path|default('') and service in packages %}

{{ service }}_config:
  file.managed:
    - name: {{ config.path }}
    {%- if config.properties|default({}, true) %}
    - source: salt://zoomdata/templates/service.properties
    - template: jinja
    - defaults:
        header: {{ zoomdata.header|default('', true)|yaml() }}
        properties: {{ config['properties']|yaml() }}
    {%- else %}
    - replace: False
    {%- endif %}
    - user: root
    - group: {{ zoomdata.group }}
    - mode: 0640
    - makedirs: True
    - require:
      - pkg: {{ service }}_package
    {%- if service in zoomdata['services'] %}
    - watch_in:
      - {{ service }}_start_enable
    {%- endif %}
    # Prevent ``test=True`` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

  {%- if config.json|default({}, true) and service in packages %}

{{ service }}_json:
  file.serialize:
    - name: {{ config.path }}
    - dataset: {{ config.json|yaml() }}
    - formatter: json
    - user: root
    - group: {{ zoomdata.group }}
    - mode: 0640
    - makedirs: True
    - require:
      - pkg: {{ service }}_package
    {%- if service in zoomdata['services'] %}
    - watch_in:
      - {{ service }}_start_enable
    {%- endif %}
    # Prevent ``test=True`` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

  {%- if config.options|default({}, true) and service in packages %}

    {%- if service.startswith('zoomdata-') %}
      {%- set srv = service|replace('zoomdata-', '', 1) %}
    {%- else %}
      {%- set srv = service %}
    {%- endif %}
    {%- set jvm_file = salt['file.join'](zoomdata.config_dir, srv ~ '.jvm') %}

{{ service }}_jvm:
  file.managed:
    - name: {{ jvm_file }}
    - source: salt://zoomdata/templates/service.jvm
    - template: jinja
    - defaults:
        header: {{ zoomdata.header|default('', true)|yaml() }}
        options: {{ config['options']|yaml() }}
    - user: root
    - group: {{ zoomdata.group }}
    - mode: 0640
    - makedirs: True
    - require:
      - pkg: {{ service }}_package
    {%- if service in zoomdata['services'] %}
    - watch_in:
      - {{ service }}_start_enable
    {%- endif %}
    # Prevent ``test=True`` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

{%- endfor %}

# Run post installation commands

{%- for service, commands in zoomdata.post_install|default({}, true)|dictsort() %}

  {%- if service in packages %}

    {%- for command in commands %}

{{ service }}-post-install-{{ loop.index }}:
  cmd.run:
    - name: {{ command }}
    - timeout: 600
    - require:
      - pkg: {{ service }}_package
    - onlyif: {{ zoomdata['bootstrap']|lower() }}

    {%- endfor %}

  {%- endif %}

{%- endfor %}
