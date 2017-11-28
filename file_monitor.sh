#!/bin/bash

#Set a variable for time to check against the change,default is half an hour , so the last half an hour changes will be monitored
chtm=1800
#Get all changed file names
files=`etckeeper vcs status --porcelain | grep -E "^\sM|^\sD|^AD|^\?\?" | awk '{print $1","$2}'`
if [ -z "$files" ]
then
  echo "There is no change in config files"
else
  for i in $files
    do
      #get the last modified time of file
      action=`echo $i | cut -d"," -f1`
      filen=`echo $i | cut -d"," -f2`
      if [ "$action" = "M" ]
      then
        timest=`date +"%s"`
        lastm=`stat -c %Y  /etc/$filen`
        dif=`expr $timest - $lastm`
        if [ $dif -lt $chtm ]
        then
          #The file has been changed half an hour ago 
          #get the changed data and prepare variable to send alert
          diffd=`etckeeper vcs diff /etc/$filen | grep -E "^(\+|-)[^-][^\+].*"`
          echo "The file /etc/$filen has been Modified \n"
          echo "$diffd\n"
        fi
      elif [ "$action" = "D" ]
      then
        echo "The file /etc/$filen has been Deleted \n"
      elif [ "$action" = "AD" ]
      then
        echo "The file /etc/$filen has been Added \n"
      elif [ "$action" = "??" ]
      then
        echo "The file /etc/$filen is untracted \n"
      fi
  done
fi
