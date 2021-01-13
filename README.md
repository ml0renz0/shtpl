# shtpl
**SHell TemPLating**

[`shtpl`](shtpl) is a templating tool that uses a [jinja-style syntax](shtpl.test) (but waaaaay simpler) to generate text files:

```
# ./shtpl < shtpl.test
VARIABLE EXPANDING:
$HOSTNAME: myhostname

DOUBLE-QUOTES
# This line does NOT have "double quotes"
# This line contains \"double quotes\"
This line does NOT have double quotes
This line contains "double quotes"

IF-ELSE-BLOCK:
# {{ A_RANDOM=$RANDOM }}
# {% if $(( $A_RANDOM%2 )) == 0 %}
# $A_RANDOM is even
# {% else %}
# $A_RANDOM is odd
# {% endif %}
30001 is odd

VARIABLE DEFINITION:
# {{ aux=4 }}
# {{ myarray=( a b c d ) }}
# \$aux: $aux
# \$myarray[@]: ${myarray[@]}

$aux: 4
$myarray[@]: a b c d

SUBSHELL:
# "$(uptime | tr -d '\n')" => "$(uptime | tr -d '\n')"
"$(uptime | tr -d '\n')" => " 17:05:19 up 9 days,  8:35,  1 user,  load average: 1,96, 3,85, 3,76"

ARITHMETIC OPERATIONS:
# "$(( 2%2+1 ))" => "$(( 2%2+1 ))"
"$(( 2%2+1 ))" => "1"

FOR-BLOCK:
# {% for (( c=1; c<=$aux; c++ )) %}
# c=$c
# {% endfor %}
c=1
c=2
c=3
c=4

FOR-BLOCK NESTED IN IF-ELSE-BLOCK:
# {% if $aux == 4 %}
# {% for n in 1 2 3 $aux %}
# \$myarray[$((n-1))]: ${myarray[$((n-1))]}
# /etc/passwd field #$n: $(grep $USER /etc/passwd | cut -d: -f$n)
# {% endfor %}
# {% else %}
# {% for n in {1..2} %}
# \$myarray[$((n-1))]: ${myarray[$((n-1))]}
# /etc/group field #$n: $(grep $USER /etc/group | cut -d: -f$n)
# {% endfor %}
# {% endif %}

$myarray[0]: a
/etc/group field #1: myusername
$myarray[1]: b
/etc/group field #2: x
$myarray[2]: c
/etc/group field #3: 1001
$myarray[3]: d
/etc/group field #4:


IF-ELSE-BLOCK NESTED IN FOR-BLOCK:
# {{ myarray2=( 1 2 3 4 ) }}
# {% for i in ${myarray2[@]} %}
# {% if $(( i%2 )) == 0 %}
# even index: \$myarray[$i]: ${myarray[$((i-1))]}
# {% else %}
# odd  index: \$myarray[$i]: ${myarray[$((i-1))]}
# {% endif %}
# {% endfor %}
odd  index: $myarray[1]: a
even index: $myarray[2]: b
odd  index: $myarray[3]: c
even index: $myarray[4]: d

CHECK IT PRINTS LAST LINE:
#$
