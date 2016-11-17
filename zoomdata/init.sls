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

  {%- if environment.get('path') and packages %}

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

  {%- if config.get('path') and packages %}

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

# Manage Zoomdata services

{%- for service in packages %}

  {%- if service in services %}
    {%- set service_function = 'running' %}
    {%- set service_requisite = 'watch' %}
  {%- else %}
    {%- set service_function = 'dead' %}
    {%- set service_requisite = 'require' %}
  {%- endif %}

{{ service }}_service:
  service.{{ service_function }}:
    - name: {{ service }}
    - enable: True
    - {{ service_requisite }}:
      - pkg: {{ service }}_package

{%- endfor %}
