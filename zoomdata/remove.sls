{%- from 'zoomdata/map.jinja' import zoomdata -%}

{%- set packages = zoomdata.tools.packages|default([], true) %}
{%- set services = zoomdata['services']|default([], true) %}

{%- for install in (zoomdata, zoomdata.edc) %}
  {%- for package in install.packages|default([], true) %}
    {%- if package and package not in packages %}
      {%- do packages.append(package) %}
      {%- if package not in services %}
        {%- do services.append(package) %}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endfor %}

{%- if zoomdata['erase'] %}
  {%- set installed = salt['zoomdata.list_pkgs'](include_edc=true, include_tools=true) %}
  {%- set services = zoomdata.local['packages'] + zoomdata.local.edc['packages'] %}
  {%- set uninstall = [] %}

  {%- for pkg in installed %}
    {% if pkg not in packages %}
      {%- do uninstall.append(pkg) %}
    {%- elif pkg in services %}
      {%- do services.remove(pkg) %}    
    {%- endif %}
  {%- endfor %}
{%- else %}
  {%- set uninstall = packages %}
{%- endif %}

{%- for service in services %}

{{ service }}_disable:
  service.dead:
    - name: {{ service }}
    - enable: False
    - require_in:
      - pkg: zoomdata-remove

{%- endfor %}

zoomdata-remove:
  pkg.removed:
    - pkgs: {{ uninstall }}
