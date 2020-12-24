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

PREEMACS_DIR=$out_path
path_job=$PREEMACS_DIR/$SUB_ID
#--------------------------------------------------------------
#                                 PATHS                                       

FSLDIR=/home/inb/lconcha/fmrilab_software/fsl_5.0.6/
scripts_path=$PREEMACS_PATH/scripts
MRTRIX_DIR=/home/inb/lconcha/fmrilab_software/mrtrix3.git/bin
templates_path=$PREEMACS_PATH/templates
ants_path=/home/inb/lconcha/fmrilab_software/antsbin/bin

#--------------------------------------------------------------
#                              BRAIN MASK
# I don't know how to activate this in the M1.sh script
#inb_anaconda_on
#conda activate bskull

	Mdeepbrain-extractor -i $path_job/T1_conform.nii.gz -o $path_job/
	${MRTRIX_DIR}/mrconvert $path_job/brain_mask.nii  $path_job/mask/brain_mask_orig.nii.gz
	rm $path_job/brain_mask.nii
	rm $path_job/brain.nii
	${FSLDIR}/fslmaths $path_job/mask/brain_mask_orig.nii.gz -mul $path_job/T1_preproc.nii.gz $path_job/T1_brain.nii.gz

	$ants_path/antsRegistrationSyN.sh -d 3 -f $path_job/T1_brain.nii.gz -m $templates_path/NMT_brain_05.nii.gz -t a -o $path_job/mask/NMT_to_mask_
	${FSLDIR}/fslmaths $path_job/mask/NMT_to_mask_Warped.nii.gz -bin $path_job/mask/NMT_to_mask_Warped_mask.nii.gz
	${FSLDIR}/fslmaths $path_job/mask/NMT_to_mask_Warped_mask.nii.gz -dilM $path_job/mask/NMT_to_mask_Warped_mask.nii.gz
	${FSLDIR}/fslmaths $path_job/mask/NMT_to_mask_Warped_mask.nii.gz -mul $path_job/T1_brain.nii.gz $path_job/T1_brain.nii.gz
	${FSLDIR}/fslmaths $path_job/T1_brain.nii.gz -bin $path_job/brain_mask.nii.gz
	${FSLDIR}/fslmaths $path_job/brain_mask.nii.gz -mul $path_job/T2_preproc.nii.gz $path_job/T2_brain.nii.gz
	cp $path_job/T2_preproc.nii.gz $path_job/T2.nii.gz
	cp $path_job/T1_preproc.nii.gz $path_job/T1.nii.gz
