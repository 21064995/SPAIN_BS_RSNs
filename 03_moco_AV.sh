#!/bin/bash -x

####03_moco.sh####
# Perform motion correction on functional data; to execute: sh 03_moco_AV.sh
# Created: Alexandra Voce 16/01/2024
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

# for loop for running MCFLIRT motion correction for each session
for sub_dir in `ls -d ${working_dir}/sub-SPAIN??/ses-?`; do
	sub_id=`echo ${sub_dir} | cut -d / -f 8`
	ses=`echo ${sub_dir} | cut -d / -f 9`
	echo "sub_id: ${sub_id}"
	cd ${sub_dir}

	echo "Processing ${sub_id}"

	mcflirt -in ${sub_id}_${ses}_task-rest_bold_chop_brainstem.nii.gz -plots -meanvol
	echo "Yay, ${sub_id} done!"
done
