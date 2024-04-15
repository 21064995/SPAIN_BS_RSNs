#!/bin/bash -x

####06_ts_extract.sh####
# Perform inverse transformation on mask regions to bring into participant space; to execute: sh 06_transform.sh
# Created: Alexandra Voce 16/01/2024
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
working_dir=/data/project/SPAIN_BS/SPAIN/derivatives/processed2
mask_dir=${working_dir}/brainstem_masks

# Loop through subject directories
for sub_dir in ${working_dir}/sub-SPAIN*; do
    sub_id=$(basename ${sub_dir})
    
    # Create brainstem_mask folder for output
    mkdir -p ${sub_dir}/ses-B/brainstem_mask
    
    # Loop through each brainstem region mask
    for region_file in ${mask_dir}/*.nii.gz; do
        region=$(basename ${region_file%%.*.*})  # remove extension from region name

        echo "Applying inverse warp for ${sub_id} and ${region}"
        
        # warping mask from standard to high res
		applywarp --ref=${sub_dir}/ses-B/${sub_id}_ses-B_T1w_chop.nii.gz --in=${region_file} --out=${sub_dir}/ses-B/brainstem_mask/${region}_anat.nii.gz --warp=${sub_dir}/ses-B/brainstem_reg/standard2highres_warp.mat
		 
		# binarise the mask
		fslmaths ${sub_dir}/ses-B/brainstem_mask/${region}_anat.nii.gz -bin ${sub_dir}/ses-B/brainstem_mask/${region}_anat_bin.nii.gz
		 
		# register the region mask to subject functional space
		flirt -in ${sub_dir}/ses-B/brainstem_mask/${region}_anat_bin.nii.gz -ref ${sub_dir}/ses-B/${sub_id}_ses-B_task-rest_bold_chop_brainstem_mcf_tmean.nii.gz -out ${sub_dir}/ses-B/brainstem_mask/${region}_sub_space.nii.gz -init ${sub_dir}/ses-B/brainstem_reg/highres2func.mat -applyxfm -interp nearestneighbour
		 
        echo "Yay! Inverse warp applied for ${sub_id}, ${region}"
    done
done
