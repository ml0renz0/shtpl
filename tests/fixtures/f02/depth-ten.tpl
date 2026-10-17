{% for outer in A B %}
{% if $outer == A %}
{% for a in 1 2 %}
{% if $a == 1 %}
{% for b in x y %}
{% if $b == x %}
{% for c in 7 8 %}
{% if $c == 7 %}
{% for d in m n %}
{% if $d == m %}
deep=$outer$a$b$c$d
{% else %}
leaf=$outer$a$b$c$d
{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
{% else %}
outer=$outer
{% endif %}
{% endfor %}
