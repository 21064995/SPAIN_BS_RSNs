#!/bin/bash -x

####06_ts_extract.sh####
# Extract the timeseries from the fourth ventricle for each participant; to execute: sh 09_fourth_ventricle.sh
# Created: Alexandra Voce 20/01/2024
###################

# Clear out any modules loaded by ~/.cshrc and load NaN defaults
echo "Loading necessary modules"
source /software/system/modules/latest/init/bash
module use /software/system/modules/NaN/generic
module purge
module load nan

# Load modules necessary for analyses
module load fsl/6.0.7.4

# Set working directory
participant_dir=/data/project/SPAIN_BS/SPAIN/derivatives/processed2
ventricle_dir=/data/project/SPAIN_BS/SPAIN/derivatives/processed2/fourth_ventricle/singularity

# Loop through subject directories
for sub_dir in ${participant_dir}/sub-SPAIN*; do
    sub_id=$(basename ${sub_dir})
    
    mkdir ${ventricle_dir}/${sub_id}
    
	# segment brain ventricles according to these instructions: http://medic.rad.jhmi.edu/index.php?title=Brain_ventricle_parcellation_instructions, 51 = right lateral ventricle, 52 = left lateral ventricle, 4 = third ventricle, 11 = fourth ventricle
	singularity run ${ventricle_dir}/ventricle-parcellation_v4.simg -i ${sub_dir}/ses-B/${sub_id}_ses-B_T1w_chop.nii.gz -o ${ventricle_dir}/${sub_id}
 
	# threshold the resultant image to isolate fourth ventricle (i.e. 11)
	fslmaths ${ventricle_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_n4_mni_strip_seg_inverse.nii.gz -thr 11 -uthr 11 ${ventricle_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_fourth_ventricle.nii.gz
 
	# erode and binarise the fourth ventricle mask
	fslmaths ${ventricle_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_fourth_ventricle.nii.gz -ero -ero -bin ${ventricle_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_fourth_ventricle_ero_bin.nii.gz
 
	# register the mask to functional space image
	flirt -in ${ventricle_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_fourth_ventricle_ero_bin.nii.gz -ref ${sub_dir}/ses-B/${sub_id}_ses-B_task-rest_bold_chop_brainstem_mcf_tmean.nii.gz -out ${ventricle_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_fourth_ventricle_ero_bin_reg_func.nii.gz -init ${sub_dir}/ses-B/brainstem_reg/highres2func.mat -applyxfm -interp nearestneighbour
 
	# extract mean CSF timecourse from the functional timeseries using the mask in functional space
	fslmeants -i ${sub_dir}/ses-B/${sub_id}_ses-B_task-rest_bold_chop_brainstem_mcf.nii.gz -o ${ventricle_dir}/${sub_id}/${sub_id}_csf.txt -m ${ventricle_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_fourth_ventricle_ero_bin_reg_func.nii.gz
 
 done
 
