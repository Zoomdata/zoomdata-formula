{%- from 'zoomdata/map.jinja' import zoomdata with context %}

{%- if grains['os_family'] == 'Debian' %}

  {%- set repo_url = (zoomdata.base_url,
                      zoomdata.release,
                      'apt',
                      grains['os'] | lower())
                      |join('/') %}

zoomdata-repo:
  pkgrepo.managed:
    - name: {{ ('deb', repo_url, grains['oscodename'], 'stable')|join(' ') }}
    - humanname: Zoomdata {{ zoomdata.release }} stable APT repository
    - file: {{ zoomdata.repo_file }}
  {%- if zoomdata.gpgkey %}
    - key_url: {{ zoomdata.gpgkey }}
  {%- endif %}

{%- elif grains['os_family'] == 'RedHat' %}

  {%- set repo_url = (zoomdata.base_url,
                      zoomdata.release,
                      'yum',
                      grains['os_family'] | lower(),
                      grains['osmajorrelease'],
                      grains['osarch'],
                      'stable')
                      |join('/') %}

zoomdata-repo:
  pkgrepo.managed:
    - name: zoomdata-{{ zoomdata.release }}
    - humanname: Zoomdata {{ zoomdata.release }} stable RPMs
    - baseurl: {{ repo_url }}
  {%- if zoomdata.gpgkey %}
    - gpgcheck: 1
    - gpgkey: {{ zoomdata.gpgkey }}
  {%- else %}
    - gpgcheck: 0
  {%- endif %}

{%- endif %}
