{%- from 'zoomdata/map.jinja' import zoomdata with context %}

{%- if zoomdata.base_url and zoomdata.release %}

  {%- if not zoomdata.components %}
    {%- do zoomdata.update({'components': ['stable']}) %}
  {%- endif %}

  {%- if grains['os_family'] == 'Debian' %}

    {%- set repo_url = (zoomdata.base_url,
                        zoomdata.release,
                        'apt',
                        grains['os'] | lower())
                        |join('/') %}
    {%- set tools_repo_url = (
                    zoomdata.base_url,
                    'tools',
                    'apt',
                    grains['os']|lower())
                    |join('/') %}

    {%- if zoomdata.gpgkey %}

      {%- set keyfile = salt['file.join'](
                        '/etc/zoomdata',
                        salt['file.basename'](zoomdata.gpgkey)) %}

zoomdata-gpg-key:
  file.managed:
    - name: {{ keyfile }}
    - makedirs: True
    - user: root
    - group: root
    - mode: 0444
    # FIXME: due to a bug in Salt 2017.7.2,
    # some file downloads and remote hash verifications are broken
    - contents: |
        {{ salt['http.query'](zoomdata.gpgkey)['body']|indent(8) }}

    {%- endif %}

{{ ('zoomdata', zoomdata.release, 'repo')|join('-') }}:
  pkgrepo.managed:
    - name: {{ (['deb', repo_url, grains['oscodename']] +
               zoomdata.components
               )|join(' ') }}
    - file: {{ zoomdata.repo_file }}
    - clean_file: True
    {%- if keyfile is defined %}
    - key_url: file://{{ keyfile }}
    - require:
      - file: zoomdata-gpg-key
    {%- endif %}

zoomdata-tools:
  pkgrepo.managed:
    - name: {{ ('deb',
                 tools_repo_url,
                 grains['oscodename'],
                 'stable',
               )|join(' ') }}
    - file: {{ zoomdata.tools_repo_file }}
    - clean_file: True
    {%- if keyfile is defined %}
    - key_url: file://{{ keyfile }}
    - require:
      - file: zoomdata-gpg-key
    {%- endif %}

  {%- elif grains['os_family'] == 'RedHat' %}

# FIXME: provision and check sum for repo GnuPG pub key

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

zoomdata-tools:
  pkgrepo.managed:
    - humanname: {{ ('Zoomdata tools for', grains['os'], grains['osmajorrelease'], '-', grains['osarch'])|join(' ') }}
    - baseurl: {{ (zoomdata.base_url, 'tools', 'yum', grains['os_family'] | lower(), grains['osmajorrelease'], grains['osarch'], 'stable') |join('/') }}
    {%- if zoomdata.gpgkey %}
    - gpgcheck: 1
    - gpgkey: {{ zoomdata.gpgkey }}
    {%- else %}
    - gpgcheck: 0
    {%- endif %}

  {%- endif %}

{%- else %}

zoomdata-repo-is-mission:
  test.show_notification:
    - text: |
        There is no Zoomdata repository URL and/or release (major) version provided.
        The repo configuration skipped.

{%- endif %}
