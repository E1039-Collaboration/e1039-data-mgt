#!/bin/bash 
#A master script to copy the decoded runs from /data2/ area and run it in grid
#Author: Abinash pun

#variables to use the updated proxy certificate
export ROLE=Analysis
export X509_USER_PROXY=/var/tmp/${USER}.${ROLE}.proxy


DIR_SCRIPTS=$(dirname $(readlink -f $BASH_SOURCE))
FILE_RECO_STAT=$DIR_SCRIPTS/reco_status.txt

#grid setup script
source /e906/app/software/script/setup-jobsub-spinquest.sh

##list out all the decoded runs and save the runid (by kenichi)
mysql --defaults-file=/data2/e1039/resource/db_conf/my_db1.cnf     --batch --skip-column-names     --execute='select run_id from deco_status where deco_status = 2 order by run_id desc'     user_e1039_maindaq >$DIR_SCRIPTS/list.txt

##find out the difference between the two list and copy it to pnfs/e1039/tape_backed/decoded_data area
grep -vxf $DIR_SCRIPTS/list_hold.txt $DIR_SCRIPTS/list.txt >$DIR_SCRIPTS/run_list.txt

##Loop over new decoded data
while read RunNum; do
  
  RUN_DIR=($(printf 'run_%06d' $RunNum) )
  echo $RUN_DIR

  UNSPLIT_FILE=($(printf 'run_%06d_spin.root' $RunNum) ) 
 
  ##no. of splits in corresponding run
  N_splits=$(ls /data2/e1039/dst/$run_dir/ | wc -l)
  echo $N_splits

  reco_status=0
  if [ $N_splits -gt 1 ]; then #choose the runs with more than 1 splits only

    #Copy the decoded data to tape_backed area, now handeled in e906-gat1 account

    #Submit the grid job
    $DIR_SCRIPTS/gridsub_data.sh $RUN_DIR 1 $RunNum 0 splitting 

    reco_status=1    
          
  fi 

 paste <(echo "$RunNum") <(echo "$N_splits") <(echo "$reco_status")>>$FILE_RECO_STAT

done <$DIR_SCRIPTS/run_list.txt

##update the holding list
cat $DIR_SCRIPTS/run_list.txt >>$DIR_SCRIPTS/list_hold.txt

