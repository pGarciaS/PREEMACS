#!/bin/bash
print_help() {
echo "
Usage:
	`basename $0` SUB_ID out_path
Pam Garcia
INB June,2020
np.pam.garcia@gmail.com
"
}
#------------------------------------------------------------------------------#
#			 Declaring variables & WARNINGS
if [ $# -lt 1 ]
then
	echo -e "\e[0;36m\n[ERROR]... Argument missing: \n\e[0m\t\tT1_path_N_Points $2 \n\t\tYou need list of ID of each point$4"
	print_help
	exit 1
fi

SUB_ID=$1
out_path=$2
####################################


#--------------------------------------------------------------
#                              PATHS 

source ./pathFile.sh

#### DO NOT MODIFY BELOW THIS LINE##############################################
PREEMACS_DIR=$out_path
path_job=$PREEMACS_DIR/$SUB_ID
curr_path=$( pwd )
PREEMACS_PATH="$(dirname -- $curr_path)"
scripts_path=$PREEMACS_PATH/scripts
templates_path=$PREEMACS_PATH/templates


#--------------------------------------------------------------
#                              BRAIN MASK
# I don't know how to activate this in the M1.sh script
#inb_anaconda_on
#conda activate bskull

	Mdeepbrain-extractor -i $path_job/T1_conform.nii.gz -o $path_job/
	${MRTRIX_DIR}/mrconvert $path_job/brain_mask.nii  $path_job/mask/brain_mask_orig.nii.gz
	rm $path_job/brain_mask.nii
	rm $path_job/brain.nii
	${FSLDIR}/fslmaths $path_job/mask/brain_mask_orig.nii.gz -mul $path_job/T1_conform.nii.gz $path_job/T1_brain.nii.gz
	${FSLDIR}/fslmaths $path_job/mask/brain_mask_orig.nii.gz -bin $path_job/brain_mask.nii.gz
