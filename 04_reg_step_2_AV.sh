#!/bin/bash

####04_reg_step_02.sh####
# Register T1w and functional data to MNI space (using parallel processing on SLURM)
# To execute: sbatch 04_reg_step_02.sh
# To check status of the job: squeue
# To cancel the job: scancel <job_id>
# More SLURM help: https://mri.nan.kcl.ac.uk/mediawiki/index.php?title=SLURM:Array_Jobs
# Created: Olivia Kowalczyk 25/01/2024, edited by Alexandra Voce 26/01/2024
###################

#SBATCH --job-name=spain_reg
#SBATCH --output=/data/project/SPAIN_BS/SPAIN/code/ALEX_V/logs/%A_%a.out
#SBATCH --export=none
#SBATCH --cpus-per-task=2
#SBATCH --mem=50G
#SBATCH --time=3-60:00

# edit the range in this line to tell the script which jobs to process (range) and how many at a time (%x)
#SBATCH --array=1-62%10

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

# pick subject dir from list
input="`awk FNR==$SLURM_ARRAY_TASK_ID $index`"

# from the above list, separate string at each "/"
IFS='/' read -ra input_parts <<< "$input"

# store first and second part of the string as sub and ses variables
sub=${input_parts[0]} 
ses=${input_parts[1]}

echo ${sub}
echo ${ses}

echo "Running on ${HOSTNAME}"
echo "Array ID: ${SLURM_ARRAY_JOB_ID}"
echo "Task ID: ${SLURM_ARRAY_TASK_ID}"

# set home dir
home_dir=/data/project/SPAIN_BS/SPAIN

# set working directory
working_dir=${home_dir}/derivatives/processed2

# setting up variables 
func=${sub}_${ses}_task-rest_bold_chop_brainstem_mcf
func=`basename $func`
func_tmean=${func}_tmean

t1=${sub}_${ses}_T1w_chop
t1_brain=${sub}_${ses}_T1w_brain

mni_05mm=${home_dir}/data/mni/MNI152_T1_0.5mm
mni_brain_05mm=${home_dir}/data/mni/MNI152_T1_0.5mm_brain
mni_mask_05mm=${home_dir}/data/mni/MNI152_T1_0.5mm_brain_mask_dil

mni_2mm=/software/system/fsl/6.0.7.4/data/standard/MNI152_T1_2mm
mni_brain_2mm=/software/system/fsl/6.0.7.4/data/standard/MNI152_T1_2mm_brain
mni_mask_2mm=/software/system/fsl/6.0.7.4/data/standard/MNI152_T1_2mm_brain_mask_dil

echo "Processing subject: ${sub}, session: ${ses}"

cd ${working_dir}/${sub}/${ses}

# register mean functional image to subject-space T1
flirt -in ${func_tmean}_brain -ref ${t1_brain} -out brainstem_reg/func2highres -omat brainstem_reg/func2highres.mat -dof 6 -nosearch -init brainstem_reg/func2highres_nudge.mat -interp trilinear

# generate the inverse warp of the above (subject-specific T1w -> functional)
convert_xfm -inverse -omat brainstem_reg/highres2func.mat brainstem_reg/func2highres.mat
	
# general linear and non-linear warps for going from subject-specific T1w space to MNI template space
flirt -in ${t1_brain} -ref ${mni_brain_05mm} -out brainstem_reg/highres2standard -omat brainstem_reg/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 

fnirt --iout=brainstem_reg/highres2standard_head --in=${t1} --aff=brainstem_reg/highres2standard.mat --cout=brainstem_reg/highres2standard_warp --iout=brainstem_reg/highres2standard --jout=brainstem_reg/highres2highres_jac --config=T1_2_MNI152_2mm --ref=${mni_2mm} --refmask=${mni_mask_2mm} --warpres=5,5,5

#fnirt --iout=brainstem_reg/highres2standard_head --in=${t1} --aff=brainstem_reg/highres2standard.mat --cout=brainstem_reg/highres2standard_warp --iout=brainstem_reg/highres2standard --jout=brainstem_reg/highres2highres_jac --config=/data/project/SPAIN_BS/SPAIN/data/mni/T1_2_MNI152_0.5mm.cnf --ref=${mni} --refmask=${mni_mask} --warpres=5,5,5

# generate the inverse warp of the above (MNI -> subject-specific T1w)
convert_xfm -inverse -omat brainstem_reg/standard2highres.mat brainstem_reg/highres2standard.mat

# concatenate functional -> subject-specific T1w and subject-specific T1w -> MNI to generate functional -> MNI
convert_xfm -omat brainstem_reg/func2standard.mat -concat brainstem_reg/highres2standard.mat brainstem_reg/func2highres.mat

# test linear transformation for bringing functional data into MNI space
flirt -in ${func_tmean} -ref ${mni_brain_05mm} -out brainstem_reg/func2standard_flirt -omat brainstem_reg/func2standard_flirt.mat -init brainstem_reg/func2standard.mat -applyxfm

convertwarp --ref=${mni_2mm} --premat=brainstem_reg/func2highres.mat --warp1=brainstem_reg/highres2standard_warp --out=brainstem_reg/func2standard_warp

# generate the inverse warp of the above (MNI -> functional) 
convert_xfm -inverse -omat brainstem_reg/standard2func.mat brainstem_reg/func2standard.mat

# test the warp on the temporal mean functional image
applywarp --ref=${mni_brain_05mm} --in=${func_tmean}_brain --out=brainstem_reg/func2standard_fnirt --warp=brainstem_reg/func2standard_warp

echo "Yay, ${sub} ${ses} done!"
