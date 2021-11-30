# Source all parameters
awk -F, 'NF && $1!~/^#/ { print $1"='"$2"'"}' ${1}