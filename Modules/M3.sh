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

#                              PATHS           


source ./pathFile.sh

### DO NOT MODIFY BELOW THIS LINE

PREEMACS_DIR=$out_path
path_job=$PREEMACS_DIR/$SUB_ID
scripts=$PREEMACS_DIR/$SUB_ID/scripts

curr_path=$( pwd )
PREEMACS_PATH="$(dirname -- $curr_path)"

scripts_path=$PREEMACS_PATH/scripts
templates_path=$PREEMACS_PATH/templates
minc_path=$PREEMACS_PATH/programs
CARETDIR=${scripts_path}/caretDir

# # -------------------------------------------------------------- -Check Dice value of PREEMACS braintool mask

	# if [[ $Dice_val =< 0.95 ]]; then
	# $ants_path/antsRegistrationSyN.sh -d 3 -f $path_job/T1_brain.nii.gz -m $templates_path/NMT_brain_05.nii.gz -t a -o $path_job/mask/NMT_to_mask_
	# ${FSLDIR}/fslmaths $path_job/mask/NMT_to_mask_Warped.nii.gz -bin $path_job/mask/NMT_to_mask_Warped_mask.nii.gz
	# ${FSLDIR}/fslmaths $path_job/mask/NMT_to_mask_Warped_mask.nii.gz -dilM $path_job/mask/NMT_to_mask_Warped_mask.nii.gz
	# ${FSLDIR}/fslmaths $path_job/mask/NMT_to_mask_Warped_mask.nii.gz -mul $path_job/T1_brain.nii.gz $path_job/T1_brain.nii.gz
	# ${FSLDIR}/fslmaths $path_job/T1_brain.nii.gz -bin $path_job/brain_mask.nii.gz
    #fi

## --------------------------------------------------------------- Conform crop images and brainmask ----------------------------------#
#### Crop the images to perform BHCP. The images to perform mriqc are in 256. BHCP is better with the images crop

cd $scripts
echo "addpath('$scripts_path');NewMat=preemacs_autocrop('$path_job/','T1_conform.nii.gz','T1_preproc.nii.gz');exit()" > $scripts/info.m
$matlab_path -batch info
rm $scripts/info.m
cd ../

$ants_path/antsRegistrationSyN.sh -d 3 -f $path_job/T1_preproc.nii.gz -m $path_job/T1_brain.nii.gz -t r -o $path_job/T1_brain_crop_
	rm  $path_job/T1_brain_crop_0GenericAffine.mat
	rm  $path_job/T1_brain_crop_InverseWarped.nii.gz
mv  $path_job/brain_mask.nii.gz $path_job/mask/brain_mask_image_256.nii.gz

${FSLDIR}/bin/fslmaths $path_job/T1_brain_crop_Warped.nii.gz -bin $path_job/brain_mask.nii.gz
${FSLDIR}/bin/fslmaths $path_job/brain_mask.nii.gz kernel box 1x1x1 -fmean $path_job/brain_mask.nii.gz
${FSLDIR}/bin/fslmaths $path_job/brain_mask.nii.gz -mul $path_job/T1_preproc.nii.gz $path_job/T1_brain.nii.gz

##---------------------------------------------------------------- T1_T2 reg -----------------------------------------------------#

Info "T2 registration T1"
cd $path_job/

$ants_path/antsRegistrationSyN.sh -d 3 -f $path_job/T1_preproc.nii.gz -m $path_job/T2_preproc.nii.gz -t r -o $path_job/T2_preproc_
rm  $path_job/T2_preproc_0GenericAffine.mat
rm  $path_job/T2_preproc_InverseWarped.nii.gz
mv  $path_job/T2_preproc_Warped.nii.gz $path_job/T2_preproc.nii.gz

${FSLDIR}/bin/fslmaths $path_job/brain_mask.nii.gz -mul $path_job/T2_preproc.nii.gz $path_job/T2_brain.nii.gz
		  #---------------------------------------------------------------------------------------#
cp $path_job/T2_preproc.nii.gz $path_job/T2.nii.gz
cp $path_job/T1_preproc.nii.gz $path_job/T1.nii.gz

rm $path_job/T1_brain_crop_Warped.nii.gz

# #--------------------------------------------------------------- BIAS HCP --------------------------------------------------------------
image=$path_job/T1.nii.gz

## default parameters HCP

Factor=0.5 #Leave this at 0.5 for now it is the number of standard deviations below the mean to threshold the non-brain tissues at
BiasFieldSmoothingSigma=5 #Leave this at 5mm for now

# #----------------------------------------------------------------PROCESS
aloita=$(date +%s.%N)
echo -e "\033[48;5;125m \n [INIT]...Process BIAS \n\033[0m";
echo " "
echo " START: BiasFieldCorrection"

#Record the input options in a log file

echo "$0 $@" >> $path_job/HCP/log.txt
echo "PWD = `pwd`" >> $path_job/HCP/log.txt
echo "date: `date`" >> $path_job/HCP/log.txt
echo " " >> $path_job/HCP/log.txt


#  # Form sqrt(T1w*T2w), mask this and normalise by the mean
${FSLDIR}/bin/fslmaths $path_job/T1.nii.gz -mul $path_job/T2.nii.gz -abs -sqrt $path_job/HCP/T1wmulT2w.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w.nii.gz -mas $path_job/T1_brain.nii.gz $path_job/HCP/T1wmulT2w_brain.nii.gz
meanbrainval=`${FSLDIR}/bin/fslstats $path_job/HCP/T1wmulT2w_brain.nii.gz -M`
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain.nii.gz -div $meanbrainval $path_job/HCP/T1wmulT2w_brain_norm.nii.gz

# Smooth the normalised sqrt image, using within-mask smoothing : s(Mask*X)/s(Mask)
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm.nii.gz -bin -s $BiasFieldSmoothingSigma $path_job/HCP/SmoothNorm_s${BiasFieldSmoothingSigma}.nii.gz
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm.nii.gz -s $BiasFieldSmoothingSigma -div $path_job/HCP/SmoothNorm_s${BiasFieldSmoothingSigma}.nii.gz $path_job/HCP/T1wmulT2w_brain_norm_s${BiasFieldSmoothingSigma}.nii.gz

# Divide normalised sqrt image by smoothed version (to do simple bias correction)
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm.nii.gz -div $path_job/HCP/T1wmulT2w_brain_norm_s$BiasFieldSmoothingSigma.nii.gz $path_job/HCP/T1wmulT2w_brain_norm_modulate.nii.gz

# Create a mask using a threshold at Mean - 0.5*Stddev, with filling of holes to remove any non-grey/white tissue.
STD=`${FSLDIR}/bin/fslstats $path_job/HCP/T1wmulT2w_brain_norm_modulate.nii.gz -S`
echo $STD
MEAN=`${FSLDIR}/bin/fslstats $path_job/HCP/T1wmulT2w_brain_norm_modulate.nii.gz -M`
echo $MEAN
Lower=`echo "$MEAN - ($STD * $Factor)" | bc -l`
echo $Lower
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm_modulate -thr $Lower -bin -ero -mul 255 $path_job/HCP/T1wmulT2w_brain_norm_modulate_mask
${CARETDIR}/wb_command -volume-remove-islands $path_job/HCP/T1wmulT2w_brain_norm_modulate_mask.nii.gz $path_job/HCP/T1wmulT2w_brain_norm_modulate_mask.nii.gz

