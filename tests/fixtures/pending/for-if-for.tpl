{% for i in 1 2 %}
{% if $i == 1 %}
{% for j in a b %}
$i$j
{% endfor %}
{% endif %}
{% endfor %}
