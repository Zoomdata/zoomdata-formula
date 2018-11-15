{%- from 'zoomdata/map.jinja' import zoomdata -%}

{%- set packages = zoomdata['packages'] +
                   zoomdata.edc['packages'] +
                   zoomdata.microservices['packages'] +
                   zoomdata.tools['packages'] %}

{%- if zoomdata['erase'] %}
  {%- set installed = salt['zoomdata.list_pkgs']() %}
  {%- set uninstall = [] %}

  {%- for pkg in installed %}
    {%- if pkg not in packages %}
      {%- do uninstall.append(pkg) %}
    {%- endif %}
  {%- endfor %}
{%- else %}
  {%- set uninstall = packages %}
{%- endif %}

zoomdata-remove:
  pkg.removed:
    - pkgs: {{ uninstall|yaml() }}
