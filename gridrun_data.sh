#!/bin/bash
#Author: Abinash 
#Script to run macro over grid node

nevents=$1
run_number=$2
data_file=$3

echo $datafile
if [ -z ${CONDOR_DIR_INPUT+x} ];
  then
    CONDOR_DIR_INPUT=./input;
    echo "CONDOR_DIR_INPUT is initiallized as $CONDOR_DIR_INPUT"
  else
    echo "CONDOR_DIR_INPUT is set to '$CONDOR_DIR_INPUT'";
fi

if [ -z ${CONDOR_DIR_OUTPUT+x} ];
  then
    CONDOR_DIR_OUTPUT=./out;
    mkdir -p $CONDOR_DIR_OUTPUT
    echo "CONDOR_DIR_OUTPUT is initiallized as $CONDOR_DIR_OUTPUT"
  else
    echo "CONDOR_DIR_OUTPUT is set to '$CONDOR_DIR_OUTPUT'";
fi

echo "hello, grid." | tee out.txt $CONDOR_DIR_OUTPUT/out.txt
echo "HOST = $HOSTNAME" | tee -a out.txt $CONDOR_DIR_OUTPUT/out.txt
pwd | tee -a out.txt $CONDOR_DIR_OUTPUT/out.txt

tar -xzvf $CONDOR_DIR_INPUT/input.tar.gz

ln -s $CONDOR_DIR_INPUT/$data_file data.root 

E1039_CORE_VERSION=pr.128
FN_SETUP=/e906/app/software/osg/software/e1039/this-e1039.sh
if [ ! -e $FN_SETUP ] ; then # On grid
    FN_SETUP=/cvmfs/seaquest.opensciencegrid.org/seaquest/${FN_SETUP#/e906/app/software/osg/}
fi
echo "SETUP = $FN_SETUP"
source $FN_SETUP

echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

time root -b -q RecoE1039Data.C\($nevents\,$run_number\)
RET=$?
if [ $RET -ne 0 ] ; then
    echo "Error in RecoE1039Data.C: $RET"
    exit $RET
fi

mv *.root *.tsv $CONDOR_DIR_OUTPUT/

echo "gridrun.sh finished!"
echo "Following for recording status: data file and status (0 if success otherwise error)"
echo $data_file
echo $RET
