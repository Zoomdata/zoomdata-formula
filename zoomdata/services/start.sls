{%- from 'zoomdata/map.jinja' import init_available,
                                     packages,
                                     zoomdata with context %}

{%- if init_available %}

  {%- if salt['test.provider']('service') == 'systemd' %}

systemctl_reload:
  module.wait:
    - name: service.systemctl_reload

  {%- endif %}

  {%- for service in packages %}

    {%- if service in zoomdata['services'] %}

{{ service }}_start_enable:
  {%- if service == 'zoomdata-edc-all' %}
  zoomdata.edc_running:
  {%- else %}
  service.running:
  {%- endif %}
    - name: {{ service }}
    - enable: True
  {%- if service.startswith('zoomdata-edc-') and zoomdata.edc.probe['timeout'] %}
    {%- if service != 'zoomdata-edc-all' %}
  zoomdata.service_probe:
    - name: {{ service }}
    {%- endif %}
    - url_path: {{ zoomdata.edc.probe['path'] }}
    - timeout: {{ zoomdata.edc.probe['timeout'] }}
  {%- endif %}

    {%- endif %}

  {%- endfor %}

{%- else %}

# Try to enable Zoomdata services in "manual" way if Salt ``service`` state
# module is currently not available (e.g. during Docker or Packer build when
# there is no init system running).

  {%- for service in packages %}

{{ service }}_start_enable:
  cmd.run:
    {%- if salt['file.file_exists']('/bin/systemctl') %}
    - name: systemctl enable {{ service }}
    {%- elif salt['cmd.which']('chkconfig') %}
    - name: chkconfig {{ service }} on
    {%- elif salt['file.file_exists']('/usr/sbin/update-rc.d') %}
    - name: update-rc.d {{ service }} defaults
    {%- else %}
    # Nothing to do
    - name: 'true'
    {%- endif %}

  {%- endfor %}

{%- endif %}