## Extrapolate normalised sqrt image from mask region out to whole FOV
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm.nii.gz -mas $path_job/HCP/T1wmulT2w_brain_norm_modulate_mask.nii.gz -dilall $path_job/HCP/bias_raw.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/HCP/bias_raw.nii.gz -s $BiasFieldSmoothingSigma $path_job/HCP/BiasField.nii.gz

## Use bias field output to create corrected images
${FSLDIR}/bin/fslmaths $path_job/T1.nii.gz -div $path_job/HCP/BiasField.nii.gz -mas $path_job/T1_brain.nii.gz $path_job/HCP/T1_Brain_RestoredImage.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/T1.nii.gz -div $path_job/HCP/BiasField.nii.gz $path_job/HCP/T1_RestoredImage.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/T2.nii.gz -div $path_job/HCP/BiasField.nii.gz -mas $path_job/T2_brain.nii.gz $Output_$path_job/HCP/T2_Brain_RestoredImage.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/T2.nii.gz -div $path_job/HCP/BiasField.nii.gz $path_job/HCP/T2_RestoredImage.nii.gz -odt float

## Copy images without bet to use init FS

cp  $path_job/HCP/T1_RestoredImage.nii.gz   $path_job/T1.nii.gz
cp  $path_job/HCP/T2_RestoredImage.nii.gz   $path_job/T2.nii.gz

mkdir $path_job/before_HCP
mv $path_job/T1_preproc.nii.gz $path_job/before_HCP/T1_before_HCP.nii.gz
mv $path_job/T2_preproc.nii.gz $path_job/before_HCP/T2_before_HCP.nii.gz
mv $path_job/T1_brain.nii.gz $path_job/before_HCP/T1_brain_before_HCP.nii.gz
mv $path_job/T2_brain.nii.gz $path_job/before_HCP/T2_brain_before_HCP.nii.gz

echo " "
echo " END: BiasFieldCorrection"
echo " END: `date`" >> $path_job/HCP/log.txt

#---------------------------------------------------------- Truncate instensity of images

$ants_path/ImageMath 3 $path_job/T1.nii.gz TruncateImageIntensity $path_job/T1.nii.gz

#---------------------------------------------------------- FAKE SPACE

cd $scripts
echo "addpath('$scripts_path');[NII]= fake_space('$path_job/','T1',[1;1;1;1;0;0;0;0],'_fake','T1');exit()" > $scripts/info.m
	$matlab_path -batch info
	rm $scripts/info.m

cd $scripts

echo "addpath('$scripts_path');[NII]= fake_space('$path_job/','T2',[1;1;1;1;0;0;0;0],'_fake','T2');exit()" > $scripts/info.m
	$matlab_path -batch info
	rm $scripts/info.m


# #-------------------------------------------------------- FS process autorecon1

${FREESURFER_HOME}/bin/recon-all -i $path_job/T1_fake.nii.gz -s $SUB_ID -T2 $path_job/T2_fake.nii.gz -T2pial -autorecon1 -noskullstrip

# #-------------------------------------------------------- Mask process based on PREEMACS mask
echo -e "\033[48;5;125m \n [INIT]... CORRECT BRAIN MASK: EDIT MASK TO FS \n\033[0m";

DIR=$SUBJECTS_DIR/$SUB_ID
DIRm=$SUBJECTS_DIR/$SUB_ID/mri
mkdir $DIR/mri/brain_mask_template/
DIR_bm=$SUBJECTS_DIR/$SUB_ID/mri/brain_mask_template
path_job=$PREEMACS_DIR/$SUB_ID


mkdir $DIR/mri/fix_wm/
fix_wm=$DIR/mri/fix_wm

#---------------------------------------------------------- Brain Mask process

${FREESURFER_HOME}/bin/mri_convert $DIR/mri/T1.mgz $DIR_bm/T1.nii.gz
original_image=$path_job/T1.nii.gz
mask_native_space=$path_job/brain_mask.nii.gz

cd $DIR_bm
echo "addpath('$scripts_path');fake_space('$DIR_bm/','T1',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake','T1');exit()" > $DIR_bm/info.m
 $matlab_path -batch info
rm $DIR_bm/info.m

${FSLDIR}/bin/flirt -ref $DIR_bm/T1_no_fake.nii.gz  -in $path_job/T1.nii.gz  -out $DIR_bm/ATLAS_TO_T1.nii.gz -dof 12 -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -omat $DIR_bm/ATLAS_TO_T1.mat
${FSLDIR}/bin/flirt -ref $DIR_bm/ATLAS_TO_T1.nii.gz -in $mask_native_space -applyxfm -init $DIR_bm/ATLAS_TO_T1.mat -out $DIR_bm/MASK_ATLAS_TO_T1.nii.gz

cd $DIR_bm/
echo "addpath('$scripts_path');fake_space('$DIR_bm/','T1',[1;1;1;1;0;0;0;0],'_fake','MASK_ATLAS_TO_T1');exit()" > $DIR_bm/info.m
 $matlab_path -batch info
rm $DIR_bm/info.m

#mv $DIRm/brainmask.auto.mgz $DIRm/brainmask_original.auto.mgz
#mv $DIRm/brainmask.mgz $DIRm/brainmask_original.mgz

${FSLDIR}/bin/fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $DIR_bm/T1.nii.gz $DIR_bm/brainmask_fix.nii.gz

${FREESURFER_HOME}/bin/mri_mask $DIR_bm/brainmask_fix.nii.gz $DIR_bm/T1.nii.gz $DIRm/brainmask.auto.mgz
${FREESURFER_HOME}/bin/mri_add_xform_to_header -c $SUBJECTS_DIR/$SUB_ID/transforms/talairach.xfm $DIRm/brainmask.auto.mgz $DIRm/brainmask.auto.mgz
cp $DIRm/brainmask.auto.mgz $DIRm/brainmask.mgz
# #------------------------------------------------------- Register to FS Atlas

${FREESURFER_HOME}/bin/mri_em_register -rusage $DIR/touch/rusage.mri_em_register.dat -uns 3 -mask $DIRm/brainmask.mgz $DIRm/nu.mgz /home/inb/lconcha/fmrilab_software/freesurfer_6.0//average/RB_all_2016-05-10.vc700.gca $DIRm/transforms/talairach.lta
${FREESURFER_HOME}/bin/mri_ca_normalize -c $DIRm/ctrl_pts.mgz -mask $DIRm/brainmask.mgz $DIRm/nu.mgz /home/inb/lconcha/fmrilab_software/freesurfer_6.0//average/RB_all_2016-05-10.vc700.gca $DIRm/transforms/talairach.lta $DIRm/norm.mgz
${FREESURFER_HOME}/bin/mri_ca_register -rusage $DIR/touch/rusage.mri_ca_register.dat -nobigventricles -T $DIRm/transforms/talairach.lta -align-after -mask $DIRm/brainmask.mgz $DIRm/norm.mgz /home/inb/lconcha/fmrilab_software/freesurfer_6.0//average/RB_all_2016-05-10.vc700.gca $DIRm/transforms/talairach.m3z
${FREESURFER_HOME}/bin/mri_ca_label -relabel_unlikely 9 .3 -prior 0.5 -align $DIRm/norm.mgz $DIRm/transforms/talairach.m3z /home/inb/lconcha/fmrilab_software/freesurfer_6.0//average/RB_all_2016-05-10.vc700.gca $DIRm/aseg.auto_noCCseg.mgz
${FREESURFER_HOME}/bin/mri_cc -aseg aseg.auto_noCCseg.mgz -o aseg.auto.mgz -lta $DIR/mri/transforms/cc_up.lta $SUB_ID
cp $DIRm/aseg.auto.mgz $DIRm/aseg.presurf.mgz
${FREESURFER_HOME}/bin/mri_normalize -mprage -aseg $DIRm/aseg.presurf.mgz -mask $DIRm/brainmask.mgz $DIRm/norm.mgz $DIRm/brain.mgz
${FREESURFER_HOME}/bin/mri_mask -T 5 $DIRm/brain.mgz $DIRm/brainmask.mgz $DIRm/brain.finalsurfs.mgz

