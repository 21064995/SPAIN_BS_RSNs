#!/bin/bash 

####04_reg_step_01.sh####
# Prep for registration
# To execute: sh 04_reg_step_01.sh
# Created: Olivia Kowalczyk 25/01/2024
###################

# clear out any modules loaded by ~/.cshrc and load NaN defaults
echo "Loading necessary modules"
source /software/system/modules/latest/init/bash
module use /software/system/modules/NaN/generic
module purge
module load nan

# load modules necessary for analyses
module load fsl/6.0.7.4

# load list of subjects
index=/data/project/SPAIN_BS/SPAIN/code/ALEX_V/ses.index

# set working directory
working_dir=/data/project/SPAIN_BS/SPAIN/derivatives/tmp

# while loop for generating registration warps for each session
while IFS= read -r input
do
	# from the above list, separate string at each "/"
	IFS='/' read -ra input_parts <<< "$input"

	# store first and second part of the string as sub and ses variables
	sub=${input_parts[0]} 
	ses=${input_parts[1]}

	cd ${working_dir}/${sub}/${ses}
		if [ -d "brainstem_reg" ]; then
			echo "Directory already exists. Doing nothing."
		else
			mkdir -p "brainstem_reg"
			echo "Directory created: ${working_dir}/${sub}/${ses}/brainstem_reg"
		fi
	
	# setting up variables 
	func=${sub}_${ses}_task-rest_bold_chop_brainstem_mcf
	func=`basename $func .nii.gz`
	func_tmean=${func}_tmean

	t1=${sub}_${ses}_T1w_chop
	t1_brain=${sub}_${ses}_T1w_brain
	
	echo "Processing subject: ${sub}, session: ${ses}, FUNC = ${func}"
		
	# create a temporal mean of the motion corrected functional image
	fslmaths ${func} -Tmean ${func_tmean}
	
	# a very inclusive, low-Z dimension aware  brain extraction of the functional image
	bet ${func_tmean} ${func_tmean}_brain -f 0.15 -Z
	
	# use fslcpgeom to remove the zero padding from the low-Z bet
	fslcpgeom ${func_tmean} ${func_tmean}_brain	

	echo "${sub} processed"
	
done < "$index"

echo "04_reg_step_01.sh is finished. Now launch FSLeyes overlaying each subject's/session's tmean image on their T1w image. Go to Tools -> Nudge. In the pop-up window press Save affine. Select T1w image as reference, click Choose, navigate to the sub-<sub>/ses-<ses>/brainstem_reg directory, and name the matrix func2highres_nudge.mat"
	
echo "Now proceed to 04_reg_step_02.sh"
