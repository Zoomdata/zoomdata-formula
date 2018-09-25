{%- from 'zoomdata/map.jinja' import zoomdata -%}

{%- set url = 'http://localhost:8080' -%}
{%- set data = [] %}
{%- set show = {} %}

{%- for user in zoomdata.setup.passwords|default({}, true) %}
  {%- if zoomdata.setup.passwords[user] == 'random' %}
    {%- set password = salt['random.get_str'](20) %}
    {%- if '_' not in password %}
      {%- set password = password[0] + '_' + password[1:] %}
    {%- endif %}
    {%- do show.update({user: password}) %}
  {%- else %}
    {%- set password = zoomdata.setup.passwords[user] %}
  {%- endif %}
  {% do data.append({'user': user, 'password': password}) %}
{%- endfor %}

{%- if data %}

# Wait until Zoomdata server will be available
zoomdata-wait:
  http.wait_for_successful_query:
    - name: '{{ url }}/zoomdata/service/version'
    - wait_for: 600
    - status: 200

# Setup user passwords
zoomdata-setup-passwords:
  http.query:
    - name: '{{ url }}/zoomdata/service/user/initUsers'
    - status: 200
    - method: POST
    - header_dict:
        Accept: '*/*'
        Content-Type: 'application/vnd.zoomdata.v2+json'
    - username: admin
    - password: admin
    - data: '{{ data|json }}'
    - require:
      - http: zoomdata-wait

  {%- if show %}

zoomdata-show-passwords:
  test.show_notification:
    - name: Passwords generated for users in Zoomdata
    - text: |-
        {{ show|yaml(false)|indent(8) }}
    - require:
      - http: zoomdata-setup-passwords

  {%- endif %}

{%- else %}

zoomdata-setup:
  test.show_notification:
    - text: |-
        The Zoomdata installation has been comleted. Nothing to setup.
        Configure the ``zoomdata:setup:passwords`` Pillar values to
        automatically set passswords for users.

{%- endif %}
