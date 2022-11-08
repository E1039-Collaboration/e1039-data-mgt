#!/bin/bash
#Author: Abinash pun
#grid submmiting script

dir_macros=$(dirname $(readlink -f $BASH_SOURCE))
LIFE_TIME=medium # short (3h), medium (8h) or long (23h)

jobname=$1
do_sub=$2
run_name=$3
nevents=$4
dst_mode=${5:-'splitting'} # 'splitting' or 'single'
resub_file=${6:-'null'} #file for resubmitting run

echo $resub_file

if [ $do_sub == 1 ]; then
    echo "Grid mode."
    if ! which jobsub_submit &>/dev/null ; then
	echo "Command 'jobsub_submit' not found."
	echo "Forget 'source /e906/app/software/script/setup-jobsub-spinquest.sh'?"
	exit
    fi
    #work=/pnfs/e1039/scratch/cosmic_reco_dst/$jobname
    work=/pnfs/e1039/persistent/cosmic_recodata/$jobname
else
    echo "Local mode."
    work=$dir_macros/scratch/$jobname
fi

##location of the decoded data
#data_dir="/pnfs/e1039/tape_backed/decoded_data"
data_dir="/pnfs/e1039/scratch/cosmic_decoded_dst"

if [ "$resub_file" = "null" ]; then

    mkdir -p $work
    chmod -R 01755 $work

    echo $work
    echo $dir_macros

    tar -C $dir_macros -czvf $work/input.tar.gz geom.root RecoE1039Data.C

    ##declare -a data_path_list=()
    #if [ $dst_mode = 'single' ] ; then
    #	data_path_list=( $data_dir/$(printf 'run_%06d_spin.root' $run_name) )
    #else # 'splitting'     
	data_path_list=( $(find $data_dir -name $(printf 'run_%06d_spill_*_spin.root' $run_name) ) )
	echo $data_path_list
    #fi

else
 
    data_path_list=( $(find $data_dir -name  $resub_file ) )
   
fi #resub_file condition

for data_path in ${data_path_list[*]} ; do
    
    data_file=$(basename $data_path)
    job_name=${data_file%'.root'}
    echo $data_file
    echo $job_name

    if [ "$resub_file" = "null" ]; then
	mkdir -p $work/$job_name/log
	mkdir -p $work/$job_name/out
	chmod -R 01755 $work/$job_name
    fi
    
    rsync -av $dir_macros/gridrun_data.sh $work/$job_name/gridrun_data.sh

    if [ $do_sub == 1 ]; then
        CMD="/e906/app/software/script/jobsub_submit_spinquest.sh"
        CMD+=" --expected-lifetime='$LIFE_TIME' --memory=2GB"
	CMD+=" --mail_never"
        CMD+=" --lines '+FERMIHTC_AutoRelease=True'"
        CMD+=" --lines '+FERMIHTC_GraceLifetime=7200'" #2 hours of grace lifetime
        CMD+=" --lines '+FERMIHTC_GraceMemory=1024'" #1GB of grace memory
	CMD+=" -L $work/$job_name/log/log.txt"
	CMD+=" -f $work/input.tar.gz"
	CMD+=" -d OUTPUT $work/$job_name/out"
	CMD+=" -f $data_path"
	CMD+=" file://`which $work/$job_name/gridrun_data.sh` $nevents $run_name $data_file"
	echo "$CMD"
	$CMD #| tee $work/$job_name/log_jobsub_submit.txt
    else
	mkdir -p $work/$job_name/input
	rsync -av $work/input.tar.gz $data_path  $work/$job_name/input
	cd $work/$job_name/
	$work/$job_name/gridrun_data.sh $nevents $run_num $data_file | tee $work/$job_name/log/log.txt
	cd -
    fi | tee $dir_macros/single_log_gridsub.txt
   
    JOBID="$(tail -2 $dir_macros/single_log_gridsub.txt | head -1 | grep -o '\S*@jobsub\S*')"
    echo $JOBID
    echo $job_name
    echo "$job_name $JOBID">>$dir_macros/jobid_info.txt

done 2>&1 | tee $dir_macros/log_gridsub.txt
