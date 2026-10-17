{% if 1 == 1 %}
{% else %}
wrong
{% endif %}
{% if 1 == 2 %}
wrong
{% else %}
{% endif %}
{% for i in 1 2 %}
{% if $i == 1 %}
{% else %}
{% endif %}
{% endfor %}
{% for x in a b %}
{% endfor %}
empty-blocks-ok
