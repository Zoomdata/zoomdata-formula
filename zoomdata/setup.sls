{%- from 'zoomdata/map.jinja' import zoomdata -%}

{%- set url = 'http://localhost:8080' -%}
{%- set headers = {
  'Accept': '*/*',
  'Content-Type': 'application/vnd.zoomdata.v2+json'
} %}

{%- set users = {} %}
{%- set data = [] %}
{%- set show = {} %}

{%- for user in zoomdata.setup.passwords|default({}, true) %}

  {%- if not zoomdata.setup.passwords[user] or
             zoomdata.setup.passwords[user] == 'random' %}

    {%- set password = salt['grains.get']('zoomdata:users:' ~ user,
                                          salt['random.get_str'](20)) %}

    {%- if '_' not in password %}
      {%- set password = password[0] + '_' + password[1:] %}
    {%- endif %}

    {%- do show.update({user: password}) %}

  {%- else %}
    {%- set password = zoomdata.setup.passwords[user] %}
  {%- endif %}

  {%- do users.update({user: password}) %}

  {%- if not salt['grains.has_value']('zoomdata:users:' ~ user) %}
    {%- do data.append({'user': user, 'password': password}) %}
  {%- endif %}

{%- endfor %}

# Wait until Zoomdata server will be available
zoomdata-wait:
  http.wait_for_successful_query:
    - name: '{{ url }}/zoomdata/service/version'
    - wait_for: {{ zoomdata.setup['timeout'] }}
    - status: 200
    - failhard: True

{%- if data %}

# Setup user passwords
zoomdata-setup-passwords:
  http.query:
    - name: '{{ url }}/zoomdata/service/user/initUsers'
    - status: 200
    - method: POST
    - header_dict: {{ headers|yaml }}
    - username: admin
    - password: admin
    - data: '{{ data|json }}'

  {%- if show %}

zoomdata-save-generated-passwords:
  grains.present:
    - name: zoomdata:users
    - value: {{ show|yaml }}
    - require:
      - http: zoomdata-setup-passwords

zoomdata-show-passwords:
  test.show_notification:
    - name: Passwords generated for users in Zoomdata
    - text: |-
        {{ show|yaml(false)|indent(8) }}
    - require:
      - http: zoomdata-setup-passwords

  {%- endif %}

{%- endif %}

{%- if 'supervisor' in users %}

  {%- for key, value in zoomdata.setup.toggles|dictsort %}

zoomdata-supervisor-toggle-{{ key }}:
  http.query:
    - name: '{{ url }}/zoomdata/api/system/variables/ui/{{ key }}'
    - status: 204
    - method: POST
    - header_dict:
        Accept: '*/*'
        Content-Type: 'text/plain'
    - username: supervisor
    - password: {{ users['supervisor'] }}
    - data: '{{ value|string|lower }}'

  {%- endfor %}

  {%- for key, value in zoomdata.setup.connectors|dictsort %}

zoomdata-connector-{{ key }}:
  http.query:
    - name: '{{ url }}/zoomdata/service/connection/types/{{ key }}'
    - status: 200
    - method: PATCH
    - header_dict: {{ headers|yaml }}
    - username: supervisor
    - password: {{ users['supervisor'] }}
    - data: '{"enabled": {{ value|string|lower }}}'

  {%- endfor %}

  {%- if zoomdata.setup.branding['file']|default(none) %}

    {%- set file = zoomdata.setup.branding['file'] %}

zoomdata-branding-from-file-{{ salt['file.basename'](file) }}:
  http.query:
    - name: '{{ url }}/zoomdata/api/branding'
    - status: 200
    - method: POST
    - header_dict: {{ headers|yaml }}
    - username: supervisor
    - password: {{ users['supervisor'] }}
    - data_file: {{ salt['cp.cache_file'](file) }}

  {%- endif %}

{%- endif %}

{%- if not zoomdata.setup|default({}, true) %}

zoomdata-setup:
  test.show_notification:
    - text: |-
        The Zoomdata installation has been comleted. Nothing to setup.
        Configure the ``zoomdata:setup:passwords`` Pillar values to
        automatically set passswords for users.

{%- endif %}
