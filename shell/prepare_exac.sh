#####################################################
# Jenica Abrudan, NIPM V1.0 09/21/2016              #
#####################################################
#!/usr/bin/env bash -x

IFS=$'\n';
declare -A HEADERS   
for line in $(cat $1);
do
   CNAME=$(echo $line | cut -f 1 );
   CORDER=$(echo $line | cut -f 2 );
   CCLASS=$(echo $line | cut -f 3 );
   if [ -n "${HEADERS[$CCLASS] + 1}" ]; then
      HEADERS[$CCLASS]+=( ["number"]=$CORDER ["header"]=$CNAME)
   else
   HEADERS +=( ["class"]=$CCLASS ["number"]=$CORDER ["header"]=$CNAME)      
   fi
done;

echo ${HEADERS["class"]} " ";