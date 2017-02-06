{%- from 'zoomdata/map.jinja' import zoomdata with context %}

{%- set init_available = grains['init'] != 'unknown' %}
{%- set config = zoomdata['config']|default({}, true) %}
{%- set properties = config.get('zoomdata', {})['properties']|default({}, true) %}
{%- set keystore = properties['server.ssl.key-store']|default(none, true) %}
{%- set password = properties['server.ssl.key-store-password']|default(none, true) %}

include:
  - zoomdata

{%- if zoomdata.tls.certificate|default('', true)
   and zoomdata.tls.key|default('', true)
   and keystore
   and password
   and 'zoomdata' in zoomdata.packages|default([], true) %}

  {%- set pem = keystore.split('.')[:-1]|join('.') %}
  {%- set crt = pem ~ '.crt' %}
  {%- set key = pem ~ '.key' %}
  {%- set p12 = pem ~ '.p12' %}

openssl:
  pkg.installed

zoomdata-download-tls-crt:
  file.managed:
    - name: {{ pem }}.crt
    - makedirs: True
    - contents_pillar: zoomdata:tls:certificate
    - unless: test -f '{{ keystore }}'

zoomdata-download-tls-key:
  file.managed:
    - name: {{ pem }}.key
    - makedirs: True
    - contents_pillar: zoomdata:tls:key
    - unless: test -f '{{ keystore }}'

zoomdata-create-pkcs12:
  cmd.run:
    - name: >-
        openssl pkcs12 -export
        -inkey {{ key }} -in {{ crt }} -CAfile {{ crt }}
        -name {{ zoomdata.tls.name }} -out {{ p12 }}
        -password pass:{{ password }}
    - require:
      - pkg: openssl
      - file: zoomdata-download-tls-crt
      - file: zoomdata-download-tls-key
    - unless: test -f {{ p12 }} && test -s {{ p12 }}
    - prereq:
      - cmd: zoomdata-create-jks

zoomdata-create-jks:
  cmd.run:
    - name: >-
        /opt/zoomdata/jre/bin/keytool
        -importkeystore -v
        -srckeystore {{ p12 }}
        -srcstoretype PKCS12
        -srcstorepass '{{ password }}'
        -destkeystore '{{ keystore }}'
        -deststorepass '{{ password }}'
        -destkeypass '{{ password }}'
    - unless: test -f '{{ keystore }}'
    - require:
      - pkg: zoomdata_package
  {%- if 'zoomdata' in zoomdata.services|default([], true)
     and init_available %}
    - watch_in:
      - service: zoomdata_service
  {%- endif %}

zoomdata-jks-permissions:
  file.managed:
    - name: {{ keystore }}
    - user: root
    - group: {{ zoomdata.group }}
    - mode: 0640
    - replace: False
    - require:
      - cmd: zoomdata-create-jks
  {%- if 'zoomdata' in zoomdata.services|default([], true)
     and init_available %}
    - require_in:
      - service: zoomdata_service
  {%- endif %}

zoomdata-remove-tls-crt:
  file.absent:
    - name: {{ crt }}
    - onchanges:
      - cmd: zoomdata-create-pkcs12

zoomdata-remove-tls-key:
  file.absent:
    - name: {{ key }}
    - onchanges:
      - cmd: zoomdata-create-pkcs12

zoomdata-remove-pkcs12:
  file.absent:
    - name: {{ p12 }}
    - onchanges:
      - cmd: zoomdata-create-jks

{%- endif %}