#--------------------------------------------------------- NMT registration
${FSLDIR}/bin/fslmaths $path_job/T1.nii.gz -mul $path_job/brain_mask.nii.gz $path_job/brain.nii.gz
mkdir $path_job/NMT_reg
NMT_REG=$path_job/NMT_reg
$ants_path/antsRegistrationSyN.sh -d 3 -f $path_job/brain.nii.gz -m  $templates_path/NMT_brain.nii.gz -o $NMT_REG/NMT_to_T1_
$ants_path/ConvertTransformFile 3 $NMT_REG/NMT_to_T1_0GenericAffine.mat $NMT_REG/NMT_to_T1_0GenericAffine.txt
#-------------------------------------------------------- WM fix
#1. Get FS labels from NMT
#2. Filling subcortical structures
#3. High instensity Control Point (HICPO)

#-------------------------------------------------------  1.Get FS labels from NMT
reference_image=$path_job/brain.nii.gz
fs_atlas=$templates_path/labes_fs_with_thalamus.nii.gz
image_1Warp=$NMT_REG/NMT_to_T1_1Warp.nii.gz
txt_from_registration=$NMT_REG/NMT_to_T1_0GenericAffine.txt

$ants_path/WarpImageMultiTransform 3 $fs_atlas $fix_wm/fs_atlas.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
# get the transforms for fs atlas
${FSLDIR}/bin/fslmaths $DIR_bm/MASK_ATLAS_TO_T1.nii.gz -mul $DIR_bm/T1_no_fake.nii.gz $DIR_bm/brain_no_fake.nii.gz
${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $reference_image -out $fix_wm/brain_for_fix_fs.nii.gz -dof 12 -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -omat $fix_wm/brain_for_fix_fs.mat -interp nearestneighbour
${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $fix_wm/fs_atlas.nii.gz -applyxfm -init $fix_wm/brain_for_fix_fs.mat -out $fix_wm/brain_for_fix_fs_space.nii.gz -interp nearestneighbour

cd $fix_wm
echo "addpath('$scripts_path');fake_space('$fix_wm/','T1',[1;1;1;1;0;0;0;0],'_fake','brain_for_fix_fs_space');exit()" > $fix_wm/info.m
 $matlab_path -batch info
rm $fix_wm/info.m

mv $DIRm/aseg.auto.mgz  $DIRm/aseg.presurf_orig.mgz
mv $DIRm/aseg.presurf.mgz $DIRm/aseg.presurf_orig.mgz


${FREESURFER_HOME}/bin/mri_convert $fix_wm/brain_for_fix_fs_space_fake.nii.gz $DIRm/aseg.presurf.mgz
${FREESURFER_HOME}/bin/mri_convert $fix_wm/brain_for_fix_fs_space_fake.nii.gz $DIRm/aseg.presurf.mgz
${FREESURFER_HOME}/bin/mri_convert $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz $DIR_bm/MASK_ATLAS_TO_T1_fake.mgz
${FREESURFER_HOME}/bin/mri_convert $DIR_bm/MASK_ATLAS_TO_T1_fake.mgz  $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz

###---------------------------------------------------------fix mask
${FREESURFER_HOME}/bin/mri_convert $DIRm/norm.mgz $DIRm/norm.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIRm/brain.mgz $DIRm/brain.nii.gz
${FSLDIR}/bin/fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $DIRm/brain.nii.gz $DIRm/brain.nii.gz
${FSLDIR}/bin/fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $DIRm/norm.nii.gz  $DIRm/norm.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIRm/norm.nii.gz $DIRm/norm.mgz
${FREESURFER_HOME}/bin/mri_convert $DIRm/brain.nii.gz $DIRm/brain.mgz
cp $DIRm/brain.mgz $DIRm/brain.finalsurfs.mgz
${FREESURFER_HOME}/bin/mri_segment -mprage $DIRm/brain.mgz $DIRm/wm.seg.mgz
${FREESURFER_HOME}/bin/mri_edit_wm_with_aseg -keep-in $DIRm/wm.seg.mgz $DIRm/brain.mgz $DIRm/aseg.presurf.mgz $DIRm/wm.asegedit.mgz
${FREESURFER_HOME}/bin/mri_pretess $DIRm/wm.asegedit.mgz wm $DIRm/norm.mgz $DIRm/wm.mgz
${FREESURFER_HOME}/bin/mri_fill -a $DIR/scripts/ponscc.cut.log -xform $DIRm/transforms/talairach.lta -segmentation $DIRm/aseg.auto_noCCseg.mgz $DIRm/wm.mgz $DIRm/filled.mgz

##---------------------------------------------------------Filling subcortical structures
mask_for_bg=$templates_path/gb_mod.nii.gz
claustro_mask=$templates_path/claustros.nii.gz

#--------------------------------------------------------- Process

$ants_path/WarpImageMultiTransform 3 $mask_for_bg $fix_wm/bg_ventricules.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
$ants_path/WarpImageMultiTransform 3 $claustro_mask $fix_wm/claustro.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
${FSLDIR}/bin/fslmaths $fix_wm/claustro.nii.gz -mul 30 $fix_wm/claustro.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/claustro.nii.gz -fmean $fix_wm/claustro.nii.gz

${FSLDIR}/bin/fslmaths $DIR_bm/MASK_ATLAS_TO_T1.nii.gz -mul $DIR_bm/T1_no_fake.nii.gz $DIR_bm/brain_no_fake.nii.gz

${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules.nii.gz -dilM $fix_wm/bg_ventricules.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules.nii.gz -fmean $fix_wm/bg_ventricules_smooth.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules.nii.gz -binv  $fix_wm/bg_ventricules_binv.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules_binv.nii.gz -fmean $fix_wm/bg_ventricules_binv_smooth.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules_smooth.nii.gz -mul 110 $fix_wm/bg_ventricules_smooth_mul.nii.gz

${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $reference_image -out $fix_wm/brain_for_fix_gb.nii.gz -dof 12 -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -omat $fix_wm/brain_for_fix_gb.mat

${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $fix_wm/bg_ventricules_smooth_mul.nii.gz -applyxfm -init $fix_wm/brain_for_fix_gb.mat -out $fix_wm/bg_ventricules_smooth_mul_fs_space.nii.gz
${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $fix_wm/bg_ventricules_binv_smooth.nii.gz -applyxfm -init $fix_wm/brain_for_fix_gb.mat -out $fix_wm/bg_ventricules_smooth_binv_fs_space.nii.gz
${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $fix_wm/claustro.nii.gz -applyxfm -init $fix_wm/brain_for_fix_gb.mat -out $fix_wm/claustro.nii.gz -interp nearestneighbour


cd $fix_wm
echo "addpath('$scripts_path');fake_space('$fix_wm/','T1',[1;1;1;1;0;0;0;0],'_fake','bg_ventricules_smooth_mul_fs_space');exit()" > $fix_wm/info.m
 $matlab_path -batch info
rm $fix_wm/info.m


cd $fix_wm
echo "addpath('$scripts_path');fake_space('$fix_wm/','T1',[1;1;1;1;0;0;0;0],'_fake','bg_ventricules_smooth_binv_fs_space');exit()" > $fix_wm/info.m
 $matlab_path -batch info
rm $fix_wm/info.m

cd $fix_wm
echo "addpath('$scripts_path');fake_space('$fix_wm/','T1',[1;1;1;1;0;0;0;0],'_fake','claustro');exit()" > $fix_wm/info.m
 $matlab_path -batch info
rm $fix_wm/info.m


mv $DIRm/brain.mgz $DIRm/brain_ori.mgz
mv $DIRm/norm.mgz $DIRm/norm_orig.mgz
${FREESURFER_HOME}/bin/mri_convert $DIRm/brain_ori.mgz $DIRm/brain_ori.nii.gz
${FREESURFER_HOME}/bin/mri_convert $fix_wm/bg_ventricules_smooth_mul_fs_space_fake.nii.gz $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz
${FREESURFER_HOME}/bin/mri_convert $fix_wm/bg_ventricules_smooth_binv_fs_space_fake.nii.gz $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz

${FREESURFER_HOME}/bin/mri_convert $DIRm/norm_orig.mgz $DIRm/norm_orig.nii.gz

#apply_brain
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz -mul $DIRm/brain_ori.nii.gz $fix_wm/bg_ventricules_fs_no_bg.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules_fs_no_bg.nii.gz -add $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz $fix_wm/fix_wm_fs_space.nii.gz

#apply norm
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz -mul $DIRm/norm_orig.nii.gz $fix_wm/bg_ventricules_fs_no_bg_norm.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules_fs_no_bg_norm.nii.gz -add $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz $fix_wm/fix_wm_fs_space_norm.nii.gz

${FREESURFER_HOME}/bin/mri_convert $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz $DIR_bm/MASK_ATLAS_TO_T1_fake.mgz
${FREESURFER_HOME}/bin/mri_convert $DIR_bm/MASK_ATLAS_TO_T1_fake.mgz  $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz

#fix mask
${FSLDIR}/bin/fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $fix_wm/fix_wm_fs_space.nii.gz $DIRm/brain.nii.gz
${FSLDIR}/bin/fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $fix_wm/fix_wm_fs_space_norm.nii.gz $DIRm/norm.nii.gz

## add claustros
${FSLDIR}/bin/fslmaths $DIRm/brain.nii.gz -add  $fix_wm/claustro_fake.nii.gz $DIRm/brain.nii.gz
${FSLDIR}/bin/fslmaths $DIRm/norm.nii.gz -add  $fix_wm/claustro_fake.nii.gz $DIRm/norm.nii.gz

${FREESURFER_HOME}/bin/mri_convert $DIRm/brainmask.mgz $DIRm/brainmask.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz -mul $DIRm/brainmask.nii.gz $DIRm/brainmask_1.nii.gz
${FSLDIR}/bin/fslmaths $DIRm/brainmask_1.nii.gz -add $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz $DIRm/brainmask_2.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIRm/brainmask_2.nii.gz $DIRm/brainmask.mgz
${FREESURFER_HOME}/bin/mri_add_xform_to_header -c $DIRm/transforms/talairach.xfm $DIRm/brainmask.mgz $DIRm/brainmask.mgz
cp $DIRm/brainmask.mgz $DIRm/brainmask.auto.mgz

${FREESURFER_HOME}/bin/mri_convert $DIRm/nu.mgz $DIRm/nu.nii.gz
${FSLDIR}/bin/fslmaths $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz -mul $DIRm/nu.nii.gz $DIRm/nu_1.nii.gz
${FSLDIR}/bin/fslmaths $DIRm/nu_1.nii.gz -add $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz $DIRm/nu_2.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIRm/nu_2.nii.gz $DIRm/nu.mgz
${FREESURFER_HOME}/bin/mri_add_xform_to_header -c $DIRm/transforms/talairach.xfm $DIRm/nu.mgz $DIRm/nu.mgz

${FREESURFER_HOME}/bin/mri_convert $DIRm/brain.nii.gz $DIRm/brain.mgz
${FREESURFER_HOME}/bin/mri_convert $DIRm/norm.nii.gz $DIRm/norm.mgz
cp $DIRm/brain.mgz $DIRm/brain.finalsurfs.mgz
#----------------------------------------------------HICPO
Template_image=$templates_path/NMT_brain.nii.gz
High_Intensity_ROI=$templates_path/ROI_pg_visual_c.nii.gz

DIRs=$SUBJECTS_DIR/$SUB_ID/surf
mkdir $DIR/mri/HICPO/
HICPO=$DIR/mri/HICPO

cd $DIRm
#----------------------------------------------------Fix wm with norm
cp $DIRm/brain.mgz $DIRm/brain_orig_after_MACS.mgz
cp $DIRm/norm.mgz $DIRm/brain.mgz

${FREESURFER_HOME}/bin/mri_segment -mprage -wlo 105 -ghi 100 $DIR/mri/brain.mgz  $HICPO/wm.seg_MOD.mgz

${FREESURFER_HOME}/bin/mri_convert $DIR/mri/T1.mgz $HICPO/T1.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/wm.seg.mgz $HICPO/wm.seg.nii.gz
${FREESURFER_HOME}/bin/mri_convert $HICPO/wm.seg_MOD.mgz $HICPO/wm.seg_MOD.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/brain.mgz $HICPO/brain.nii.gz

cd $HICPO
echo "addpath('$scripts_path');convert('$HICPO/',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake');exit()" > $HICPO/info.m
$matlab_path -batch info
rm $HICPO/info.m

$ants_path/WarpImageMultiTransform 3 $High_Intensity_ROI $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -applyxfm -init $fix_wm/brain_for_fix_fs.mat -out $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -interp nearestneighbour


${FSLDIR}/bin/fslmaths $HICPO/wm.seg_MOD.nii.gz -binv $HICPO/wm.seg_MOD_binv.nii.gz
${FSLDIR}/bin/fslmaths $HICPO/wm.seg_MOD_binv.nii.gz -mul $HICPO/wm.seg.nii.gz $HICPO/bump.nii.gz


${FSLDIR}/bin/fslmaths $HICPO/bump.nii.gz -mul $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz $HICPO/bump_error.nii.gz #error estimation

${FSLDIR}/bin/fslmaths $HICPO/bump_error.nii.gz -sub 80 $HICPO/resta.nii.gz
${FSLDIR}/bin/fslmaths $HICPO/resta.nii.gz -bin $HICPO/resta_bin.nii.gz
${FSLDIR}/bin/fslmaths $HICPO/resta_bin.nii.gz -mul $HICPO/resta.nii.gz $HICPO/low_values.nii.gz
${FSLDIR}/bin/fslmaths $HICPO/low_values.nii.gz -bin $HICPO/low_values_bin.nii.gz

#----------------------------------------------------------SMOOTH
${FSLDIR}/bin/fslmaths $HICPO/low_values_bin.nii.gz -kernel box 3x3x3 -fmean $HICPO/low_values_bin_smooth.nii.gz

#----------------------------------------------------------Changes values

${FSLDIR}/bin/fslmaths $HICPO/low_values_bin_smooth.nii.gz -mul -20 $HICPO/low_values_normalize.nii.gz

${FSLDIR}/bin/fslmaths $HICPO/low_values_normalize.nii.gz -add $HICPO/brain.nii.gz $HICPO/brain_normalize_HI.nii.gz

cp $DIR/mri/brain.mgz $DIR/mri/brain_original.mgz
${FREESURFER_HOME}/bin/mri_convert $HICPO/brain_normalize_HI.nii.gz $DIR/mri/brain.mgz


#----------------------------------------------------------FIX WM with brain normalize previosly fix norm
mv $DIR/mri/brain.mgz $DIR/mri/norm.mgz
${FREESURFER_HOME}/bin/mri_normalize -mprage -aseg $DIRm/aseg.presurf_orig.mgz -mask $DIRm/brainmask.mgz $DIRm/norm.mgz $DIRm/brain.mgz

#----------------------------------------------------------Segmentacion WM

${FREESURFER_HOME}/bin/mri_mask -T 5 $DIRm/brain.mgz $DIRm/brainmask.mgz $DIRm/brain.finalsurfs.mgz
${FREESURFER_HOME}/bin/mri_segment -mprage $DIRm/brain.mgz $DIRm/wm.seg.mgz

#----------------------------------------------------------CLEAN WM.SEG.MZ
${FREESURFER_HOME}/bin/mri_segment -mprage -wlo 100 -ghi 110 $DIR/mri/brain.mgz  $HICPO/wm.seg_MOD.mgz
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/T1.mgz $HICPO/T1.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/wm.seg.mgz $HICPO/wm.seg.nii.gz
${FREESURFER_HOME}/bin/mri_convert $HICPO/wm.seg_MOD.mgz $HICPO/wm.seg_MOD.nii.gz

cd $HICPO
echo "addpath('$scripts_path');convert('$HICPO/',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake');exit()" > $HICPO/info.m
$matlab_path -batch info
rm $HICPO/info.m

$ants_path/WarpImageMultiTransform 3 $High_Intensity_ROI $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -applyxfm -init $fix_wm/brain_for_fix_fs.mat -out $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -interp nearestneighbour

${FSLDIR}/bin/fslmaths $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -binv $HICPO/MASK_WM.SEG_MOD_FOR_CROP.nii.gz
${FSLDIR}/bin/fslmaths $HICPO/MASK_WM.SEG_MOD_FOR_CROP.nii.gz -mul $HICPO/wm.seg_no_fake.nii.gz $HICPO/1.nii.gz
${FSLDIR}/bin/fslmaths $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -mul $HICPO/wm.seg_MOD_no_fake.nii.gz $HICPO/2.nii.gz
${FSLDIR}/bin/fslmaths $HICPO/1.nii.gz -add $HICPO/2.nii.gz $HICPO/wm.seg_final_no_fake.nii.gz -odt char

cd $HICPO
echo "addpath('$scripts_path');convert_wm_ed_fake('$HICPO/');exit()" > $HICPO/info.m
$matlab_path -batch info
rm $HICPO/info.m

mv $DIRm/wm.seg.mgz $DIRm/wm.seg_original.mgz
mv $DIRm/wm.mgz $DIRm/wm_ORIGINAL.mgz

${FREESURFER_HOME}/bin/mri_convert $HICPO/wm.seg_final_fake.nii.gz $DIRm/wm.seg.mgz --out_data_type uchar
${FREESURFER_HOME}/bin/mri_edit_wm_with_aseg -keep-in $DIRm/wm.seg.mgz $DIRm/brain.mgz $DIRm/aseg.presurf.mgz $DIRm/wm.asegedit.mgz
${FREESURFER_HOME}/bin/mri_pretess $DIRm/wm.asegedit.mgz wm $DIRm/norm.mgz $DIRm/wm.mgz

#-----------------------------------------------------Fill

${FREESURFER_HOME}/bin/mri_fill -a $DIR/scripts/ponscc.cut.log -xform $DIRm/transforms/talairach.lta -segmentation $DIRm/aseg.auto_noCCseg.mgz $DIRm/wm.mgz $DIRm/filled.mgz

#-----------------------------------------------------Tessellate lh

 ${FREESURFER_HOME}/bin/mri_pretess $DIRm/filled.mgz 255 $DIR/mri/norm.mgz $DIR/mri/filled-pretess255.mgz

 ${FREESURFER_HOME}/bin/mri_tessellate $DIRm/filled-pretess255.mgz 255 $DIR/surf/lh.orig.nofix

 rm -f $DIRm/filled-pretess255.mgz

 ${FREESURFER_HOME}/bin/mris_extract_main_component $DIR/surf/lh.orig.nofix $DIR/surf/lh.orig.nofix

 ${FREESURFER_HOME}/bin/mri_pretess $DIRm/filled.mgz 127 $DIRm/norm.mgz $DIRm/filled-pretess127.mgz

 ${FREESURFER_HOME}/bin/mri_tessellate $DIRm/filled-pretess127.mgz 127 $DIR/surf/rh.orig.nofix

 rm -f $DIRm/filled-pretess127.mgz

 ${FREESURFER_HOME}/bin/mris_extract_main_component $DIR/surf/rh.orig.nofix $DIR/surf/rh.orig.nofix

#------------------------------------------------------Smooth1

 ${FREESURFER_HOME}/bin/mris_smooth -nw -seed 1234 $DIR/surf/lh.orig.nofix $DIR/surf/lh.smoothwm.nofix

 ${FREESURFER_HOME}/bin/mris_smooth -nw -seed 1234 $DIR/surf/rh.orig.nofix $DIR/surf/rh.smoothwm.nofix

#------------------------------------------------------Inflation1

 ${FREESURFER_HOME}/bin/mris_inflate -no-save-sulc $DIR/surf/lh.smoothwm.nofix $DIR/surf/lh.inflated.nofix

 ${FREESURFER_HOME}/bin/mris_inflate -no-save-sulc $DIR/surf/rh.smoothwm.nofix $DIR/surf/rh.inflated.nofix

#------------------------------------------------------QSphere

 ${FREESURFER_HOME}/bin/mris_sphere -q -seed 1234 $DIR/surf/lh.inflated.nofix $DIR/surf/lh.qsphere.nofix

 ${FREESURFER_HOME}/bin/mris_sphere -q -seed 1234 $DIR/surf/rh.inflated.nofix $DIR/surf/rh.qsphere.nofix

#------------------------------------------------------Fix Topology

 cp $DIR/surf/lh.orig.nofix $DIR/surf/lh.orig
 cp $DIR/surf/lh.inflated.nofix $DIR/surf/lh.inflated

 cp $DIR/surf/rh.orig.nofix $DIR/surf/rh.orig
 cp $DIR/surf/rh.inflated.nofix $DIR/surf/rh.inflated


 ${FREESURFER_HOME}/bin/mris_fix_topology -rusage $DIR/touch/rusage.mris_fix_topology.lh.dat -mgz -sphere qsphere.nofix -ga -seed 1234 $SUB_ID lh

 ${FREESURFER_HOME}/bin/mris_fix_topology -rusage $DIR/touch/rusage.mris_fix_topology.rh.dat -mgz -sphere qsphere.nofix -ga -seed 1234 $SUB_ID rh

 ${FREESURFER_HOME}/bin/mris_euler_number $DIR/surf/lh.orig

 ${FREESURFER_HOME}/bin/mris_euler_number $DIR/surf/rh.orig

 ${FREESURFER_HOME}/bin/mris_remove_intersection $DIR/surf/lh.orig $DIR/surf/lh.orig


 rm $DIR/surf/lh.inflated


 ${FREESURFER_HOME}/bin/mris_remove_intersection $DIR/surf/rh.orig $DIR/surf/rh.orig


 rm $DIR/surf/rh.inflated

#---------------------------------------------------------Make White Surf

 ${FREESURFER_HOME}/bin/mris_make_surfaces -aseg aseg.presurf -white white.preaparc -noaparc -whiteonly -mgz -T1 brain.finalsurfs $SUB_ID lh

 ${FREESURFER_HOME}/bin/mris_make_surfaces -aseg aseg.presurf -white white.preaparc -noaparc -whiteonly -mgz -T1 brain.finalsurfs $SUB_ID rh


#---------------------------------------------------------Smooth2
${FREESURFER_HOME}/bin/mris_smooth -n 3 -nw -seed 1234 $DIR/surf/lh.white.preaparc $DIR/surf/lh.smoothwm

${FREESURFER_HOME}/bin/mris_smooth -n 3 -nw -seed 1234 $DIR/surf/rh.white.preaparc $DIR/surf/rh.smoothwm

#--------------------------------------------------------Inflation2 lh
${FREESURFER_HOME}/bin/mris_inflate -rusage $DIR/touch/rusage.mris_inflate.lh.dat $DIR/surf/lh.smoothwm $DIR/surf/lh.inflated

${FREESURFER_HOME}/bin/mris_inflate -rusage $DIR/touch/rusage.mris_inflate.rh.dat $DIR/surf/rh.smoothwm $DIR/surf/rh.inflated

#--------------------------------------------------------Curv .H and .K
${FREESURFER_HOME}/bin/mris_curvature -w $DIR/surf/lh.white.preaparc
${FREESURFER_HOME}/bin/mris_curvature -thresh .999 -n -a 5 -w -distances 10 10 $DIR/surf/lh.inflated

${FREESURFER_HOME}/bin/mris_curvature -w $DIR/surf/rh.white.preaparc
${FREESURFER_HOME}/bin/mris_curvature -thresh .999 -n -a 5 -w -distances 10 10 $DIR/surf/rh.inflated

#--------------------------------------------------------Curvature Stats lh

${FREESURFER_HOME}/bin/mris_curvature_stats -m --writeCurvatureFiles -G -o $DIR/stats/lh.curv.stats -F smoothwm $SUB_ID lh curv sulc
${FREESURFER_HOME}/bin/mris_curvature_stats -m --writeCurvatureFiles -G -o $DIR/stats/rh.curv.stats -F smoothwm $SUB_ID rh curv sulc

#----------------------------------------------- ET2L ---------------------------------------------------
mkdir $DIR/mri/ET2L/
ETOOL=$DIR/mri/ET2L/

Mean_Wall=$templates_path/mean_wall_NMT.nii.gz
HIPO_MASK=$templates_path/hipos_amigdalas.nii.gz

cp -r $DIRs $DIR/surf_PRE_ET2L
cp -r $DIRm $DIR/mri_PRE_ET2L

#-----------------------------------------------------------SURFACE REGISTRATION
${FREESURFER_HOME}/bin/mris_sphere -rusage $DIR/touch/rusage.mris_sphere.lh.dat -seed 1234 $DIRs/lh.inflated $DIRs/lh.sphere
${FREESURFER_HOME}/bin/mris_sphere -rusage $DIR/touch/rusage.mris_sphere.rh.dat -seed 1234 $DIRs/rh.inflated $DIRs/rh.sphere

${FREESURFER_HOME}/bin/mris_register -curv -rusage $DIR/touch/rusage.mris_register.lh.dat $DIRs/lh.sphere $templates_path/lh.PREEMACS_34_v1.tif $DIRs/lh.sphere.reg

${FREESURFER_HOME}/bin/mris_register -curv -rusage $DIR/touch/rusage.mris_register.rh.dat $DIRs/rh.sphere $templates_path/rh.PREEMACS_34_v1.tif $DIRs/rh.sphere.reg


${FREESURFER_HOME}/bin/mris_jacobian $DIRs/lh.white.preaparc $DIRs/lh.sphere.reg $DIRs/lh.jacobian_white

${FREESURFER_HOME}/bin/mris_jacobian $DIRs/rh.white.preaparc $DIRs/rh.sphere.reg $DIRs/rh.jacobian_white

${FREESURFER_HOME}/bin/mrisp_paint -a 5 $templates_path/lh.PREEMACS_34_v1.tif#6 $DIRs/lh.sphere.reg $DIRs/lh.avg_curv

${FREESURFER_HOME}/bin/mrisp_paint -a 5 $templates_path/rh.PREEMACS_34_v1.tif#6 $DIRs/rh.sphere.reg $DIRs/rh.avg_curv


${FREESURFER_HOME}/bin/mris_ca_label -l $DIR/label/lh.cortex.label -aseg $DIR/mri/aseg.presurf.mgz -seed 1234 $SUB_ID lh $DIRs/lh.sphere.reg ${FREESURFER_HOME}/average/lh.DKaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs $DIR/label/lh.aparc.annot

${FREESURFER_HOME}/bin/mris_ca_label -l $DIR/label/rh.cortex.label -aseg $DIR/mri/aseg.presurf.mgz -seed 1234 $SUB_ID rh $DIRs/rh.sphere.reg ${FREESURFER_HOME}/average/lh.DKaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs $DIR/label/rh.aparc.annot

#----------------------------------------------------------Make Pial Surf
${FREESURFER_HOME}/bin/mri_convert $DIRm/brain.finalsurfs.mgz $ETOOL/brain.finalsurfs.nii.gz

cd $ETOOL
echo "addpath('$scripts_path');convertseq('$ETOOL','T1',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake','brain.finalsurfs');exit()" > $ETOOL/info.m
$matlab_path -batch info
rm $ETOOL/info.m

#-------------  1.Get FS labels from NMT

reference_image=$path_job/brain.nii.gz
image_1Warp_05=$NMT_REG/NMT_to_T1_05_1Warp.nii.gz
txt_from_registration_05=$NMT_REG/NMT_to_T1_05_0GenericAffine.txt

${FREESURFER_HOME}/bin/mris_make_surfaces -orig_white white.preaparc -orig_pial white.preaparc -max 10 -aseg aseg.presurf -mgz -T1 brain.finalsurfs $SUB_ID lh

${FREESURFER_HOME}/bin/mris_make_surfaces -orig_white white.preaparc -orig_pial white.preaparc -max 10 -aseg aseg.presurf -mgz -T1 brain.finalsurfs $SUB_ID rh
${FREESURFER_HOME}/bin/mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID

${FREESURFER_HOME}/bin/mri_convert  $DIRm/lh.ribbon.mgz $DIRm/lh.ribbon.nii.gz
${FREESURFER_HOME}/bin/mri_convert  $DIRm/rh.ribbon.mgz $DIRm/rh.ribbon.nii.gz

${FSLDIR}/bin/fslmaths $DIRm/lh.ribbon.nii.gz -add $DIRm/rh.ribbon.nii.gz $DIRm/ribbon_cross.nii.gz
${MRTRIX_DIR}/mrcalc $DIRm/ribbon_cross.nii.gz 2 -eq $DIRm/cross_T1.nii.gz -force
${FSLDIR}/bin/fslmaths $DIRm/cross_T1.nii.gz -binv $DIRm/cross_T1_binv.nii.gz
${FSLDIR}/bin/fslmaths $DIRm/cross_T1_binv.nii.gz -mul $ETOOL/brain.finalsurfs_no_fake.nii.gz $ETOOL/brain.finalsurfs_no_fake_no_T2_cross.nii.gz

cd $ETOOL
echo "addpath('$scripts_path');convertseq('$ETOOL','T1',[1;1;1;1;0;0;0;0],'_fake','brain.finalsurfs_no_fake_no_T2_cross');exit()" > $ETOOL/info.m
$matlab_path -batch info
rm $ETOOL/info.m

${FSLDIR}/bin/fslmaths  $ETOOL/brain.finalsurfs_no_fake_no_T2_cross_fake.nii.gz -mul $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz $ETOOL/brain.finalsurfs_no_fake_no_T2_cross_fake.nii.gz

${FREESURFER_HOME}/bin/mri_convert $ETOOL/brain.finalsurfs_no_fake_no_T2_cross_fake.nii.gz $DIRm/brain.finalsurfs.mgz

${FREESURFER_HOME}/bin/mris_make_surfaces -orig_white white.preaparc -orig_pial white.preaparc -max 10 -aseg aseg.presurf -mgz -T1 brain.finalsurfs $SUB_ID lh

${FREESURFER_HOME}/bin/mris_make_surfaces -orig_white white.preaparc -orig_pial white.preaparc -max 10 -aseg aseg.presurf -mgz -T1 brain.finalsurfs $SUB_ID rh
${FREESURFER_HOME}/bin/mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID

${FREESURFER_HOME}/bin/mri_convert $DIR/mri/orig/T2raw.mgz  $DIR/mri/orig/T2raw.nii.gz
$ants_path/ImageMath 3 $DIR/mri/orig/T2raw.nii.gz TruncateImageIntensity $DIR/mri/orig/T2raw.nii.gz

# ########################## PREPARE RIBBON  ##################################
cp $DIR/mri/ribbon.mgz  $ETOOL/ribbon_original.mgz
cp $DIR/mri/ribbon.mgz  $DIR/mri/ribbon_firt.mgz
mv $DIR/mri/ribbon.mgz  $ETOOL/ribbon_sin_T2.mgz

# # # ##################### T2 PIAL SURFACE WITH KISS ERROR ###################

cp $DIR/mri/orig/T2raw.mgz $DIR/mri/orig/T2raw.mgz #NO_TEMPLATE
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/orig/T2raw.mgz $DIR/mri/orig/T2raw.nii.gz
${minc_path}/mincnlm_nii.sh $DIR/mri/orig/T2raw.nii.gz  $DIR/mri/orig/T2raw_deno.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/orig/T2raw_deno.nii.gz $DIR/mri/orig/T2raw.mgz
#rm $DIR/mri/orig/T2raw_deno.nii.gz
rm $DIR/mri/orig/T2raw.nii.gz

${FREESURFER_HOME}/bin/bbregister --s $SUB_ID --mov $DIR/mri/orig/T2raw.mgz --lta $DIR/mri/transforms/T2raw.auto.lta --init-coreg --T2

cp $DIR/mri/transforms/T2raw.auto.lta $DIR/mri/transforms/T2raw.lta

${FREESURFER_HOME}/bin/mri_convert -odt float -at $DIR/mri/transforms/T2raw.lta -rl $DIR/mri/orig.mgz $DIR/mri/orig/T2raw.mgz $DIR/mri/T2.prenorm.mgz

${FREESURFER_HOME}/bin/mri_normalize -sigma 0.5 -nonmax_suppress 0 -min_dist 1 -aseg $DIR/mri/aseg.presurf_orig.mgz -surface $DIR/surf/rh.white identity.nofile -surface $DIR/surf/lh.white identity.nofile $DIR/mri/T2.prenorm.mgz $DIR/mri/T2.norm.mgz

${FREESURFER_HOME}/bin/mri_mask $DIR/mri/T2.norm.mgz $DIR/mri/brainmask.mgz $DIR/mri/T2.mgz

cp -v $DIR/surf/lh.pial $DIR/surf/lh.woT2.pial
cp -v $DIR/surf/lh.pial $DIR/surf/lh.orig.pial

${FREESURFER_HOME}/bin/mris_make_surfaces -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 2 -nsigma_below 5 $SUB_ID lh

cp -v $DIR/surf/rh.pial $DIR/surf/rh.woT2.pial
cp -v $DIR/surf/rh.pial $DIR/surf/rh.orig.pial

${FREESURFER_HOME}/bin/mris_make_surfaces -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 2 -nsigma_below 5 $SUB_ID rh

# # ######################## Cortical ribbon mask  ########################

${FREESURFER_HOME}/bin/mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID
# # # ######################## FIX T2 PIAL SURFACE KISS ####################
mv $DIR/mri/ribbon.mgz $ETOOL/ribbon_kiss.mgz

${FREESURFER_HOME}/bin/mri_convert $DIR/mri/T1.mgz          $ETOOL/T1.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/T2.prenorm.mgz  $ETOOL/T2.prenorm.nii.gz
${FREESURFER_HOME}/bin/mri_convert $ETOOL/ribbon_kiss.mgz   $ETOOL/ribbon_kiss.nii.gz
${FREESURFER_HOME}/bin/mri_convert $ETOOL/ribbon_sin_T2.mgz $ETOOL/ribbon_sin_T2.nii.gz


${FSLDIR}/bin/fslmaths $ETOOL/ribbon_kiss.nii.gz -add $ETOOL/ribbon_sin_T2.nii.gz $ETOOL/ribbon_sum.nii.gz

${MRTRIX_DIR}/mrcalc $ETOOL/ribbon_sum.nii.gz 25  -eq $ETOOL/ribbon_25.nii.gz
${MRTRIX_DIR}/mrcalc $ETOOL/ribbon_sum.nii.gz 15 -eq $ETOOL/ribbon_15.nii.gz
${FSLDIR}/bin/fslmaths $ETOOL/ribbon_25.nii.gz -add $ETOOL/ribbon_15.nii.gz $ETOOL/diffence.nii.gz


cd $ETOOL
echo "addpath('$scripts_path');convertseq('$ETOOL','T1',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake','T1');exit()" > $ETOOL/info.m
$matlab_path -batch info
rm $ETOOL/info.m

cd $ETOOL
echo "addpath('$scripts_path');convertseq('$ETOOL','T2',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake','T2.prenorm');exit()" > $ETOOL/info.m
$matlab_path -batch info
rm $ETOOL/info.m

$ants_path/WarpImageMultiTransform 3 $Mean_Wall $ETOOL/mean_wall_reg.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN

${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $reference_image -dof 6 -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -omat $ETOOL/omat_reg_fs_space.mat -interp nearestneighbour
${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $ETOOL/mean_wall_reg.nii.gz -applyxfm -init $ETOOL/omat_reg_fs_space.mat -out $ETOOL/cross.nii.gz -interp nearestneighbour
${FSLDIR}/bin/fslmaths   $ETOOL/cross.nii.gz -mul $ETOOL/diffence.nii.gz $ETOOL/not_kiss.nii.gz
${FSLDIR}/bin/fslmaths $ETOOL/not_kiss.nii.gz -binv $ETOOL/not_kiss_binv.nii.gz
${FSLDIR}/bin/fslmaths $ETOOL/not_kiss_binv.nii.gz -mul $ETOOL/T2.prenorm_no_fake.nii.gz $ETOOL/T2_pre_pial.nii.gz


# ##################QUIT HIPOS############

$ants_path/WarpImageMultiTransform 3 $HIPO_MASK $ETOOL/Hippos.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN

${FSLDIR}/bin/flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $ETOOL/Hippos.nii.gz -applyxfm -init $ETOOL/omat_reg_fs_space.mat -out $ETOOL/HIPOS_mask.nii.gz -interp nearestneighbour -interp nearestneighbour

${FSLDIR}/bin/fslmaths $ETOOL/HIPOS_mask.nii.gz -binv $ETOOL/HIPOS_mask_inverse.nii.gz
${FSLDIR}/bin/fslmaths $ETOOL/T2_pre_pial.nii.gz -mul $ETOOL/HIPOS_mask_inverse.nii.gz $ETOOL/T2_pre_pial.nii.gz

cd $ETOOL
echo "addpath('$scripts_path');convertseq('$ETOOL','T2',[1;1;1;1;0;0;0;0],'_fake','T2_pre_pial');exit()" > $ETOOL/info.m
$matlab_path -batch info
rm $ETOOL/info.m

${FREESURFER_HOME}/bin/mri_convert $ETOOL/T2_pre_pial_fake.nii.gz $DIR/mri/T2.prenorm.mgz

# #################### SURFACE T2 without kiss #########################

${FREESURFER_HOME}/bin/mri_normalize -sigma 0.5 -nonmax_suppress 0 -min_dist 1 -aseg $DIR/mri/aseg.presurf_orig.mgz -surface $DIR/surf/rh.white identity.nofile -surface $DIR/surf/lh.white identity.nofile $DIR/mri/T2.prenorm.mgz $DIR/mri/T2.norm.mgz

${FREESURFER_HOME}/bin/mri_mask $DIR/mri/T2.norm.mgz $DIR/mri/brainmask.mgz $DIR/mri/T2.mgz

cp    $DIR/surf/lh.orig.pial $DIR/surf/lh.T1.pial
mv    $DIR/surf/lh.orig.pial $DIR/surf/lh.pial
cp -v $DIR/surf/lh.pial $DIR/surf/lh.woT2.pial

# ####################### FIX T2 PIAL SURFACE KISS 2 ########################
#  ######## Add_cortical_ribbon_to_T2 only in AMS and cingulate cortex #####

${FREESURFER_HOME}/bin/mri_convert $DIR/mri/rh.ribbon.mgz $ETOOL/rh.ribbon.nii.gz #FOR FIX T2 KISS SECOND PART
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/lh.ribbon.mgz $ETOOL/lh.ribbon.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/T2.mgz  $ETOOL/T2.before.2do.fix.kiss.nii.gz
cp $ETOOL/T2.before.2do.fix.kiss.nii.gz $DIR/mri/T2.before.fix.2ndpart.kiiss.nii.gz
${FREESURFER_HOME}/bin/mri_convert $DIR/mri/T2.before.fix.2ndpart.kiiss.nii.gz $DIR/mri/T2.before.fix.2ndpart.kiiss.mgz

${FSLDIR}/bin/fslmaths $ETOOL/lh.ribbon.nii.gz -binv $ETOOL/lh.ribbon_binv.nii.gz
${FSLDIR}/bin/fslmaths $ETOOL/rh.ribbon.nii.gz -binv $ETOOL/rh.ribbon_binv.nii.gz

${FSLDIR}/bin/fslmaths $ETOOL/rh.ribbon_binv.nii.gz -mul $ETOOL/T2.before.2do.fix.kiss.nii.gz $ETOOL/T2_wth_rh_hemisphere.nii.gz
${FREESURFER_HOME}/bin/mri_convert $ETOOL/T2_wth_rh_hemisphere.nii.gz $DIR/mri/T2.mgz

${FREESURFER_HOME}/bin/mris_make_surfaces -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 3 -nsigma_below 5 $SUB_ID lh

${FSLDIR}/bin/fslmaths $ETOOL/lh.ribbon_binv.nii.gz -mul $ETOOL/T2.before.2do.fix.kiss.nii.gz $ETOOL/T2_wth_lh_hemisphere.nii.gz
${FREESURFER_HOME}/bin/mri_convert $ETOOL/T2_wth_lh_hemisphere.nii.gz $DIR/mri/T2.mgz

cp    $DIR/surf/rh.orig.pial $DIR/surf/rh.T1.pial
mv    $DIR/surf/rh.orig.pial $DIR/surf/rh.pial
cp -v $DIR/surf/rh.pial $DIR/surf/rh.woT2.pial

${FREESURFER_HOME}/bin/mris_make_surfaces -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 3 -nsigma_below 5 $SUB_ID rh

# ######################## Cortical ribbon mask  ########################
${FREESURFER_HOME}/bin/mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID

${FREESURFER_HOME}/bin/mri_vol2surf --mov $DIR/mri/rawavg.mgz --hemi lh --noreshape --interp trilinear --projdist -1 --o $DIR/surf/lh.wm.mgh --regheader $SUB_ID --cortex
${FREESURFER_HOME}/bin/mri_vol2surf --mov $DIR/mri/rawavg.mgz --hemi lh --noreshape --interp trilinear --o $DIR/surf/lh.gm.mgh --projfrac 0.3 --regheader $SUB_ID --cortex
${FREESURFER_HOME}/bin/mri_concat $DIR/surf/lh.wm.mgh $DIR/surf/lh.gm.mgh --paired-diff-norm --mul 100 --o $DIR/surf/lh.w-g.pct.mgh

${FREESURFER_HOME}/bin/mri_vol2surf --mov $DIR/mri/rawavg.mgz --hemi rh --noreshape --interp trilinear --projdist -1 --o $DIR/surf/rh.wm.mgh --regheader $SUB_ID --cortex
${FREESURFER_HOME}/bin/mri_vol2surf --mov $DIR/mri/rawavg.mgz --hemi rh --noreshape --interp trilinear --o $DIR/surf/rh.gm.mgh --projfrac 0.3 --regheader $SUB_ID --cortex
${FREESURFER_HOME}/bin/mri_concat $DIR/surf/rh.wm.mgh $DIR/surf/rh.gm.mgh --paired-diff-norm --mul 100 --o $DIR/surf/rh.w-g.pct.mgh
########################     Total Time       #########################
lopuu=$(date +%s.%N)
eri=$(echo "$lopuu - $aloita" | bc)
echo -e "\\033[38;5;220m \n TOTAL running time: ${eri} seconds \n \\033[0m"
