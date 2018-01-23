{%- from 'zoomdata/map.jinja' import init_available,
                                     zoomdata with context %}

{%- set packages = [] %}
{%- set services = zoomdata.services|default([], true) %}
{%- set versions = {} %}

{%- for install in (zoomdata, zoomdata.edc) %}
  {%- for package in install.packages|default([], true) %}
    {%- if package not in packages %}
      {%- do packages.append(package) %}
      {%- do versions.update({package: install.get('version')}) %}
    {%- endif %}
  {%- endfor %}
{%- endfor %}

{%- set includes = [] %}
{%- if packages %}
  {%- do includes.append('zoomdata.repo') %}
{%- endif %}
{%- if 'zoomdata' in packages %}
  {%- do includes.append('zoomdata.tls') %}
{%- endif %}

{%- if includes -%}

# Configure Zoomdata packages repository

include:
  {{ includes|yaml(false)|indent(2) }}

{%- endif %}

{%- for package in packages %}

{{ package }}_package:
  pkg.installed:
    - name: {{ package }}
  {%- if versions.get(package) %}
    - version: {{ versions[package] }}
  {%- endif %}
    - skip_verify: {{ zoomdata.gpgkey is none or zoomdata.gpgkey == '' }}
    - require:
      - sls: zoomdata.repo

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
        {%- if package in services and init_available %}
    - watch_in:
      - service: {{ package }}_service
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
        header: {{ zoomdata.header|default('', true)|yaml }}
        sections:
          Service:
      {%- for item, limit in zoomdata.limits|default({}, true)|dictsort() %}
        {%- if 'hard' in limit|default({}, true) %}
            Limit{{ item|upper() }}: >-
                {{ (limit.get('soft', none),limit.hard)|reject("none")|join(":") }}
        {%- endif %}
      {%- endfor %}
    - require:
      - pkg: {{ service }}_package
      {%- if init_available %}
    - watch_in:
      - module: systemctl_reload
        {%- if service in services %}
      - service: {{ service }}_service
        {%- endif %}
      {%- endif %}

    {%- endfor %}

    {%- if init_available %}

systemctl_reload:
  module.wait:
    - name: service.systemctl_reload

    {%- endif %}

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
        header: {{ zoomdata.header|default('', true)|yaml }}
        release: {{ zoomdata.release }}
        limits: {{ zoomdata.limits }}
        user: {{ zoomdata.user|default('root', true) }}
    - require:
      - pkg: {{ packages|first() }}_package
    {%- if services and init_available %}
    - watch_in:
      {%- for service in packages %}
      - service: {{ service }}_service
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
        header: {{ zoomdata.header|default('', true)|yaml }}
        release: {{ zoomdata.release }}
        environment: {{ environment['variables'] }}
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
    {%- if service in services and init_available %}
    - watch_in:
      - service: {{ service }}_service
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
      {%- if service in services and init_available %}
    - watch_in:
      - service: {{ service }}_service
      {%- endif %}

    {%- endif %}

{{ service }}_config:
  file.managed:
    - name: {{ config.path }}
    {%- if config.properties|default({}, true) %}
    - source: salt://zoomdata/templates/service.properties
    - template: jinja
    - defaults:
        header: {{ zoomdata.header|default('', true)|yaml }}
        release: {{ zoomdata.release }}
        properties: {{ config['properties'] }}
    {%- else %}
    - replace: False
    {%- endif %}
    - user: root
    - group: {{ zoomdata.group }}
    - mode: 0640
    - makedirs: True
    - require:
      - pkg: {{ service }}_package
    {%- if service in services and init_available %}
    - watch_in:
      - service: {{ service }}_service
    {%- endif %}
    # Prevent ``test=True`` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

{%- endfor %}

# Manage Zoomdata services: first stop those were not explicitly declared and
# finally start all defined in defaults or Pillar

{%- if init_available %}

  {%- for service in packages %}

    {%- if service not in services %}

{{ service }}_service:
  service.dead:
    - name: {{ service }}
    - require:
      - pkg: {{ service }}_package

    {%- endif %}

  {%- endfor %}

  {%- for service in services %}

    {%- if service in packages %}

{{ service }}_service:
  service.running:
    - name: {{ service }}
    - enable: True
    - watch:
      - pkg: {{ service }}_package
    # Skip dealing with daemons if there are no binaries at all.
    # Fixes applying the state with ``test=True``.
    - onlyif: test -d "{{ salt['file.join'](zoomdata.prefix, 'bin') }}"

    {%- endif %}

  {%- endfor %}

{%- else %}

# Try to enable Zoomdata services in "manual" way if Salt `service` state module
# is currently not available (e.g. during Docker or Packer build when is no init
# system running)

  {%- for service in packages %}

{{ service }}_enable:
  cmd.run:
    {%- if salt['file.file_exists']('/bin/systemctl') %}
    - name: systemctl enable {{ service }}
    {%- elif salt['cmd.which']('chkconfig') %}
    - name: chkconfig {{ service }} on
    {%- elif salt['file.file_exists']('/usr/sbin/update-rc.d') %}
    - name: update-rc.d {{ service }} defaults
    {%- else %}
    # Nothing to do
    - name: 'true'
    {%- endif %}

  {%- endfor %}

{%- endif %}
