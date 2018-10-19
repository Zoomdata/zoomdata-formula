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

include:
  - zoomdata.repo

{%- for package in packages %}

{{ package }}_package:
  pkg.installed:
    - name: {{ package }}
    {%- if versions[package] %}
    - version: {{ versions[package] }}
    {#- Update local package metadata only on the first state.
        This speed ups execution during upgrades. #}
    - refresh: {{ loop.index == 1 }}
    {%- endif %}
    - skip_verify: {{ zoomdata.gpgkey|default(none, true) is none }}
    {%- if not zoomdata['bootstrap'] and not zoomdata['upgrade'] %}
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
      - service: {{ package }}_start_enable
    {%- endif %}

{%- endfor %}

{%- set jdbc = zoomdata.edc.jdbc|default({}, true) %}

{%- if jdbc.install|default(false) %}

# Download provided JDBC drivers for EDC connectors

  {%- for driver, jars in jdbc.drivers|default({}, true)|dictsort() %}
    {%- set package = ('zoomdata-edc', driver)|join('-') %}
    {%- if package in packages %}
      {%- for jar in jars %}

        {%- set jar_name = salt['file.basename'](jar) %}
        {%- set jar_hash = jar|replace('http:', 'https:', 1) ~ '.sha1' %}

        {#- Ugly workaround for bug in Salt 2016.11.3:
            ``skip_verify`` leads to stack trace with KeyError on ``source_sum['hsum']``.
            It is already fixed in upcoming 2016.11.4. #}

        {%- if 'error' in salt['http.query'](jar_hash, method='HEAD') %}
          {#- Check local cache or probe jar file URL #}
          {%- if salt['cp.is_cached'](jar) or
                 'body' in salt['http.query'](jar, method='HEAD') %}
            {#- Cache jar file and get its hash #}
            {%- set jar_hash = salt['hashutil.sha256_digest'](
                               salt['cp.get_file_str'](jar)) %}
          {%- endif %}
        {%- endif %}

{{ package }}_jdbc_{{ jar_name }}:
  file.managed:
    - name: {{ salt['file.join'](zoomdata.prefix, 'lib/edc-' ~ driver, jar_name) }}
    - source: {{ jar }}
    - source_hash: {{ jar_hash }}
    - user: root
    - group: {{ zoomdata.group }}
    - mode: 0640
    - makedirs: True
    - show_change: False
    - require:
      - pkg: {{ package }}_package
    {%- if package in zoomdata['services'] %}
    - watch_in:
      - service: {{ package }}_start_enable
    {%- endif %}

      {%- endfor %}
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
      - service: {{ service }}_start_enable
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
        release: {{ zoomdata.release }}
        limits: {{ zoomdata.limits|yaml() }}
        user: {{ zoomdata.user|default('root', true) }}
    - require:
      - pkg: {{ packages|first() }}_package
    {%- if zoomdata['services'] %}
    - watch_in:
      {%- for service in zoomdata['services'] %}
      - service: {{ service }}_start_enable
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
        release: {{ zoomdata.release }}
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
      - service: {{ service }}_start_enable
    {%- endif %}
    # Prevent `test=True` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

{%- endfor %}

# Configure Zoomdata services

{%- for service, config in zoomdata.config|default({}, true)|dictsort() %}

  {%- if config.path|default('') and service in packages %}

    {%- if config.old_path|default('') %}

{{ service }}_legacy_config:
  file.absent:
    - name: {{ config.old_path }}
    {%- if service in zoomdata['services'] %}
    - watch_in:
      - service: {{ service }}_start_enable
    {%- endif %}

    {%- endif %}

{{ service }}_config:
  file.managed:
    - name: {{ config.path }}
    {%- if config.properties|default({}, true) %}
    - source: salt://zoomdata/templates/service.properties
    - template: jinja
    - defaults:
        header: {{ zoomdata.header|default('', true)|yaml() }}
        release: {{ zoomdata.release }}
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
      - service: {{ service }}_start_enable
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
    {%- set jvm_file = salt['file.join'](zoomdata.prefix, srv ~ '.jvm') %}

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
      - service: {{ service }}_start_enable
    {%- endif %}
    # Prevent ``test=True`` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

{%- endfor %}
