{%- if header %}
{{- header|trim }}
{# blank line inserted here #}
{%- endif -%}
{%- for key, value in environment|dictsort() %}
    {%- if value is none %}
        {%- set value = '' %}
    {%- endif %}
    {%- if key == 'DISCOVERY_REGISTRY_HOST' %}
{{ key }}={{ value }}
    {%- else %}
{{ key }}="{{ value }}"
    {%- endif %}
{%- endfor %}

{#- vim: ft=jinja sw=4 sts=4 et
VIM modeline should end with newline -#}
