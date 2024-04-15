#!/bin/bash -x

####06_ts_extract.sh####
# Perform timeseries extraction from brainstem regions; to execute: sh 07_ts_extract.sh
# Created: Alexandra Voce 16/01/2024
###################

# clear out any modules loaded by ~/.cshrc and load NaN defaults
echo "Loading necessary modules"
source /software/system/modules/latest/init/bash
module use /software/system/modules/NaN/generic
module purge
module load nan

# Load modules necessary for analyses
module load fsl/6.0.7.4

# Set working directory
working_dir=/data/project/SPAIN_BS/SPAIN/derivatives/processed2

# Loop through subject directories
for sub_dir in ${working_dir}/sub-SPAIN*; do
    sub_id=$(basename ${sub_dir})
    
	# Loop through each brainstem region mask
    for region_file in ${sub_dir}/ses-B/brainstem_mask/*_sub_space.nii.gz; do
    region=$(basename ${region_file%%.*.*})  # Extract region name without extension
	
	# Binarising each mask file
    fslmaths ${region_file} -bin ${sub_id}/ses-B/brainstem_mask/${region}_bin.nii.gz
    
    echo "REGION ${region}"
	
    #fslmeants -i ${sub_dir}/ses-B/${sub_id}_ses-B_task-rest_bold_chop_brainstem_mcf.nii.gz -o ${sub_id}_${region}.txt -m ${region}_bin.nii.gz
    fslmeants -i ${sub_id}/ses-B/${sub_id}_feat.feat/stats/res4d.nii.gz -o ${sub_id}/ses-B/timeseries/${sub_id}_${region}.txt -m ${sub_id}/ses-B/brainstem_mask/${region}_bin.nii.gz
	echo "Yay! ${sub_id}, ${region} done!"
	done
done



