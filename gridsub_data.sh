#!/bin/bash

dir_macros=$(dirname $(readlink -f $BASH_SOURCE))
LIFE_TIME=long # short (3h), medium (8h) or long (23h)

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
    work=/pnfs/e1039/persistent/cosmic_recodata/$jobname
    # ln -sf /pnfs/e906/persistent/cosmic_recodata data
else
    echo "Local mode."
    work=$dir_macros/scratch/$jobname
fi

#location of the decoded data
data_dir="/pnfs/e1039/scratch/cosmic_decoded_dst"

if [ "$resub_file" = "null" ]; then

    mkdir -p $work
    chmod -R 01755 $work

    echo $work
    echo $dir_macros

    tar -C $dir_macros -czvf $work/input.tar.gz geom.root RecoE1039Data.C

    #declare -a data_path_list=()
    if [ $dst_mode = 'single' ] ; then
	data_path_list=( $data_dir/$(printf 'run_%06d_spin.root' $run_name) )
    else # 'splitting'     
	data_path_list=( $(find $data_dir -name $(printf 'run_%06d_spill_*_spin.root' $run_name) ) )
	echo $data_path_list
    fi

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
	#cmd="jobsub_submit"
	#cmd="$cmd -g --OS=SL7 --use_gftp --resource-provides=usage_model=DEDICATED,OPPORTUNISTIC,OFFSITE -e IFDHC_VERSION --expected-lifetime='$LIFE_TIME'"
	#cmd="$cmd -g --OS=SL7 --use_gftp --resource-provides=usage_model=DEDICATED,OPPORTUNISTIC -e IFDHC_VERSION --expected-lifetime='$LIFE_TIME'"
        cmd="jobsub_submit --grid"
        cmd="$cmd -l '+SingularityImage=\"/cvmfs/singularity.opensciencegrid.org/e1039/e1039-sl7:latest\"'"
        cmd="$cmd --append_condor_requirements='(TARGET.HAS_SINGULARITY=?=true)'"
        cmd="$cmd --use_gftp --resource-provides=usage_model=DEDICATED,OPPORTUNISTIC,OFFSITE -e IFDHC_VERSION --expected-lifetime='$LIFE_TIME'"
	cmd="$cmd --mail_never"
	cmd="$cmd -L $work/$job_name/log/log.txt"
	cmd="$cmd -f $work/input.tar.gz"
	cmd="$cmd -d OUTPUT $work/$job_name/out"
	cmd="$cmd -f $data_path"
	cmd="$cmd file://`which $work/$job_name/gridrun_data.sh` $nevents $run_name $data_file"
	echo "$cmd"
	$cmd
    else
	mkdir -p $work/$job_name/input
	rsync -av $work/input.tar.gz $data_path  $work/$job_name/input
	cd $work/$job_name/
	$work/$job_name/gridrun_data.sh $nevents $run_num $data_file | tee $work/$job_name/log/log.txt
	cd -
    fi | tee $dir_macros/single_log_gridsub.txt
   
    JOBID="$(grep -o '\S*@jobsub\S*' <<< $(tail -2 $dir_macros/single_log_gridsub.txt | head -1))"
    echo $JOBID
    echo $job_name
    paste <(echo "$job_name") <(echo "$JOBID")>>$dir_macros/jobid_info.txt

done 2>&1 | tee $dir_macros/log_gridsub.txt
