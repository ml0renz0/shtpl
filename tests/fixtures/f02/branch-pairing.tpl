{% if 1 == 1 %}
{% if 1 == 2 %}
wrong-inner
{% else %}
inner-else
{% endif %}
outer-then
{% else %}
wrong-outer
{% endif %}
{% if 1 == 2 %}
wrong-second
{% else %}
second-else
{% endif %}
{% for value in a b %}
{% if $value == a %}
first=$value
{% else %}
second=$value
{% endif %}
{% endfor %}
