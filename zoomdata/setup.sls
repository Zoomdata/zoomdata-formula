{%- from 'zoomdata/map.jinja' import zoomdata %}

{#- Always fall back to defaults to construct connection URL #}
{%- set props = salt['defaults.merge'](
  salt['defaults.get']('zoomdata:zoomdata:config:zoomdata:properties'),
  zoomdata.config.zoomdata.properties|default({}, true)
) %}
{#- We assume Zoomdata Web server is binded on local loopback interaface #}
{%- set url = 'http://localhost:%s%s'|format(
  props['server.port'],
  props['server.servlet.context-path']
) %}
{%- set api = (url, zoomdata.setup['api'])|join('/') %}

{%- set users = {} %}
{%- set generated_passwords = {} %}

{%- for user in zoomdata.setup.passwords|default({}, true) %}
  {%- if not zoomdata.setup.passwords[user] or
             zoomdata.setup.passwords[user] == 'random' %}

    {%- set password = salt['grains.get']('zoomdata:users:' ~ user) %}

    {%- if not password %}
      {%- set password = '%s_%s'|format(salt['random.get_str'](range(8, 15)|random()),
                                        grains['server_id']|string()|random()) %}
      {%- do generated_passwords.update({user: password}) %}
    {%- endif %}

  {%- else %}
    {%- set password = zoomdata.setup.passwords[user] %}
  {%- endif %}

  {%- do users.update({user: password}) %}
{%- endfor -%}

# Wait until Zoomdata server will be available
zoomdata-wait:
  http.wait_for_successful_query:
    - name: "{{ (url, zoomdata.setup['probe'])|join('/') }}"
    - wait_for: {{ zoomdata.setup['timeout'] }}
    - status: 200
    - failhard: True
    # Works only for Salt >= 2017.7
    - request_interval: 30

{%- if users %}

zoomdata-setup-passwords:
  zoomdata.init_users:
    - name: '{{ api }}'
    - users: {{ users|yaml() }}

{%- endif %}

{%- if generated_passwords %}

zoomdata-save-generated-passwords:
  grains.present:
    - name: zoomdata:users
    - value: {{ generated_passwords|yaml() }}
    - onchanges:
      - zoomdata: zoomdata-setup-passwords

{%- endif %}

{%- if 'supervisor' in users %}

  {%- if zoomdata.setup.branding['css']|default(none, true)
      or zoomdata.setup.branding['file']|default(none, true) %}

zoomdata-branding:
  zoomdata.branding:
    - name: '{{ api }}'
    - username: supervisor
    - password: {{ users['supervisor'] }}
    - css: {{ zoomdata.setup.branding['css']|default(none, true) }}
    - login_logo: {{ zoomdata.setup.branding['login_logo']|default(none, true) }}
    - json_file: {{ zoomdata.setup.branding['file']|default(none, true) }}
    {%- if 'supervisor' in generated_passwords %}
    - onchanges:
      - zoomdata: zoomdata-setup-passwords
    {%- endif %}

  {%- endif %}

  {%- for key, value in zoomdata.setup.connectors|dictsort %}

zoomdata-connector-{{ key }}:
  http.query:
    - name: '{{ api }}/connection/types/{{ key }}'
    - status: 200
    - method: PATCH
    - header_dict: {{ zoomdata.setup['headers']|yaml }}
    - username: supervisor
    - password: {{ users['supervisor'] }}
    - data: '{"enabled": {{ value|string|lower }}}'
    {%- if 'supervisor' in generated_passwords %}
    - onchanges:
      - zoomdata: zoomdata-setup-passwords
    {%- endif %}

  {%- endfor %}

  {%- if zoomdata.setup.license['URL']|default(none, true) %}

zoomdata-license:
  zoomdata.licensing:
    - name: '{{ api }}'
    - username: supervisor
    - password: {{ users['supervisor'] }}
    - url: {{ zoomdata.setup.license['URL'] }}
    - expire: {{ zoomdata.setup.license['expirationDate']|yaml }}
    - license_type: {{ zoomdata.setup.license['licenseType'] }}
    - users: {{ zoomdata.setup.license['userCount'] }}
    - sessions: {{ zoomdata.setup.license['concurrentSessionCount'] }}
    - concurrency: {{ zoomdata.setup.license['enforcementLevel'] }}
    - force: {{ zoomdata.setup.license['force'] }}
    {%- if 'supervisor' in generated_passwords %}
    - onchanges:
      - zoomdata: zoomdata-setup-passwords
    {%- endif %}

  {%- endif %}

  {%- for key, value in zoomdata.setup.toggles|dictsort %}

zoomdata-supervisor-toggle-{{ key }}:
  http.query:
    - name: '{{ api }}/system/variables/ui/{{ key }}'
    - status: 204
    - method: POST
    - header_dict:
        Accept: '*/*'
        Content-Type: 'text/plain'
    - username: supervisor
    - password: {{ users['supervisor'] }}
    - data: '{{ value|string|lower }}'
    {%- if 'supervisor' in generated_passwords %}
    - onchanges:
      - zoomdata: zoomdata-setup-passwords
    {%- endif %}

  {%- endfor %}

{%- endif %}

{%- if not zoomdata.setup|default({}, true) %}

zoomdata-setup:
  test.show_notification:
    - text: |-
        The Zoomdata installation has been completed. Nothing to setup.
        Configure the ``zoomdata:setup:passwords`` Pillar values to
        automatically set passswords for users.

{%- endif %}
