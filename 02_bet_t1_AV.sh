#!/bin/bash -x

####02_bet_t1.sh####
# Perform brain extraction T1w images; to execute: sh 02_bet_t1_AV.sh
# Created: Matt/Alex 16/01/2024
###################

# clear out any modules loaded by ~/.cshrc and load NaN defaults
echo "Loading necessary modules"
source /software/system/modules/latest/init/bash
module use /software/system/modules/NaN/generic
module purge
module load nan

# load modules necessary for analyses
module load fsl/6.0.7.4

# set working directory
working_dir=/data/project/SPAIN_BS/SPAIN/derivatives/tmp

# for loop for BET-ing the T1w image from each session (the neck has to be cut off for this to work)
for sub_dir in `ls -d ${working_dir}/sub-SPAIN??/ses-?`; do
	sub_id=`echo ${sub_dir} | cut -d / -f 8`
	ses=`echo ${sub_dir} | cut -d / -f 9`
	cd ${sub_dir}

	bet ${sub_id}_${ses}_T1w_chop.nii.gz ${sub_id}_${ses}_T1w_brain.nii.gz -f 0.3
done
