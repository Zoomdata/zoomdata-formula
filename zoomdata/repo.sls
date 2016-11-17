{%- from 'zoomdata/map.jinja' import zoomdata with context %}

{%- if not zoomdata.components %}
  {%- do zoomdata.update({'components': ['stable']}) %}
{%- endif %}

{%- if grains['os_family'] == 'Debian' %}

  {%- set repo_url = (zoomdata.base_url,
                      zoomdata.release,
                      'apt',
                      grains['os'] | lower())
                      |join('/') %}

{{ ('zoomdata', zoomdata.release, 'repo')|join('-') }}:
  pkgrepo.managed:
    - name: {{ (['deb', repo_url, grains['oscodename']] +
               zoomdata.components)|join(' ') }}
    - file: {{ zoomdata.repo_file }}
  {%- if zoomdata.gpgkey %}
    - key_url: {{ zoomdata.gpgkey }}
  {%- endif %}
    - clean_file: True

{%- elif grains['os_family'] == 'RedHat' %}

  {%- set repo_url = (zoomdata.base_url,
                      zoomdata.release,
                      'yum',
                      grains['os_family'] | lower(),
                      grains['osmajorrelease'],
                      grains['osarch'])
                      |join('/') %}

  {%- for component in zoomdata.components %}

{{ ('zoomdata', zoomdata.release, component)|join('-') }}:
  pkgrepo.managed:
    - humanname: {{ ('Zoomdata', zoomdata.release, component, 'for',
                    grains['os'], grains['osmajorrelease'], '-', grains['osarch'])
                    |join(' ') }}
    - baseurl: {{ (repo_url, component)|join('/') }}
    {%- if zoomdata.gpgkey %}
    - gpgcheck: 1
    - gpgkey: {{ zoomdata.gpgkey }}
    {%- else %}
    - gpgcheck: 0
    {%- endif %}

  {%- endfor %}

{%- endif %}
