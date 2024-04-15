#!/bin/bash -x

####06_ts_extract.sh####
# Extract the timeseries from the white matter of the brainstem/cerebellum; to execute: sh 10_WM_extract.sh
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
wm_dir=/data/project/SPAIN_BS/SPAIN/derivatives/processed2/white_matter/fast_mask

# Loop through subject directories
for sub_dir in ${participant_dir}/sub-SPAIN*; do
    sub_id=$(basename ${sub_dir})
    
    mkdir ${wm_dir}/${sub_id}
		
	# segment T1w structural to obtain a white matter mask - run on BET data
	fast ${sub_dir}/ses-B/${sub_id}_ses-B_T1w_brain.nii.gz 
	
	# invert FNIRT warp to obtain MNI -> highres transformation
	invwarp --ref=${sub_dir}/ses-B/${sub_id}_ses-B_T1w_brain.nii.gz --warp=${sub_dir}/ses-B/brainstem_reg/highres2standard_warp.nii.gz --out=${sub_dir}/ses-B/brainstem_reg/standard2highres_warp.mat
	 
	# register MNI mask of the cerebellum to subject-specific highres (T1w) image
	applywarp --ref=${sub_dir}/ses-B/${sub_id}_ses-B_T1w_brain.nii.gz --in=${wm_dir}/mni_prob_cerebellum.nii.gz --out=${wm_dir}/${sub_id}/mni_prob_cerebellum_reg_anat_fnirt.nii.gz --warp=${sub_dir}/ses-B/brainstem_reg/standard2highres_warp.mat
	 
	# erode and binarise the cerebellar mask
	fslmaths ${wm_dir}/${sub_id}/mni_prob_cerebellum_reg_anat_fnirt.nii.gz -ero -ero -ero -ero -bin ${wm_dir}/${sub_id}/mni_prob_cerebellum_reg_anat_fnirt_ero_bin.nii.gz
	
	# multiply the white matter mask by the cerebellar mask, threshold, erode, and binarise
	fslmaths ${sub_dir}/ses-B/${sub_id}_ses-B_T1w_chop_pve_2.nii.gz -mul ${wm_dir}/${sub_id}/mni_prob_cerebellum_reg_anat_fnirt_ero_bin.nii.gz -thr 1 -ero -ero -ero -bin ${wm_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_brain_pve_2_cerebellum_thr_ero_bin
	
	# eroding mask further
	fslmaths ${wm_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_brain_pve_2_cerebellum_thr_ero_bin.nii.gz -ero -ero -ero -ero -ero -ero -ero -ero -ero -ero ${wm_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_brain_pve_2_cerebellum_thr_ero_bin_bin.nii.gz

	# register the cerebellar white matter mask to subject functional space
	flirt -in ${wm_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_brain_pve_2_cerebellum_thr_ero_bin_bin.nii.gz -ref ${sub_dir}/ses-B/${sub_id}_ses-B_task-rest_bold_chop_brainstem_mcf_tmean.nii.gz -out ${wm_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_brain_pve_2_cerebellum_thr_ero_bin_reg_func -init ${sub_dir}/ses-B/brainstem_reg/highres2func.mat -applyxfm -interp nearestneighbour
	 
	# extract white matter timecourse from motion corrected data
	fslmeants -i ${sub_dir}/ses-B/${sub_id}_ses-B_task-rest_bold_chop_brainstem_mcf.nii.gz -o ${wm_dir}/${sub_id}/${sub_id}_wm.txt -m ${wm_dir}/${sub_id}/${sub_id}_ses-B_T1w_chop_brain_pve_2_cerebellum_thr_ero_bin_reg_func.nii.gz
	 
 done
 
