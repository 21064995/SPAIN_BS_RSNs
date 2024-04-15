#!/bin/bash -x

####01_chop_AV.sh####
# Loop for separating brainstem from the spinal cord; to execute: sh 01_chop_AV
# Created: Alex Voce 16/01/2024
###################

# clear out any modules loaded by ~/.cshrc and load NaN defaults
echo "Loading necessary modules"
source /software/system/modules/latest/init/bash
module use /software/system/modules/NaN/generic
module purge
module load nan

# load modules necessary for analyses
module load fsl/6.0.7.4

# set up path variables
code_dir=/data/project/SPAIN_BS/SPAIN/code/ALEX_V/
data_dir=/data/project/SPAIN_BS/SPAIN/data/
working_dir=/data/project/SPAIN_BS/SPAIN/derivatives/tmp

# read subject, session, and z coordinate variables from a csv file
while IFS="," read -r sub ses chop_z_func chop_z_T1
do
	modified_ses="ses-${ses: -1}"
	modified_sub="sub-${sub}"
	#echo "sub: ${sub}"
	#echo "ses: ${ses}"
	echo "sub: ${modified_sub}"
	echo "ses: ${modified_ses}"
	echo "Chop z coordinate: ${chop_z}"
	
	cd ${data_dir}/${modified_sub}/${modified_ses}/
	#Creating participant directories within /derivatives/chopped to save the outputs
		if [ -d "${working_dir}/${modified_sub}/${modified_ses}" ]; then
			echo "Directory already exists. Doing nothing."
		else
			mkdir -p "${working_dir}/${modified_sub}/${modified_ses}"
			echo "Directory created: ${working_dir}/${modified_sub}/${modified_ses}"
		fi
	save_dir=${working_dir}/${modified_sub}

	func_data=`ls -1 func/${modified_sub}_${modified_ses}_task-rest_bold.nii.gz`
	t1_data=`ls -1 anat/${modified_sub}_${modified_ses}_T1w.nii.gz`
	
	func_data_basename=` basename ${func_data} .nii.gz `
	t1_data_basename=`basename ${t1_data} .nii.gz`
	
	chop_z_func_plus_one=$((${chop_z_func} + 1)) # add 1 to chop_z_func value
	chop_z_t1_plus_one=$((${chop_z_T1} + 1)) # add 1 to chop_z_t1 value
	
	echo "Separating brainstem of ${func_data} at z ${chop_z_func_plus_one}..."
	fslroi ${func_data} ${save_dir}/${func_data_basename}_chop_brainstem.nii.gz 0 -1 0 -1 ${chop_z_func_plus_one} -1 0 -1
	
	echo "Separating brainstem of ${t1_data} at z ${chop_z_t1_plus_one}..."
	fslroi ${t1_data} ${save_dir}/${t1_data_basename}_chop.nii.gz 0 -1 0 -1 ${chop_z_t1_plus_one} -1 0 -1
	
done < ${code_dir}/chop_z_AV.csv
