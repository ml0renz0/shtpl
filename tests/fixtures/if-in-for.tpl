{% for i in 1 2 3 %}
{% if $((i%2)) == 0 %}
even=$i
{% else %}
odd=$i
{% endif %}
{% endfor %}
