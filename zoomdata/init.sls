{%- from 'zoomdata/map.jinja' import zoomdata with context %}

{%- set packages = [] %}
{%- set services = zoomdata.services|default([], true) %}

{%- for install in (zoomdata, zoomdata.get('edc')) %}

  {%- for package in install.packages|default([], true) %}

    {%- if loop.first and not packages %}

# Configure Zoomdata packages repository

include:
  - zoomdata.repo

    {%- endif %}

    {%- do packages.append(package) %}

{{ package }}_package:
  pkg.installed:
    - name: {{ package }}
    {%- if install.get('version') %}
    - version: {{ install.version }}
    {%- endif %}
    - skip_verify: {{ zoomdata.gpgkey is none or zoomdata.gpgkey == '' }}
    - require:
      - sls: zoomdata.repo

  {%- endfor %}

{%- endfor %}

{%- if salt['test.provider']('service') == 'systemd'
   and zoomdata.limits %}

# Provision systemd limits Zoomdata services

  {%- for service in packages %}

{{ service }}_systemd_limits:
  file.managed:
    - name: /etc/systemd/system/{{ service }}.service.d/limits.conf
    - source: salt://zoomdata/files/systemd_unit_override.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    - context:
        sections:
          Service:
    {%- for item, limit in zoomdata.limits|dictsort() %}
      {%- if 'hard' in limit|default({}, true) %}
            Limit{{ item|upper() }}: >-
                {{ (limit.get('soft', none),limit.hard)|reject("none")|join(":") }}
      {%- endif %}
    {%- endfor %}
    - require:
      - pkg: {{ service }}_package
    - watch_in:
      - module: systemctl_reload
    {%- if service in services %}
      - service: {{ service }}_service
    {%- endif %}

  {%- endfor %}

systemctl_reload:
  module.wait:
    - name: service.systemctl_reload

{%- else %}

  {%- if packages %}

# Provision global system limits for Zoomdata user

zoomdata-user-limits-conf:
  file.managed:
    - name: /etc/security/limits.d/30-zoomdata.conf
    - source: salt://zoomdata/files/limits.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: {{ packages|first() }}_package
    {%- if services %}
    - watch_in:
      {%- for service in services %}
      - service: {{ service }}_service
      {%- endfor %}
    {%- endif %}

  {%- endif %}

{%- endif %}

# Configure Zoomdata environment

{%- for service, environment in zoomdata.environment|default({}, true)|dictsort() %}

  {%- if environment.get('path') and service in packages %}

{{ service }}_environment:
  file.managed:
    - name: {{ environment.path }}
    {%- if environment.get('variables') %}
    - source: salt://zoomdata/files/env.sh
    - template: jinja
    - context:
        service: {{ service }}
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
    {%- if service in services %}
    - watch_in:
      - service: {{ service }}_service
    {%- endif %}
    # Prevent `test=True` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

{%- endfor %}

# Configure Zoomdata services

{%- for service, config in zoomdata.config|default({}, true)|dictsort() %}

  {%- if config.get('path') and service in packages %}

{{ service }}_config:
  file.managed:
    - name: {{ config.path }}
    {%- if config.get('properties') %}
    - source: salt://zoomdata/files/service.properties
    - template: jinja
    - context:
        service: {{ service }}
    {%- else %}
    - replace: False
    {%- endif %}
    - user: root
    - group: {{ zoomdata.group }}
    - mode: 0640
    - makedirs: True
    {%- if service in packages %}
    - require:
      - pkg: {{ service }}_package
    {%- endif %}
    {%- if service in services %}
    - watch_in:
      - service: {{ service }}_service
    {%- endif %}
    # Prevent `test=True` failures on a fresh system
    - onlyif: getent group | grep -q '\<{{ zoomdata.group }}\>'

  {%- endif %}

{%- endfor %}

# Manage Zoomdata services: first stop those were not explicitly declared and
# finally start all defined in defaults or Pillar

{%- for service in packages %}

  {%- if service not in services %}

{{ service }}_service:
  service.dead:
    - name: {{ service }}
    - enable: True
    - require:
      - pkg: {{ service }}_package

  {%- endif %}

{%- endfor %}

{%- for service in services %}

{{ service }}_service:
  service.running:
    - name: {{ service }}
    - enable: True
    - watch:
      - pkg: {{ service }}_package

{%- endfor %}

# Try to enable Zoomdata services in "manual" way if Salt `service` state module
# is currently not available (e.g. during Docker or Packer build)

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
    - onfail:
      - service: {{ service }}_service

{%- endfor %}
