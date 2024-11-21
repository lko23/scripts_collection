#!/bin/bash
temp_file="/tmp/tmp_sid_lookup.txt"
output_file="/data/loki/loki_lookup/lookup_sid_user.txt"
letters="a b c d e f g h i j k l m n o p q r t u v w x y z"

rm -f $temp_file $output_file
echo "UserID,User" >> $output_file
echo "S-1-5-18,system" >> $output_file

#ldap search for admins and split User S
ldapsearch -H ldap://domain.tld -D "user@domain.tld" -w secure-password -b "OU=aaa,OU=bbb,OU=ccc,DC=domain,DC=tld" -S sAMAccountName sAMAccountName objectSid | grep 'objectSid:: \|sAMAccountName: ' >> "$temp_file"

ldapsearch -H ldap://domain.tld -D "user@domain.tld" -w secure-password -b "OU=aaa,OU=bbb,OU=ccc,DC=domain,DC=tld" "(&(objectClass=user)(cn=sch*))" -S sAMAccountName sAMAccountName objectSid | grep 'objectSid:: \|sAMAccountName: ' >> "$temp_file"
ldapsearch -H ldap://domain.tld -D "user@domain.tld" -w secure-password -b "OU=aaa,OU=bbb,OU=ccc,DC=domain,DC=tld" "(&(objectClass=user)(cn=s*)(!(cn=sch*)))" -S sAMAccountName sAMAccountName objectSid | grep 'objectSid:: \|sAMAccountName: ' >> "$temp_file"

# iterate over standard users letter by letter
for letter in $letters
do
        ldapsearch -H ldap://domain.tld -D "user@domain.tld" -w secure-password -b "OU=aaa,OU=bbb,OU=ccc,DC=domain,DC=tld" "(&(objectClass=user)(cn=$letter*))" -S sAMAccountName sAMAccountName objectSid | grep 'objectSid:: \|sAMAccountName: ' >> "$temp_file"
done

#convert base64 to human readable SID
while IFS= read -r line
do
line_array=($line)
        if [[ ${line_array[0]} == "objectSid::" ]];
        then
                G=($(echo -n ${line_array[1]} | base64 -d -i | hexdump -v -e '1/1 " %02X"'))
                BESA2=${G[8]}${G[9]}${G[10]}${G[11]}
                BESA3=${G[12]}${G[13]}${G[14]}${G[15]}
                BESA4=${G[16]}${G[17]}${G[18]}${G[19]}
                BESA5=${G[20]}${G[21]}${G[22]}${G[23]}
                BERID=${G[24]}${G[25]}${G[26]}${G[27]}${G[28]}

                LESA1=${G[2]}${G[3]}${G[4]}${G[5]}${G[6]}${G[7]}
                LESA2=${BESA2:6:2}${BESA2:4:2}${BESA2:2:2}${BESA2:0:2}
                LESA3=${BESA3:6:2}${BESA3:4:2}${BESA3:2:2}${BESA3:0:2}
                LESA4=${BESA4:6:2}${BESA4:4:2}${BESA4:2:2}${BESA4:0:2}
                LESA5=${BESA5:6:2}${BESA5:4:2}${BESA5:2:2}${BESA5:0:2}
                LERID=${BERID:6:2}${BERID:4:2}${BERID:2:2}${BERID:0:2}

                printf "S-1-%u-%u-%u-%u-%u-%u\n" $(( 16#$LESA1 )) $(( 16#$LESA2 )) $(( 16#$LESA3 )) $(( 16#$LESA4 )) $(( 16#$LESA5 )) $(( 16#$LERID )) >> $output_file
        else
                echo $line >> $output_file
        fi
done < "$temp_file"

#re-write to space separated output
sed -i -z -E 's/\nsAMAccountName: /,/g' $output_file
