{%- if header %}
{{- header|trim }}

{# blank line inserted here #}
{%- endif -%}
# See https://www.zoomdata.com/docs/{{ release }}/zoomdata-configuration-property-files-and-their-corresponding-variables.html
{# blank line inserted here #}
{%- for key, value in environment|dictsort() %}
    {%- if value is none %}
        {%- set value = '' %}
    {%- endif %}
{{ key }}="{{ value }}"
{%- endfor %}

{#- vim: ft=jinja sw=4 sts=4 et
VIM modeline should end with newline -#}