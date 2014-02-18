# Maris ELsins, Pythian, 2013
# Real memory footprint for all processes.
# Not perfectly accurate, but "good enough"
# 
# the output is like :
# ...
# 
# 22808: 34680 KB
# 8710: 37852 KB
# 8714: 37924 KB
# 8722: 37924 KB
# 8663: 70208 KB
# 28837: 335556 KB

ls -1d /proc/[1-9]* | xargs -n 1 basename | while read PPP
do
echo -n "$PPP: "
ANONS=`pmap -x $PPP | grep "^00" | grep "\[ anon \]" | awk '{print $4}' | paste -sd+ | bc`
NONANONS=`pmap -x $PPP | grep "^00" | grep -v -e "\[ anon \]" -e "\[ shmid=" | awk '{print $3}' | paste -sd+ | bc`
[ -z $ANONS ] && ANONS=0; [ -z $NONANONS ] && NONANONS=0
echo `expr $ANONS + $NONANONS` "KB"
done | sort -k2n
