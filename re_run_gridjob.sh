#!/bin/bash
#Script for reusbmission of failed grid jobs (bad job nodes and mysql server error)
#Author: Abinash Pun


##variables to use the updated proxy certificate
export ROLE=Analysis
export X509_USER_PROXY=/var/tmp/${USER}.${ROLE}.proxy

source /e906/app/software/script/setup-jobsub-spinquest.sh

dir_scripts=$(dirname $(readlink -f $BASH_SOURCE))
dir_recofile=/pnfs/e1039/persistent/cosmic_recodata #/pnfs/e1039/scratch/cosmic_reco_dst

##loop over submitted runs after ~1 hour of job submission
while read -r RunNum N_splits reco_status submission_freq; do
    
    #    [[ $reco_status -ne 1 ]] && continue  #only checks the uncompleted runs
    #    [[ $submission_freq -gt 5 ]] && continue # Not more than 5 resubmission
    if [[ $reco_status -eq 1 && $submission_freq -lt 5 ]]; then   
	run_dir=($(printf 'run_%06d' $RunNum) )
	N_GOOD_LOG=0
	
	##loop over the log files of the submitted runs
	for i in $dir_recofile/$run_dir/$run_dir*; do
	    echo $i

	    resub_file_base=$(basename $i)
	    echo $resub_file_base 
	    resub_file=$resub_file_base'.root'
            echo $resub_file

	    ##look at the job id corresponding to resub_file_base with no log file and check status and resubmit
	    if [ ! -e $i/log/log.txt ]; then

		while read -r job_name job_id; do

  		    if [ $job_name == $resub_file_base ]; then
			printf "%s\n" "job ID: $job_id"
			JOB_STATUS=$(jobsub_q --jobid $job_id | awk -v i=2 -v j=5 'FNR == i {print $j}')

			if [ -z "$JOB_STATUS" ]; then 
		    	    #remove the row with job_id before resubmitting(will be assigned new job_id)
		    	    sed -i '/$job_id/d' .$dir_scripts/jobid_info.txt

			    printf "JOB_STATUS is NULL with no log.txt file, Resubmitting .....%s\n"
			    echo $resub_file
			    $dir_scripts/gridsub_data.sh $run_dir 1 $RunNum 0 splitting $resub_file
			    #(( submission_freq++ ))
			fi 
		    fi
		done < $dir_scripts/jobid_info.txt	    

            else

		job_status=$(tail -1 "$i/log/log.txt" | head -1) #reco_status from root -l {macro} command in gridrun_data.sh	
		
		echo $job_status

		if [ "$job_status" = "0" ]; then
		    (( N_GOOD_LOG++ ))
		fi

		if  ! grep -q 'gridrun.sh finished!' $i/log/log.txt || [ "$job_status" != "0" ]; then	
	
            	    #remove the log and output files if any   
		    rm $dir_recofile/$run_dir/$resub_file_base/log/log.txt
		    rm $dir_recofile/$run_dir/$resub_file_base/out/*.root

		    #resubmit the grid job
		    echo "Error while running the macro, Resubmitting ...."
		    echo $resub_file
		    $dir_scripts/gridsub_data.sh $run_dir 1 $RunNum 0 splitting $resub_file
		    #(( submission_freq++ ))
		fi

            fi
	done	        
	(( submission_freq++ ))
    fi
    
    if [ $N_splits -eq $N_GOOD_LOG ]; then
	reco_status=2
    fi
    
    paste <(echo "$RunNum") <(echo "$N_splits") <(echo "$reco_status") <(echo "$submission_freq")>>$dir_scripts/reco_status_tmp.txt
    
done <$dir_scripts/reco_status.txt

#update the reco_status
mv $dir_scripts/reco_status_tmp.txt $dir_scripts/reco_status.txt
