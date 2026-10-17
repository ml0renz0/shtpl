{{ FLAG=yes }}
{% if $FLAG == yes %}
{% for i in a b %}
item=$i
{% endfor %}
{% else %}
not-selected
{% endif %}
