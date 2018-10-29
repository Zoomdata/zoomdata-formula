{%- if header %}
{{- header|trim }}
{# blank line inserted here #}
{%- endif -%}
{%- for key, value in environment|dictsort() %}
    {%- if value is none %}
        {%- set value = '' %}
    {%- endif %}
{{ key }}="{{ value }}"
{%- endfor %}

{#- vim: ft=jinja sw=4 sts=4 et
VIM modeline should end with newline -#}
