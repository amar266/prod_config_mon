#!/bin/bash

#Get all changes
cd /srv/salt/reclass
chngs=`git status --porcelain | grep -E "^\sM|^\sD|^\?\?" | awk '{print $1","$2}'`
if [ -z "$chngs" ]
then
  echo "There is no change in reclass"
  exit 0
else
  for i in $chngs
    do
      action=`echo $i | cut -d"," -f1`
      filen=`echo $i | cut -d"," -f2`
      if [ "$action" = "M" ]
      then
        #get the changed data and prepare variable to send alert
        diffd=`git diff /srv/salt/reclass/$filen | grep -E "^(\+|-)[^-][^\+].*"`
        echo "The file /etc/$filen has been Modified \n"
        echo "$diffd\n"
      elif [ "$action" = "D" ]
      then
        echo "The file $filen has been Deleted \n"
      elif [ "$action" = "??" ]
      then
        echo "The file $filen is newly added \n"
      fi
  done
exit 1
fi
