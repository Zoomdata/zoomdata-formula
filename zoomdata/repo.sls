{%- from 'zoomdata/map.jinja' import zoomdata with context %}
{%- import_yaml 'zoomdata/defaults.yaml' as defaults %}

{%- set repositories = [] %}
{%- set default_components = defaults.zoomdata['components'] %}
{%- if zoomdata['base_url'] and zoomdata['release'] %}
  {#- Create list of repos to make full OS dependent entries of them #}
  {%- set repositories = [zoomdata.release] +
                         zoomdata.repositories|default([], true) %}

  {#- Make sure components always have at lest default value.
      GPG key value should be always set, even to ``None`` or ``Null``. #}
  {%- do zoomdata.update({
    'components': zoomdata.components|default(default_components, true),
    'gpgkey': zoomdata.gpgkey|default(none, true),
  }) %}

# FIXME: provision and check sum for repo GnuPG pub key

  {%- if grains['os_family'] == 'Debian'
     and zoomdata.gpgkey %}

# FIXME: due to a bug in Salt 2017.7.2,
# some file downloads and remote hash verifications are broken
zoomdata-gpg-key-download:
  file.managed:
    - name: /tmp/zoomdata-gpg-key.asc
    - user: root
    - group: root
    - mode: 0644
    - contents: |
        {{ salt['http.query'](zoomdata.gpgkey)['body']|indent(8) }}

zoomdata-gpg-key:
  cmd.run:
    - name: mkdir -p /usr/share/keyrings && gpg --dearmor -o {{ zoomdata.repo_keyfile }} /tmp/zoomdata-gpg-key.asc
    - onchanges:
      - file: zoomdata-gpg-key-download
    - require:
      - file: zoomdata-gpg-key-download

  {%- endif %}

{%- else %}

zoomdata-repo-is-mission:
  test.show_notification:
    - text: |
        There is no Zoomdata repository URL and/or release (major) version provided.
        The repo configuration has been skipped.

{%- endif %}

{%- for repo in repositories %}
  {#- Populate configured components only for release repo #}
  {%- if repo == zoomdata.release %}
    {%- set components = zoomdata.components %}
  {%- else %}
    {%- set components = default_components %}
  {%- endif %}

  {%- if grains['os_family'] == 'Debian' %}
    {#- Update merged ``zoomdata`` dictionary with repo information on
        each iteration to reuse it in later state formatting #}
    {%- do zoomdata.update({
      'repo': repo,
      'components': components|join(' '),
    }) %}

    {%- if zoomdata.gpgkey %}
    {%- set _signed_by = '[signed-by=' ~ zoomdata.repo_keyfile ~ '] ' %}
    {%- else %}
    {%- set _signed_by = '' %}
    {%- endif %}

{{ zoomdata.repo_name|format(**zoomdata) }}:
  pkgrepo.managed:
    - name: deb {{ _signed_by }}{{ (zoomdata.repo_entry|format(**zoomdata))[4:] }}
    - file: {{ zoomdata.repo_file|format(**zoomdata) }}
    - clean_file: True
    {%- if zoomdata.gpgkey %}
    - require:
      - cmd: zoomdata-gpg-key
    {%- endif %}

  {%- elif grains['os_family'] == 'RedHat' %}
    {%- for component in components %}
      {#- Update merged ``zoomdata`` dictionary with repo information on
          each iteration to reuse it in later state formatting #}
      {%- do zoomdata.update({
        'repo': repo,
        'component': component,
      }) %}

{{ zoomdata.repo_name|format(**zoomdata) }}:
  pkgrepo.managed:
    - humanname: {{ zoomdata.repo_desc|format(**zoomdata) }}
    - baseurl: {{ zoomdata.repo_url|format(**zoomdata) }}
    {%- if zoomdata.gpgkey %}
    - gpgcheck: 1
    - gpgkey: {{ zoomdata.gpgkey }}
    {%- else %}
    - gpgcheck: 0
    {%- endif %}

    {%- endfor %}
  {%- endif %}
{%- endfor %}
