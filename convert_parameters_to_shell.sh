# Source all parameters
awk -F, 'NF && $1!~/^#/ { printf "%s='\''%s'\''\n", $1, $2}' ${1}