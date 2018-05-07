{%- from 'zoomdata/map.jinja' import init_available,
                                     zoomdata with context %}

{%- set packages = zoomdata['packages'] +
                   zoomdata.edc['packages'] +
                   zoomdata.microservices['packages'] %}


{%- if init_available %}

  {%- set services = [] %}
  {%- for service in packages + zoomdata.local['services'] %}
    {%- if service and service not in services %}
      {%- do services.append(service) %}
    {%- endif %}
  {%- endfor %}

  {%- if 'zoomdata-consul' in services %}
    {#- The ``zoomdata-consul`` is a special kind of service
        and should be stopped last. #}
    {%- do services.remove('zoomdata-consul') %}
    {%- do services.append('zoomdata-consul') %}
  {%- endif %}

  {%- for service in services %}

{{ service }}_stop_disable:
  service.dead:
    - name: {{ service }}
    - disabled: {{ service not in zoomdata['services'] }}

  {%- endfor %}

{%- else %}

  {#- If there is no init system, just do nothing.
      The states here are rendered to satisfy upper level
      dependecies only. #}
  {%- for service in packages %}

{{ service }}_stop_disable:
  test.nop:
    - name: {{ service }}

  {%- endfor %}

{%- endif %}
