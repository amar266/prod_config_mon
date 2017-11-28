#!/bin/bash
#Set a variable for time to check against the change,default is half an hour , so the last half an hour changes will be monitored
chtm=1800
#get current date
dt=`date +%Y-%m-%d`
#Get the data for current date 
datap=`grep "$dt" /var/log/dpkg.log | grep -E "\ install\ |\ remove\ |\ upgrade\ "|awk '{print $1","$2","$3","$4}'`

for i in $datap
do
  dt=`echo $i|cut -d"," -f1`
  tm=`echo $i|cut -d"," -f2`
  act=`echo $i|cut -d"," -f3`
  pkg=`echo $i|cut -d"," -f4`
  timest=`date --date="$dt $tm" +"%s"`
  ctimest=`date +"%s"`
  dif=`expr $ctimest - $timest`
  if [ $dif -lt $chtm ]
  then
     #send alert
     echo "$act action has been done for Package $pkg on $dt $tm "
  fi
  #convert date and time to time stamp
done
