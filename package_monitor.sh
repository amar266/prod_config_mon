#!/bin/bash
#Set a variable for time to check against the change,default is half an hour , so the last half an hour changes will be monitored
chtm=18000000
idc=0
#get current date
dt=`date +%Y-%m-%d`
#Get the data for current date 
datap=`grep "$dt" /var/log/dpkg.log | grep -E "\ install\ |\ remove\ |\ upgrade\ "|awk '{print $1","$2","$3","$4}'`
role=`hostname|cut -d"." -f1 | grep -o -E '[a-zA-Z]+'`
hstnm=`hostname|cut -d"." -f1`
for i in $datap
do
  dt=`echo $i|cut -d"," -f1`
  tm=`echo $i|cut -d"," -f2`
  act=`echo $i|cut -d"," -f3`
  pkg=`echo $i|cut -d"," -f4`
  pkgr=`echo $pkg|cut -d":" -f1`
  timest=`date --date="$dt $tm" +"%s"`
  ctimest=`date +"%s"`
  dif=`expr $ctimest - $timest`
  if [ $dif -lt $chtm ]
  then
     # In case of install
     peerversn=`salt-call  mine.get "$role* and not $hstnm*" pkg.list_pkgs compound| grep -A 1 $pkgr | grep -o -E "[0-9].*"|sort|uniq`
     case $act in
       install)
               #Get the current version of package
               versn=`dpkg -l | grep -E "\s$pkg\s" | awk '{print $3}'`
               if [ -z "$versn" ]
               then
                 versn=`dpkg -l | grep -E "\s$pkgr\s" | awk '{print $3}'`
               fi
               #check the current version of package in peer nodes
               if [ -z $peerversn ]
               then
                 echo "The $pkgr is newly installed in the node and it is not installed in peer node"
                 idc=1
               else
                 echo "$peerversn is not blank"
                 for i in $peerversn
                 do
                   if [ "$versn" != "$peerversn" ]
                   then
                     echo "The $pkgr is installed in peer node but of different version local version is $versn and peer version is $peerversn"
                     idc=1
                   fi
                 done
               fi 
               ;;
       upgrade)
               #Get the current version of package
               versn=`dpkg -l | grep -E "\s$pkg\s" | awk '{print $3}'`
               if [ -z "$versn" ]
               then
                 versn=`dpkg -l | grep -E "\s$pkgr\s" | awk '{print $3}'`
               fi
               #check the current version of package in peer nodes
               for i in $peerversn
               do
                 if [ "$versn" != "$peerversn" ]
                 then
                   echo "The $pkgr is upgraded , version with peer nodes is not matching, the  version local is $versn and peer has $peerversn"
                   idc=1
                 fi
                 
               done
               ;;
       remove)
               #check the package installed in peer nodes
               if [ -z "$peerversn" ]
               then
                 echo "The package is not available in peer nodes"
               else
                 echo "The $pkgr is removed from node and it is installed at peer nodes"
                 idc=1
               fi
               ;;
      esac
     
  fi
done

if [ "$idc" = 0 ]
then
  exit 0
else
  exit 1
fi
