{% for i in 1 2 %}
{% if $i == 1 %}
{% if 1 == 2 %}
wrong
{% else %}
first=$i
{% endif %}
{% else %}
second=$i
{% endif %}
{% endfor %}
{% for j in A B %}
sibling=$j
{% endfor %}
