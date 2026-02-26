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

{#- Use modern APT keyring (signed-by + gpg --dearmor) only on Ubuntu 24.04 and later.
    The ``osmajorrelease`` grain returns the integer year part (e.g. 24 for Ubuntu 24.04). #}
{%- set use_modern_keyring = grains['os_family'] == 'Debian' and
                             grains['os'] == 'Ubuntu' and
                             grains['osmajorrelease']|int >= 24 %}

# FIXME: provision and check sum for repo GnuPG pub key

  {%- if grains['os_family'] == 'Debian'
     and zoomdata.gpgkey
     and not use_modern_keyring %}

# FIXME: due to a bug in Salt 2017.7.2,
# some file downloads and remote hash verifications are broken
zoomdata-gpg-key:
  file.managed:
    - name: {{ zoomdata.repo_keyfile }}
    - makedirs: True
    - user: root
    - group: root
    - mode: 0444
    - contents: |
        {{ salt['http.query'](zoomdata.gpgkey)['body']|indent(8) }}

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

    {%- if zoomdata.gpgkey and use_modern_keyring %}
    {#- Per-repo key URL: use gpgkeys dict if a specific key is configured for
        this repo, otherwise fall back to the global gpgkey. #}
    {%- set _repo_keyurl = (zoomdata.gpgkeys|default({}, true)).get(repo, zoomdata.gpgkey) %}
    {%- set _repo_keyfile = zoomdata.repo_keyfile|format(**zoomdata) %}
    {%- set _signed_by = '[signed-by=' ~ _repo_keyfile ~ '] ' %}

zoomdata-gpg-key-download-{{ repo }}:
  file.managed:
    - name: /tmp/zoomdata-{{ repo }}-gpg-key.asc
    - user: root
    - group: root
    - mode: 0644
    - contents: |
        {{ salt['http.query'](_repo_keyurl)['body']|indent(8) }}

zoomdata-gpg-key-{{ repo }}:
  cmd.run:
    - name: mkdir -p /usr/share/keyrings && gpg --dearmor -o {{ _repo_keyfile }} /tmp/zoomdata-{{ repo }}-gpg-key.asc
    - creates: {{ _repo_keyfile }}
    - onchanges:
      - file: zoomdata-gpg-key-download-{{ repo }}
    - require:
      - file: zoomdata-gpg-key-download-{{ repo }}

    {%- else %}
    {%- set _signed_by = '' %}
    {%- endif %}

{{ zoomdata.repo_name|format(**zoomdata) }}:
  pkgrepo.managed:
    - name: deb {{ _signed_by }}{{ (zoomdata.repo_entry|format(**zoomdata))[4:] }}
    - file: {{ zoomdata.repo_file|format(**zoomdata) }}
    - clean_file: True
    {%- if zoomdata.gpgkey %}
    {%- if use_modern_keyring %}
    - require:
      - cmd: zoomdata-gpg-key-{{ repo }}
    {%- else %}
    - key_url: file://{{ zoomdata.repo_keyfile }}
    - require:
      - file: zoomdata-gpg-key
    {%- endif %}
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
