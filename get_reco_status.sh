#!/bin/bash

#Script for getting the reconstruction status
#Author: Abinash Pun Feb-2021

run_info=$1 # 'range' or 'run' or 'list'
range_1st=$2
range_last=$3

dir_scripts=$(dirname $(readlink -f $BASH_SOURCE))
dir_recofile=/pnfs/e1039/persistent/cosmic_recodata/

case ${run_info} in
    ##===============range================================================
    "range")
	
	for ((run_num=range_1st;run_num<=range_last;run_num++));
	do 
	    run_dir=($(printf 'run_%06d' $run_num) )
	    
	    ##no. of splits in corresponding run
  	    N_splits=$(ls /data2/e1039/dst/$run_dir/ | wc -l)
	
  	    reco_status=0
	    completed_dst=0

  	    if [ $N_splits -gt 1 ]; then #choose the runs with more than 1 splits only
  		N_GOOD_LOG=0
		reco_status=1
		#loop over the log files of the submitted runs
		for i in $dir_recofile/$run_dir/*/log/log.txt; do

		    [[ ! -e $i ]] && continue
		    
		    job_status=$(tail -1 "$i" | head -1) #reco_status from root -l {macro} command in gridrun_data.sh	
		    
		    #echo $job_status

		    if [ "$job_status" = "0" ]; then
			(( N_GOOD_LOG++ ))
		    fi
		done

		if [ $N_splits -eq $N_GOOD_LOG ]; then
		    reco_status=2
		fi
		completed_dst=$N_GOOD_LOG
	    fi
	    echo -e "${range_1st}\t${N_splits}\t${reco_status}\t${completed_dst}"
	    echo -e "Run number: ${range_1st}\tNo of split DSTs: ${N_splits}\tCompleted DSTs${completed_dst}"
	done	
	;;

    ##===============run================================================
    "run")
	run_dir=($(printf 'run_%06d' $range_1st) )
	
	##no. of splits in corresponding run
  	N_splits=$(ls /data2/e1039/dst/$run_dir/ | wc -l)

  	reco_status=0
	completed_dst=0

  	if [ $N_splits -gt 1 ]; then #choose the runs with more than 1 splits only
  	    N_GOOD_LOG=0
	    reco_status=1
	    #loop over the log files of the submitted runs
	    for i in $dir_recofile/$run_dir/*/log/log.txt; do
		#echo $i
		[[ ! -e $i ]] && continue
		
		job_status=$(tail -1 "$i" | head -1) #reco_status from root -l {macro} command in gridrun_data.sh	

		if [ "$job_status" = "0" ]; then
		    (( N_GOOD_LOG++ ))
		fi
	    done

	    if [ $N_splits -eq $N_GOOD_LOG ]; then
		reco_status=2
	    fi
	    completed_dst=$N_GOOD_LOG
	fi
	echo -e "${range_1st}\t${N_splits}\t${reco_status}\t${completed_dst}"
	echo -e "Run number: ${range_1st}\tNo of split DSTs: ${N_splits}\tCompleted DSTs: ${completed_dst}"
	;;

    ##===============list================================================    
    "list")

	
	while read run_num; do
	    run_dir=($(printf 'run_%06d' $run_num) )

	    #echo $run_dir
	    
	    ##no. of splits in corresponding run
  	    N_splits=$(ls /data2/e1039/dst/$run_dir/ | wc -l)
  	    #echo $N_splits

  	    reco_status=0
	    completed_dst=0
  	    if [ $N_splits -gt 1 ]; then #choose the runs with more than 1 splits only
  		N_GOOD_LOG=0
		reco_status=1
		#loop over the log files of the submitted runs
		for i in $dir_recofile/$run_dir/*/log/log.txt; do
		    #echo $i
		    [[ ! -e $i ]] && continue
		    
		    job_status=$(tail -1 "$i" | head -1) #reco_status from root -l {macro} command in gridrun_data.sh	
		    
		    #echo $job_status

		    if [ "$job_status" = "0" ]; then
			(( N_GOOD_LOG++ ))
		    fi
		done

		if [ $N_splits -eq $N_GOOD_LOG ]; then
		    reco_status=2
		fi
		completed_dst=$N_GOOD_LOG
	    fi
	    echo -e "${run_num}\t${N_splits}\t${reco_status}\t${completed_dst}"
	    echo -e "Run number: ${run_num}\tNo of split DSTs: ${N_splits}\tCompleted DSTs: ${completed_dst}"
	done <$range_1st
	;;
    #================status info===========================================	
    "status_info")
	echo "The reco status:"
	echo "	0 = Skipped"
	echo "	1 = Being processed"
	echo "	2 = Completed" 

	;;
    ##===============default================================================
    *)

	echo "Alert! Alert! " 
	echo "Please choose the 1st argument from, 'range', 'run' & 'list' and if it is" 
	echo "a) range: 2nd and 3rd argument should define the range of the runs"
	echo "b) run:   2nd argument should be run number"
	echo "c) list:  2nd arguement should be the list of runs"

esac 
