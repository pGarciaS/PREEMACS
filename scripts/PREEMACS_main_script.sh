#!/bin/bash
print_help() {
echo "
Usage:


	`basename $0` SUB_ID T1 T2 PREEMACS_PATH


Options
      - Only T1 -only T1
	  - Sphinx orientation -sphinx
	  - Orientation based on vitamin E -correct VE -incorrect VE
	  - coords CA-CP -coords

Options -ROI

Pam Garcia
INB May,2020
np.pam.garcia@gmail.com
"
}
#------------------------------------------------------------------------------#
#			 Declaring variables & WARNINGS
if [ $# -lt 1 ]
then
	echo -e "\e[0;36m\n[ERROR]... Argument missing: \n\e[0m\t\T2 $2 \n\t\tYou need T2 or T1 option$4"
	print_help
	exit 1
fi


SUB_ID=$1
T1_image_path=$2
T2_image_path=$3
PREEMACS_PATH=$4
#----------------------- Files struct------------------------------------------------------#
mkdir $PREEMACS_PATH/Module1
PREEMACS_DIR=$PREEMACS_PATH/Module1
mkdir $PREEMACS_DIR/$SUB_ID
mkdir $PREEMACS_DIR/$SUB_ID/crop
mkdir $PREEMACS_DIR/$SUB_ID/crop/antsREg
mkdir $PREEMACS_DIR/$SUB_ID/image_conform
mkdir $PREEMACS_DIR/$SUB_ID/N4_T1
mkdir $PREEMACS_DIR/$SUB_ID/N4_T2
mkdir $PREEMACS_DIR/$SUB_ID/orig
mkdir $PREEMACS_DIR/$SUB_ID/tmp
mkdir $PREEMACS_DIR/$SUB_ID/scripts
mkdir $PREEMACS_DIR/$SUB_ID/reorient

#------------------------ Variables ------------------------------------------------------#
path_job=$PREEMACS_DIR/$SUB_ID
reorient_path=$PREEMACS_DIR/$SUB_ID/reorient
TMP=$path_job/tmp
image_conform=$PREEMACS_DIR/$SUB_ID/image_conform
scripts=$PREEMACS_DIR/$SUB_ID/scripts
path_crop=$PREEMACS_DIR/$SUB_ID/crop
path_ants_reg=$PREEMACS_DIR/$SUB_ID/crop/antsREg
N4_T1_path=$PREEMACS_DIR/$SUB_ID/N4_T1
N4_T2_path=$PREEMACS_DIR/$SUB_ID/N4_T2
CARETDIR=$PREEMACS_PATH/CARETDIR

###################################################  Module 1 #######################################################
################################################## Start process to crop ############################################
cd $T1_image_path
num_ima=1
for file in *.nii.gz; do cp $T1_image_path/$file $PREEMACS_DIR/$SUB_ID/orig/raw_${num_ima}_T1.nii.gz; num_ima=$[num_ima +1];  done

#if T2
cd $T2_image_path

for file in *.nii.gz; do cp $T2_image_path/$file $PREEMACS_DIR/$SUB_ID/orig/raw_${num_ima}_T2.nii.gz; num_ima=$[num_ima +1 ]; done

############################################## 1. FIx Orientation
cd $PREEMACS_DIR/$SUB_ID/orig/
					for d in *nii.gz; do  #Have an option for incorrect orientation (mabybe only my image have a bad orientation)
					#mri_convert $d ${d/.nii.gz/}_S.nii.gz --sphinx
					#mri_convert $d $d --sphinx
					fslreorient2std $d $reorient_path/${d/.nii.gz/}_REO.nii.gz

mrinfo $reorient_path/${d/.nii.gz/}_REO.nii.gz > $TMP/${d/.nii.gz/}_REO.txt

grep strides $TMP/${d/.nii.gz/}_REO.txt > $TMP/${d/.nii.gz/}_strides.txt
orient=$(awk '{ print $4 }' $TMP/${d/.nii.gz/}_strides.txt)
correct_orient=1


               if [[ $orientation == NI ]]; then


		fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
		fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
		fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
			cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz

               fi


# # ################## FIX GENERAL ORIENTATION WITHOUT REV THE VITAMIN E CAPSULE
# if [ ${orient} != ${correct_orient} ]; then ### poner un condicional de no es ninguna opcion y una de que lo haga con mayuscula o minuscula
#
# 		fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
# 		fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  -x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
# 		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
# 		fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
# 		cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz
#
# fi
#
#
# ###falta opción de si quieres revisar la orientacion OPCION REVISAR ORIENTACION BASADO EN LA CAPSULA DE VITAMINA E
# if [ ${orient} != ${correct_orient} ]; then
#
# 	echo "error en correcion de orientation"
# 	fslview $reorient_path/${d/.nii.gz/}_REO.nii.gz &
#   cp $reorient_path/${d/.nii.gz/}_REO.nii.gz $TMP/${d/.nii.gz/}_REO_original.nii.gz
#
#  	#echo -e "> Does neurological orientation is correct? Y/N/"
# 	#read -p "Option: " option
#
# 	#if [[ $option == N ]]; then
#
# 		echo -e "> Based on vitamin capsule in the Right place. Is correct the orientation? Y or N or NI (no info) and close fsleyes"
# 		read -p "Orientation: " orientation ### poner un condicional de no es ninguna opcion
#
# 	        if [[ $orientation == N ]]; then
# 		fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
# 		fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
# 		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
# 		fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
# 			cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz
#                 fi
#
#                if [[ $orientation == Y ]]; then ### poner un condicional de no es ninguna opcion y una de que lo haga con mayuscula o minuscula
#
# 		fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
# 		fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  -x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
# 		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
# 		fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
# 			cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz
#
#                fi
#
#                if [[ $orientation == NI ]]; then ### poner un condicional de no es ninguna opcion y una de que lo haga con mayuscula o minuscula
#
#
# 		fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
# 		fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
# 		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
# 		fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
# 			cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz
#
#                fi
#
# 	fi

done
# ######################################## 2 Conform the image

echo "Doing crop"
echo "$path_job"

for d in *.nii.gz; do
nii_in=${d/.nii.gz/}_REO.nii.gz
nii_out=${d/.nii.gz/}_CROP_REO.nii.gz
path_out=$image_conform

cd $scripts

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');data_conform=conform2('$path_job/reorient/','$nii_in','$path_out/','$nii_out');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m

done
# ######################################## 3 Do Reg to NMT in order to obtain hte gometric to do the crop

cd $image_conform

for d in *T1_CROP_REO.nii.gz; do  #Have an option for incorrect orientation (mabybe only my image have a bad orientation)
echo $d
nii_out=$image_conform/$d
antsRegistrationSyN.sh -d 3 -f $PREEMACS_PATH/Templates/NMT_05.nii.gz -t r -m $nii_out -o $path_ants_reg/${d/.nii.gz/}_REG_
done

for d in *T2_CROP_REO.nii.gz; do  #Have an option for incorrect orientation (mabybe only my image have a bad orientation)
echo $d
nii_out=$image_conform/$d
antsRegistrationSyN.sh -d 3 -f $PREEMACS_PATH/Templates/NMT_05.nii.gz -t r -m $nii_out -o $path_ants_reg/${d/.nii.gz/}_REG_
done


rm $path_ants_reg/*_CROP_REO_REG_0GenericAffine.mat
rm $path_ants_reg/*_CROP_REO_REG_Warped.nii.gz
#

cd $path_ants_reg
					for d in *nii.gz; do
						reg_file=$d
				   	original_file=$image_conform/${d/_REG_InverseWarped.nii.gz/}.nii.gz
							echo "$original_file"

# # ######################################Outs
nii_out1=$TMP/${d/.nii.gz/}_ones.nii.gz
nii_out2=${d/.nii.gz/}_square_ones.nii.gz
nii_out3=${d/.nii.gz/}_crop.nii.gz
out_not_square_FOV=${d/.nii.gz/}_not_square_FOV.nii.gz
out_square_FOV=${d/.nii.gz/}_square_FOV.nii.gz


# # ######################################Process
cd $scripts

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');ones_reg_ants=crop_ants('$path_ants_reg/','$reg_file','$nii_out1');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd ../


fslmaths $nii_out1 -mul $original_file $TMP/$out_not_square_FOV

cd $scripts
echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');NewMat=preemacs_square_crop('$TMP/','$out_not_square_FOV','$nii_out2');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd ../

fslmaths $TMP/$nii_out2 -mul $original_file $TMP/$out_square_FOV

cd $scripts
echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');NewMat=preemacs_autocrop('$TMP/','$out_square_FOV','$nii_out3');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd ../

cp $TMP/$nii_out3 $path_crop/.
############### Doing crop for splir the head wih the best dimentions

size=${d/.nii.gz/}_crop.txt
nii_prefinal_crop=${d/.nii.gz/}_crop.nii.gz
echo $nii_prefinal_crop
cd $scripts
echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');image_crop=crop_only_brain('$TMP/','$nii_prefinal_crop','$size');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd ../
					var=$(cat $TMP/$size)
                                        echo $var

final_crop=${d/.nii.gz/}_final_crop.nii.gz
mrcrop $var $TMP/$nii_prefinal_crop $TMP/$final_crop
cp $TMP/$final_crop $path_crop/.
done

################Do first N4
cd $path_crop
  for d in *T1_CROP_REO_REG_InverseWarped_final_crop.nii.gz; do  N4_file=${d/.nii.gz/}_N4.nii.gz ;echo $N4_file; N4BiasFieldCorrection -d 3 -b [100] -i $d -o $N4_T1_path/$N4_file ; done
  for d in *T2_CROP_REO_REG_InverseWarped_final_crop.nii.gz; do  N4_file=${d/.nii.gz/}_N4.nii.gz ; N4BiasFieldCorrection -d 3 -b [100] -i $d -o $N4_T2_path/$N4_file ; done
#################Do average
cd $N4_T1_path
number_images=$(ls -l | wc -l)
echo $number_images



Template_for_Reg=$PREEMACS_DIR/$SUB_ID/scripts

				cd $N4_T1_path
				number_images=$(ls -l | wc -l)
				echo $number_images

				if [[ $number_images == 2 ]];
				 then
					 cp $N4_T1_path/*.nii.gz  $path_job/T1_preproc.nii.gz
					 mrresize -voxel 0.5 $path_job/T1_preproc.nii.gz $path_job/T1_preproc.nii.gz -force
				 fi


						 if [[ $number_images > 2 ]];
							then

				                                AnatomicalAverage -s $Template_for_Reg -o $path_job/T1_preproc.nii.gz $N4_T1_path/*.nii.gz
				                                mrresize -voxel 0.5 $path_job/T1_preproc.nii.gz $path_job/T1_preproc.nii.gz -force

						 fi



#Process T2

cd $N4_T2_path
number_images=$(ls -l | wc -l)
echo $number_images

if [[ $number_images == 2 ]];
 then
	 cp $N4_T2_path/*.nii.gz  $path_job/T2_preproc.nii.gz
	 mrresize -voxel 0.5 $path_job/T2_preproc.nii.gz $path_job/T2_preproc.nii.gz -force
 fi


	 if [[ $number_images > 2 ]];
		then
                                AnatomicalAverage -s $Template_for_Reg -o $path_job/T2_preproc.nii.gz $N4_T2_path/*.nii.gz
                                mrresize -voxel 0.5 $path_job/T2_preproc.nii.gz $path_job/T2_preproc.nii.gz -force
       fi


########## T1 T2 reg
cd $path_job/

antsRegistrationSyN.sh -d 3 -f $path_job/T1_preproc.nii.gz -m $path_job/T2_preproc.nii.gz -t r -o $path_job/T2_preproc_
rm 	$path_job/T2_preproc_0GenericAffine.mat
rm  $path_job/T2_preproc_InverseWarped.nii.gz
mv  $path_job/T2_preproc_Warped.nii.gz $path_job/T2_preproc.nii.gz


########## Conform 256 to mask
cd $path_job/

for file in *.nii.gz; do
nii_in=$file
nii_out=T1_conform.nii.gz
cd $scripts

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');data_conform=conform2('$path_job/','$nii_in','$path_job/','$nii_out');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m

fslroi $path_job/$nii_out $path_job/$nii_out 0 1

done

################################################################ Automatic brainmask ###################################################
anaconda_on
conda activate bskull

deepbrain-extractor -i $path_job/T1_conform.nii.gz -o $path_job/
mrconvert $path_job/brain_mask.nii  $path_job/mask/brain_mask_orig.nii.gz
rm $path_job/brain_mask.nii
rm $path_job/brain.nii
mkdir $path_job/HCP
fslmaths $path_job/mask/brain_mask_orig.nii.gz -mul $path_job/T1_conform.nii.gz $path_job/T1_brain.nii.gz

antsRegistrationSyN.sh -d 3 -f $path_job/T1_brain.nii.gz -m $PREEMACS_PATH/Templates/NMT_brain_05.nii.gz -t a -o $path_job/mask/NMT_to_mask_
fslmaths $path_job/mask/NMT_to_mask_Warped.nii.gz -bin $path_job/mask/NMT_to_mask_Warped_mask.nii.gz
fslmaths $path_job/mask/NMT_to_mask_Warped_mask.nii.gz -dilM $path_job/mask/NMT_to_mask_Warped_mask.nii.gz
fslmaths $path_job/mask/NMT_to_mask_Warped_mask.nii.gz -mul $path_job/T1_brain.nii.gz $path_job/T1_brain.nii.gz
fslmaths $path_job/T1_brain.nii.gz -bin $path_job/brain_mask.nii.gz
fslmaths $path_job/brain_mask.nii.gz -mul $path_job/T2_preproc.nii.gz $path_job/T2_brain.nii.gz
cp $path_job/T2_preproc.nii.gz $path_job/T2.nii.gz
cp $path_job/T1_conform.nii.gz $path_job/T1.nii.gz

anaconda_off
anaconda_off
############################################################### Module 3 #################################################################
image=$path_job/T1.nii.gz
mkdir $path_job/HCP

#BIAS FIELD CORRECTION HCP
# # # default parameters

Factor=0.5 #Leave this at 0.5 for now it is the number of standard deviations below the mean to threshold the non-brain tissues at
BiasFieldSmoothingSigma=5 #Leave this at 5mm for now
# # #----------------------------------------------------------------PROCESS
aloita=$(date +%s.%N)
echo -e "\033[48;5;125m \n [INIT]...Process BIAS \n\033[0m";
echo " "
echo " START: BiasFieldCorrection"

# #Record the input options in a log file
echo "$0 $@" >> $path_job/HCP/log.txt
echo "PWD = `pwd`" >> $path_job/HCP/log.txt
echo "date: `date`" >> $path_job/HCP/log.txt
echo " " >> $path_job/HCP/log.txt

# #  # Form sqrt(T1w*T2w), mask this and normalise by the mean
${FSLDIR}/bin/fslmaths $path_job/T1.nii.gz -mul $path_job/T2.nii.gz -abs -sqrt $path_job/HCP/T1wmulT2w.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w.nii.gz -mas $path_job/T1_brain.nii.gz $path_job/HCP/T1wmulT2w_brain.nii.gz
meanbrainval=`${FSLDIR}/bin/fslstats $path_job/HCP/T1wmulT2w_brain.nii.gz -M`
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain.nii.gz -div $meanbrainval $path_job/HCP/T1wmulT2w_brain_norm.nii.gz

# # Smooth the normalised sqrt image, using within-mask smoothing : s(Mask*X)/s(Mask)
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm.nii.gz -bin -s $BiasFieldSmoothingSigma $path_job/HCP/SmoothNorm_s${BiasFieldSmoothingSigma}.nii.gz
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm.nii.gz -s $BiasFieldSmoothingSigma -div $path_job/HCP/SmoothNorm_s${BiasFieldSmoothingSigma}.nii.gz $path_job/HCP/T1wmulT2w_brain_norm_s${BiasFieldSmoothingSigma}.nii.gz

# # Divide normalised sqrt image by smoothed version (to do simple bias correction)
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm.nii.gz -div $path_job/HCP/T1wmulT2w_brain_norm_s$BiasFieldSmoothingSigma.nii.gz $path_job/HCP/T1wmulT2w_brain_norm_modulate.nii.gz
#
# # Create a mask using a threshold at Mean - 0.5*Stddev, with filling of holes to remove any non-grey/white tissue.
STD=`${FSLDIR}/bin/fslstats $path_job/HCP/T1wmulT2w_brain_norm_modulate.nii.gz -S`
echo $STD
MEAN=`${FSLDIR}/bin/fslstats $path_job/HCP/T1wmulT2w_brain_norm_modulate.nii.gz -M`
echo $MEAN
Lower=`echo "$MEAN - ($STD * $Factor)" | bc -l`
echo $Lower
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm_modulate -thr $Lower -bin -ero -mul 255 $path_job/HCP/T1wmulT2w_brain_norm_modulate_mask
${CARETDIR}/wb_command -volume-remove-islands $path_job/HCP/T1wmulT2w_brain_norm_modulate_mask.nii.gz $path_job/HCP/T1wmulT2w_brain_norm_modulate_mask.nii.gz
#
# ## Extrapolate normalised sqrt image from mask region out to whole FOV
${FSLDIR}/bin/fslmaths $path_job/HCP/T1wmulT2w_brain_norm.nii.gz -mas $path_job/HCP/T1wmulT2w_brain_norm_modulate_mask.nii.gz -dilall $path_job/HCP/bias_raw.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/HCP/bias_raw.nii.gz -s $BiasFieldSmoothingSigma $path_job/HCP/BiasField.nii.gz

# ## Use bias field output to create corrected images
${FSLDIR}/bin/fslmaths $path_job/T1.nii.gz -div $path_job/HCP/BiasField.nii.gz -mas $path_job/T1_brain.nii.gz $path_job/HCP/T1_Brain_RestoredImage.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/T1.nii.gz -div $path_job/HCP/BiasField.nii.gz $path_job/HCP/T1_RestoredImage.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/T2.nii.gz -div $path_job/HCP/BiasField.nii.gz -mas $path_job/T2_brain.nii.gz $Output_$path_job/HCP/T2_Brain_RestoredImage.nii.gz -odt float
${FSLDIR}/bin/fslmaths $path_job/T2.nii.gz -div $path_job/HCP/BiasField.nii.gz $path_job/HCP/T2_RestoredImage.nii.gz -odt float

# ##Copias las imagenes sin bet que se usaran para iniciar FS

cp  $path_job/HCP/T1_RestoredImage.nii.gz                $path_job/T1.nii.gz
cp  $path_job/HCP/T2_RestoredImage.nii.gz                $path_job/T2.nii.gz

mkdir $path_job/before_HCP
mv $path_job/T1_preproc.nii.gz $path_job/before_HCP/T1_before_HCP.nii.gz
mv $path_job/T2_preproc.nii.gz $path_job/before_HCP/T2_before_HCP.nii.gz
mv $path_job/T1_brain.nii.gz $path_job/before_HCP/T1_brain_before_HCP.nii.gz
mv $path_job/T2_brain.nii.gz $path_job/before_HCP/T2_brain_before_HCP.nii.gz

echo " "
echo " END: BiasFieldCorrection"
echo " END: `date`" >> $path_job/HCP/log.txt

# #---------------------------------------------------------- Truncate instensity of images

ImageMath 3 $path_job/T1.nii.gz TruncateImageIntensity $path_job/T1.nii.gz

# #---------------------------------------------------------- FAKE SPACE
#
cd $scripts

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');[NII]= fake_space('$path_job/','T1',[1;1;1;1;0;0;0;0],'_fake','T1');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd $pwd

cd $scripts

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');[NII]= fake_space('$path_job/','T2',[1;1;1;1;0;0;0;0],'_fake','T2');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd $pwd
# #-------------------------------------------------------- FS process autorecon1
recon-all -i $path_job/T1_fake.nii.gz -s $SUB_ID -T2 $path_job/T2_fake.nii.gz -T2pial -autorecon1 -noskullstrip
# #--------------------------------------------------------  mask process based on PREEMACS mask
echo -e "\033[48;5;125m \n [INIT]... CORRECT BRAIN MASK: EDIT MASK TO FS \n\033[0m";

#--------------------------- Iterate over every subject1 -----------------------#
mkdir $DIR/mri/brain_mask_template/
mkdir $DIR/mri/ET2L/
mkdir $DIR/mri/fix_wm/

DIR=$SUBJECTS_DIR/$SUB_ID
DIRm=$SUBJECTS_DIR/$SUB_ID/mri
DIR_bm=$SUBJECTS_DIR/$SUB_ID/mri/brain_mask_template
path_job=$PREEMACS_DIR/$SUB_ID
ETOOL=$DIR/mri/ET2L/
fix_wm=$DIR/mri/fix_wm

#--------------------------- Brain Mask process
mri_convert $DIR/mri/T1.mgz $DIR_bm/T1.nii.gz
original_image=$path_job/T1.nii.gz
mask_native_space=$path_job/brain_mask.nii.gz

fslmaths $path_job/brain_mask.nii.gz -fmean $path_job/brain_mask.nii.gz

cd $DIR_bm
echo "CHANGING CURRENT DIRECTORY TO $DIR_bm"
echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');fake_space('$DIR_bm/','T1',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake','T1');exit()" > $DIR_bm/info.m
 /home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $DIR_bm/info.m


flirt -ref $DIR_bm/T1_no_fake.nii.gz  -in $original_image  -out $DIR_bm/ATLAS_TO_T1.nii.gz -dof 12 -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -omat $DIR_bm/ATLAS_TO_T1.mat
flirt -ref $DIR_bm/ATLAS_TO_T1.nii.gz -in $mask_native_space -applyxfm -init $DIR_bm/ATLAS_TO_T1.mat -out $DIR_bm/MASK_ATLAS_TO_T1.nii.gz

cd $DIR_bm/
echo "CHANGING CURRENT DIRECTORY TO $DIR_bm/"
echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');fake_space('$DIR_bm/','T1',[1;1;1;1;0;0;0;0],'_fake','MASK_ATLAS_TO_T1');exit()" > $DIR_bm/info.m
 /home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $DIR_bm/info.m

mv $DIRm/brainmask.auto.mgz $DIRm/brainmask_original.auto.mgz
mv $DIRm/brainmask.mgz $DIRm/brainmask_original.mgz

fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $DIR_bm/T1.nii.gz $DIR_bm/brainmask_fix.nii.gz

mri_mask $DIR_bm/brainmask_fix.nii.gz $DIR_bm/T1.nii.gz $DIRm/brainmask.auto.mgz
mri_add_xform_to_header -c $SUBJECTS_DIR/$SUB_ID/transforms/talairach.xfm $DIRm/brainmask.auto.mgz $DIRm/brainmask.auto.mgz
cp $DIRm/brainmask.auto.mgz $DIRm/brainmask.mgz
# #----------------------------------------------------------------------- Register to FS Atlas

mri_em_register -rusage $DIR/touch/rusage.mri_em_register.dat -uns 3 -mask $DIRm/brainmask.mgz $DIRm/nu.mgz $FS_PREEMACS_PATH/average/RB_all_2016-05-10.vc700.gca $DIRm/transforms/talairach.lta
mri_ca_normalize -c $DIRm/ctrl_pts.mgz -mask $DIRm/brainmask.mgz $DIRm/nu.mgz $FS_PREEMACS_PATH//average/RB_all_2016-05-10.vc700.gca $DIRm/transforms/talairach.lta $DIRm/norm.mgz
mri_ca_register -rusage $DIR/touch/rusage.mri_ca_register.dat -nobigventricles -T $DIRm/transforms/talairach.lta -align-after -mask $DIRm/brainmask.mgz $DIRm/norm.mgz $FS_PREEMACS_PATH//average/RB_all_2016-05-10.vc700.gca $DIRm/transforms/talairach.m3z
mri_ca_label -relabel_unlikely 9 .3 -prior 0.5 -align $DIRm/norm.mgz $DIRm/transforms/talairach.m3z $FS_PREEMACS_PATH/average/RB_all_2016-05-10.vc700.gca $DIRm/aseg.auto_noCCseg.mgz
mri_cc -aseg aseg.auto_noCCseg.mgz -o aseg.auto.mgz -lta $DIR/mri/transforms/cc_up.lta $SUB_ID
cp $DIRm/aseg.auto.mgz $DIRm/aseg.presurf.mgz
mri_normalize -mprage -aseg $DIRm/aseg.presurf.mgz -mask $DIRm/brainmask.mgz $DIRm/norm.mgz $DIRm/brain.mgz
mri_mask -T 5 $DIRm/brain.mgz $DIRm/brainmask.mgz $DIRm/brain.finalsurfs.mgz

#------------------------------------------------------------------------ NMT registration
fslmaths $path_job/T1.nii.gz -mul $path_job/brain_mask.nii.gz $path_job/brain.nii.gz
mkdir $path_job/NMT_reg
NMT_REG=$path_job/NMT_reg
antsRegistrationSyN.sh -d 3 -f $path_job/brain.nii.gz -m  $PREEMACS_PATH/Templates/NMT_brain.nii.gz -o $NMT_REG/NMT_to_T1_
ConvertTransformFile 3 $NMT_REG/NMT_to_T1_0GenericAffine.mat $NMT_REG/NMT_to_T1_0GenericAffine.txt
#------------------------------------------------------------------------ WM fix
#1. Get FS labels from NMT
#2. Filling subcortical structures
#3. High instensity Control Point (HICPO)

#-------------  1.Get FS labels from NMT
reference_image=$path_job/brain.nii.gz
fs_atlas=$PREEMACS_PATH/Templates/labes_fs_con_thalamus.nii.gz
image_1Warp=$NMT_REG/NMT_to_T1_1Warp.nii.gz
txt_from_registration=$NMT_REG/NMT_to_T1_0GenericAffine.txt

WarpImageMultiTransform 3 $fs_atlas $fix_wm/fs_atlas.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
# get the transforms for fs atlas
fslmaths $DIR_bm/MASK_ATLAS_TO_T1.nii.gz -mul $DIR_bm/T1_no_fake.nii.gz $DIR_bm/brain_no_fake.nii.gz
flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $reference_image -out $fix_wm/brain_for_fix_fs.nii.gz -dof 12 -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -omat $fix_wm/brain_for_fix_fs.mat -interp nearestneighbour
flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $fix_wm/fs_atlas.nii.gz -applyxfm -init $fix_wm/brain_for_fix_fs.mat -out $fix_wm/brain_for_fix_fs_space.nii.gz -interp nearestneighbour

cd $fix_wm
echo "CHANGING CURRENT DIRECTORY TO $fix_wm"

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');fake_space('$fix_wm/','T1',[1;1;1;1;0;0;0;0],'_fake','brain_for_fix_fs_space');exit()" > $fix_wm/info.m
 /home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $fix_wm/info.m

mv $DIRm/aseg.auto.mgz  $DIRm/aseg.presurf_orig.mgz
mv $DIRm/aseg.presurf.mgz $DIRm/aseg.presurf_orig.mgz


mri_convert $fix_wm/brain_for_fix_fs_space_fake.nii.gz $DIRm/aseg.presurf.mgz
mri_convert $fix_wm/brain_for_fix_fs_space_fake.nii.gz $DIRm/aseg.presurf.mgz
mri_convert $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz $DIR_bm/MASK_ATLAS_TO_T1_fake.mgz
mri_convert $DIR_bm/MASK_ATLAS_TO_T1_fake.mgz  $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz

# #fix mask
mri_convert $DIRm/norm.mgz $DIRm/norm.nii.gz
mri_convert $DIRm/brain.mgz $DIRm/brain.nii.gz
fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $DIRm/brain.nii.gz $DIRm/brain.nii.gz
fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $DIRm/norm.nii.gz  $DIRm/norm.nii.gz
mri_convert $DIRm/norm.nii.gz $DIRm/norm.mgz
mri_convert $DIRm/brain.nii.gz $DIRm/brain.mgz
cp $DIRm/brain.mgz $DIRm/brain.finalsurfs.mgz
# #######
mri_segment -mprage $DIRm/brain.mgz $DIRm/wm.seg.mgz
mri_edit_wm_with_aseg -keep-in $DIRm/wm.seg.mgz $DIRm/brain.mgz $DIRm/aseg.presurf.mgz $DIRm/wm.asegedit.mgz
mri_pretess $DIRm/wm.asegedit.mgz wm $DIRm/norm.mgz $DIRm/wm.mgz
mri_fill -a $DIR/scripts/ponscc.cut.log -xform $DIRm/transforms/talairach.lta -segmentation $DIRm/aseg.auto_noCCseg.mgz $DIRm/wm.mgz $DIRm/filled.mgz

##-----------------------------------Filling subcortical structures
mask_for_bg=$PREEMACS_PATH/TEMPLATES/NMT_reg_FS_space_and_labels/gb_mod.nii.gz
claustro_mask=$PREEMACS_PATH/TEMPLATES/claustros.nii.gz

#---------------- Process

WarpImageMultiTransform 3 $mask_for_bg $fix_wm/bg_ventricules.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
WarpImageMultiTransform 3 $claustro_mask $fix_wm/claustro.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
fslmaths $fix_wm/claustro.nii.gz -mul 30 $fix_wm/claustro.nii.gz
fslmaths $fix_wm/claustro.nii.gz -fmean $fix_wm/claustro.nii.gz

fslmaths $DIR_bm/MASK_ATLAS_TO_T1.nii.gz -mul $DIR_bm/T1_no_fake.nii.gz $DIR_bm/brain_no_fake.nii.gz

fslmaths $fix_wm/bg_ventricules.nii.gz -dilM $fix_wm/bg_ventricules.nii.gz
fslmaths $fix_wm/bg_ventricules.nii.gz -fmean $fix_wm/bg_ventricules_smooth.nii.gz
fslmaths $fix_wm/bg_ventricules.nii.gz -binv  $fix_wm/bg_ventricules_binv.nii.gz
fslmaths $fix_wm/bg_ventricules_binv.nii.gz -fmean $fix_wm/bg_ventricules_binv_smooth.nii.gz
fslmaths $fix_wm/bg_ventricules_smooth.nii.gz -mul 110 $fix_wm/bg_ventricules_smooth_mul.nii.gz

flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $reference_image -out $fix_wm/brain_for_fix_gb.nii.gz -dof 12 -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -omat $fix_wm/brain_for_fix_gb.mat

flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $fix_wm/bg_ventricules_smooth_mul.nii.gz -applyxfm -init $fix_wm/brain_for_fix_gb.mat -out $fix_wm/bg_ventricules_smooth_mul_fs_space.nii.gz
flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $fix_wm/bg_ventricules_binv_smooth.nii.gz -applyxfm -init $fix_wm/brain_for_fix_gb.mat -out $fix_wm/bg_ventricules_smooth_binv_fs_space.nii.gz
flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $fix_wm/claustro.nii.gz -applyxfm -init $fix_wm/brain_for_fix_gb.mat -out $fix_wm/claustro.nii.gz -interp nearestneighbour


cd $fix_wm
echo "CHANGING CURRENT DIRECTORY TO $fix_wm"

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');fake_space('$fix_wm/','T1',[1;1;1;1;0;0;0;0],'_fake','bg_ventricules_smooth_mul_fs_space');exit()" > $fix_wm/info.m
 /home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $fix_wm/info.m


cd $fix_wm
echo "CHANGING CURRENT DIRECTORY TO $fix_wm"
echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');fake_space('$fix_wm/','T1',[1;1;1;1;0;0;0;0],'_fake','bg_ventricules_smooth_binv_fs_space');exit()" > $fix_wm/info.m
 /home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $fix_wm/info.m

cd $fix_wm
echo "CHANGING CURRENT DIRECTORY TO $fix_wm"
echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');fake_space('$fix_wm/','T1',[1;1;1;1;0;0;0;0],'_fake','claustro');exit()" > $fix_wm/info.m
 /home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $fix_wm/info.m


mv $DIRm/brain.mgz $DIRm/brain_ori.mgz
mv $DIRm/norm.mgz $DIRm/norm_orig.mgz
mri_convert $DIRm/brain_ori.mgz $DIRm/brain_ori.nii.gz
mri_convert $fix_wm/bg_ventricules_smooth_mul_fs_space_fake.nii.gz $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz
mri_convert $fix_wm/bg_ventricules_smooth_binv_fs_space_fake.nii.gz $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz
mri_convert $fix_wm/claustro_fake.nii.gz $fix_wm/claustro_fake_fs.nii.gz
mri_convert $DIRm/norm_orig.mgz $DIRm/norm_orig.nii.gz

#apply_brain
fslmaths $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz -mul $DIRm/brain_ori.nii.gz $fix_wm/bg_ventricules_fs_no_bg.nii.gz
fslmaths $fix_wm/bg_ventricules_fs_no_bg.nii.gz -add $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz $fix_wm/fix_wm_fs_space.nii.gz

#apply norm
fslmaths $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz -mul $DIRm/norm_orig.nii.gz $fix_wm/bg_ventricules_fs_no_bg_norm.nii.gz
fslmaths $fix_wm/bg_ventricules_fs_no_bg_norm.nii.gz -add $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz $fix_wm/fix_wm_fs_space_norm.nii.gz

mri_convert $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz $DIR_bm/MASK_ATLAS_TO_T1_fake.mgz
mri_convert $DIR_bm/MASK_ATLAS_TO_T1_fake.mgz  $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz

#fix mask
fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $fix_wm/fix_wm_fs_space.nii.gz $DIRm/brain.nii.gz
fslmaths $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz -mul $fix_wm/fix_wm_fs_space_norm.nii.gz $DIRm/norm.nii.gz

## add claustros
fslmaths $DIRm/brain.nii.gz -add  $fix_wm/claustro_fake_fs.nii.gz $DIRm/brain.nii.gz
fslmaths $DIRm/norm.nii.gz -add  $fix_wm/claustro_fake_fs.nii.gz $DIRm/norm.nii.gz

mri_convert $DIRm/brainmask.mgz $DIRm/brainmask.nii.gz
fslmaths $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz -mul $DIRm/brainmask.nii.gz $DIRm/brainmask_1.nii.gz
fslmaths $DIRm/brainmask_1.nii.gz -add $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz $DIRm/brainmask_2.nii.gz
mri_convert $DIRm/brainmask_2.nii.gz $DIRm/brainmask.mgz
mri_add_xform_to_header -c $DIRm/transforms/talairach.xfm $DIRm/brainmask.mgz $DIRm/brainmask.mgz
cp $DIRm/brainmask.mgz $DIRm/brainmask.auto.mgz

mri_convert $DIRm/nu.mgz $DIRm/nu.nii.gz
fslmaths $fix_wm/bg_ventricules_smooth_binv_fs_space_fake_fs.nii.gz -mul $DIRm/nu.nii.gz $DIRm/nu_1.nii.gz
fslmaths $DIRm/nu_1.nii.gz -add $fix_wm/bg_ventricules_smooth_mul_fs_space_fake_fs.nii.gz $DIRm/nu_2.nii.gz
mri_convert $DIRm/nu_2.nii.gz $DIRm/nu.mgz
mri_add_xform_to_header -c $DIRm/transforms/talairach.xfm $DIRm/nu.mgz $DIRm/nu.mgz

mri_convert $DIRm/brain.nii.gz $DIRm/brain.mgz
mri_convert $DIRm/norm.nii.gz $DIRm/norm.mgz
cp $DIRm/brain.mgz $DIRm/brain.finalsurfs.mgz
#----------------------------------------------------HICPO
Template_image=$PREEMACS_PATH/TEMPLATES/NMT_brain.nii.gz
High_Intensity_ROI=$PREEMACS_PATH/TEMPLATES/ROI_pg_visual_c.nii.gz
#---------------- Timer & Beginning ----------------#
echo -e "\033[48;5;125m \n [INIT]...HIGH INTENSITY CONTROL POINT IN GM \n\033[0m";

#---------------------------------------------------#
DIRs=$SUBJECTS_DIR/$SUB_ID/surf
cp -r $DIRs $DIR/surf_original
cp -r $DIRm $DIR/mri_original
#rm $DIRs/*

rm -r $DIR/mri/HICPO/
mkdir $DIR/mri/HICPO/
HICPO=$DIR/mri/HICPO

cd $DIRm
####################################### FIx wm with norm
cp $DIRm/brain.mgz $DIRm/brain_orig_after_MACS.mgz
cp $DIRm/norm.mgz $DIRm/brain.mgz

mri_segment -mprage -wlo 105 -ghi 100 $DIR/mri/brain.mgz  $HICPO/wm.seg_MOD.mgz #LONG

mri_convert $DIR/mri/T1.mgz $HICPO/T1.nii.gz
mri_convert $DIR/mri/wm.seg.mgz $HICPO/wm.seg.nii.gz
mri_convert $HICPO/wm.seg_MOD.mgz $HICPO/wm.seg_MOD.nii.gz
mri_convert $DIR/mri/brain.mgz $HICPO/brain.nii.gz

cd $HICPO
echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');convert('$HICPO/',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake');exit()" > $HICPO/info.m
$octave_path -r -nodisplay -nojvm info
rm $HICPO/info.m

WarpImageMultiTransform 3 $High_Intensity_ROI $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -applyxfm -init $fix_wm/brain_for_fix_fs.mat -out $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -interp nearestneighbour


fslmaths $HICPO/wm.seg_MOD.nii.gz -binv $HICPO/wm.seg_MOD_binv.nii.gz
fslmaths $HICPO/wm.seg_MOD_binv.nii.gz -mul $HICPO/wm.seg.nii.gz $HICPO/bump.nii.gz
fslmaths $HICPO/bump.nii.gz -mul $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz $HICPO/bump_error.nii.gz
fslmaths $HICPO/bump_error.nii.gz -sub 80 $HICPO/resta.nii.gz
fslmaths $HICPO/resta.nii.gz -bin $HICPO/resta_bin.nii.gz
fslmaths $HICPO/resta_bin.nii.gz -mul $HICPO/resta.nii.gz $HICPO/low_values.nii.gz
fslmaths $HICPO/low_values.nii.gz -bin $HICPO/low_values_bin.nii.gz

#############SMOOTH##############
fslmaths $HICPO/low_values_bin.nii.gz -kernel box 3x3x3 -fmean $HICPO/low_values_bin_smooth.nii.gz

##########Changes values#########

fslmaths $HICPO/low_values_bin_smooth.nii.gz -mul -20 $HICPO/low_values_normalize.nii.gz
fslmaths $HICPO/low_values_normalize.nii.gz -add $HICPO/brain.nii.gz $HICPO/brain_normalize_HI.nii.gz

cp $DIR/mri/brain.mgz $DIR/mri/brain_original.mgz
mri_convert $HICPO/brain_normalize_HI.nii.gz $DIR/mri/brain.mgz
#########################################################################FIX WM with brain normalize previosly fix norm ###########################################################
mv $DIR/mri/brain.mgz $DIR/mri/norm.mgz
mri_normalize -mprage -aseg $DIRm/aseg.presurf_orig.mgz -mask $DIRm/brainmask.mgz $DIRm/norm.mgz $DIRm/brain.mgz

##################Segmentacion WM #####################################

mri_mask -T 5 $DIRm/brain.mgz $DIRm/brainmask.mgz $DIRm/brain.finalsurfs.mgz
mri_segment -mprage $DIRm/brain.mgz $DIRm/wm.seg.mgz

################## CLEAN WM.SEG.MZ ###################################
mri_segment -mprage -wlo 100 -ghi 110 $DIR/mri/brain.mgz  $HICPO/wm.seg_MOD.mgz #FOR CROSS
mri_convert $DIR/mri/T1.mgz $HICPO/T1.nii.gz
mri_convert $DIR/mri/wm.seg.mgz $HICPO/wm.seg.nii.gz
mri_convert $HICPO/wm.seg_MOD.mgz $HICPO/wm.seg_MOD.nii.gz

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');convert('$HICPO/',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake');exit()" > $HICPO/info.m

#LAST_DIR=pwd
cd $HICPO
echo "CHANGING CURRENT DIRECTORY TO $HICPO"

$octave_path -r -nodisplay -nojvm info
rm $HICPO/info.m

#cd $LAST_DIR
#echo "CHANGING CURRENT DIRECTORY TO $LAST_DIR"

## sumando la sustancia blanca que puede irse por cambios de umbral para segmentacion gm/wm
WarpImageMultiTransform 3 $High_Intensity_ROI $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN
flirt -ref $DIR_bm/brain_no_fake.nii.gz  -in $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -applyxfm -init $fix_wm/brain_for_fix_fs.mat -out $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -interp nearestneighbour

fslmaths $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -binv $HICPO/MASK_WM.SEG_MOD_FOR_CROP.nii.gz
fslmaths $HICPO/MASK_WM.SEG_MOD_FOR_CROP.nii.gz -mul $HICPO/wm.seg_no_fake.nii.gz $HICPO/1.nii.gz
fslmaths $HICPO/MASK_WM.SEG_FOR_CROP.nii.gz -mul $HICPO/wm.seg_MOD_no_fake.nii.gz $HICPO/2.nii.gz
fslmaths $HICPO/1.nii.gz -add $HICPO/2.nii.gz $HICPO/wm.seg_final_no_fake.nii.gz -odt char

cd $HICPO
echo "CHANGING CURRENT DIRECTORY TO $HICPO"

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts/');convert_wm_ed_fake('$HICPO/');exit()" > $HICPO/info.m
$octave_path -r -nodisplay -nojvm info
rm $HICPO/info.m

#cd $LAST_DIR
#echo "CHANGING CURRENT DIRECTORY TO $LAST_DIR"
mv $DIRm/wm.seg.mgz $DIRm/wm.seg_original.mgz
mv $DIRm/wm.mgz $DIRm/wm_ORIGINAL.mgz

mri_convert $HICPO/wm.seg_final_fake.nii.gz $DIRm/wm.seg.mgz --out_data_type uchar

########################################################################################
mri_edit_wm_with_aseg -keep-in $DIRm/wm.seg.mgz $DIRm/brain.mgz $DIRm/aseg.presurf.mgz $DIRm/wm.asegedit.mgz

mri_pretess $DIRm/wm.asegedit.mgz wm $DIRm/norm.mgz $DIRm/wm.mgz

#--------------------------------------------
#@# Fill

mri_fill -a $DIR/scripts/ponscc.cut.log -xform $DIRm/transforms/talairach.lta -segmentation $DIRm/aseg.auto_noCCseg.mgz $DIRm/wm.mgz $DIRm/filled.mgz

#--------------------------------------------
#@# Tessellate lh

 mri_pretess $DIRm/filled.mgz 255 $DIR/mri/norm.mgz $DIR/mri/filled-pretess255.mgz

 mri_tessellate $DIRm/filled-pretess255.mgz 255 $DIR/surf/lh.orig.nofix


 rm -f $DIRm/filled-pretess255.mgz


 mris_extract_main_component $DIR/surf/lh.orig.nofix $DIR/surf/lh.orig.nofix

#--------------------------------------------
#@# Tessellate rh

 mri_pretess $DIRm/filled.mgz 127 $DIRm/norm.mgz $DIRm/filled-pretess127.mgz


 mri_tessellate $DIRm/filled-pretess127.mgz 127 $DIR/surf/rh.orig.nofix


 rm -f $DIRm/filled-pretess127.mgz


 mris_extract_main_component $DIR/surf/rh.orig.nofix $DIR/surf/rh.orig.nofix

#--------------------------------------------
#@# Smooth1 lh

 mris_smooth -nw -seed 1234 $DIR/surf/lh.orig.nofix $DIR/surf/lh.smoothwm.nofix

#--------------------------------------------
#@# Smooth1 rh

 mris_smooth -nw -seed 1234 $DIR/surf/rh.orig.nofix $DIR/surf/rh.smoothwm.nofix

#--------------------------------------------
#@# Inflation1 lh

 mris_inflate -no-save-sulc $DIR/surf/lh.smoothwm.nofix $DIR/surf/lh.inflated.nofix

#--------------------------------------------
#@# Inflation1 rh

 mris_inflate -no-save-sulc $DIR/surf/rh.smoothwm.nofix $DIR/surf/rh.inflated.nofix

#--------------------------------------------
#@# QSphere lh

 mris_sphere -q -seed 1234 $DIR/surf/lh.inflated.nofix $DIR/surf/lh.qsphere.nofix

#--------------------------------------------
#@# QSphere rh

 mris_sphere -q -seed 1234 $DIR/surf/rh.inflated.nofix $DIR/surf/rh.qsphere.nofix

#--------------------------------------------
#@# Fix Topology Copy lh

 cp $DIR/surf/lh.orig.nofix $DIR/surf/lh.orig


 cp $DIR/surf/lh.inflated.nofix $DIR/surf/lh.inflated

#--------------------------------------------
#@# Fix Topology Copy rh

 cp $DIR/surf/rh.orig.nofix $DIR/surf/rh.orig


 cp $DIR/surf/rh.inflated.nofix $DIR/surf/rh.inflated

#@# Fix Topology lh

 mris_fix_topology -rusage $DIR/touch/rusage.mris_fix_topology.lh.dat -mgz -sphere qsphere.nofix -ga -seed 1234 $SUB_ID lh

#@# Fix Topology rh

 mris_fix_topology -rusage $DIR/touch/rusage.mris_fix_topology.rh.dat -mgz -sphere qsphere.nofix -ga -seed 1234 $SUB_ID rh


 mris_euler_number $DIR/surf/lh.orig


 mris_euler_number $DIR/surf/rh.orig


 mris_remove_intersection $DIR/surf/lh.orig $DIR/surf/lh.orig


 rm $DIR/surf/lh.inflated


 mris_remove_intersection $DIR/surf/rh.orig $DIR/surf/rh.orig


 rm $DIR/surf/rh.inflated

#--------------------------------------------
#@# Make White Surf lh

 mris_make_surfaces -aseg aseg.presurf -white white.preaparc -noaparc -whiteonly -mgz -T1 brain.finalsurfs $SUB_ID lh

#--------------------------------------------
#@# Make White Surf rh

 mris_make_surfaces -aseg aseg.presurf -white white.preaparc -noaparc -whiteonly -mgz -T1 brain.finalsurfs $SUB_ID rh


###########################################################

#@# Smooth2 lh
mris_smooth -n 3 -nw -seed 1234 $DIR/surf/lh.white.preaparc $DIR/surf/lh.smoothwm

#--------------------------------------------
#@# Smooth2 rh
mris_smooth -n 3 -nw -seed 1234 $DIR/surf/rh.white.preaparc $DIR/surf/rh.smoothwm

#--------------------------------------------
#@# Inflation2 lh
mris_inflate -rusage $DIR/touch/rusage.mris_inflate.lh.dat $DIR/surf/lh.smoothwm $DIR/surf/lh.inflated

#--------------------------------------------
#@# Inflation2 rh
mris_inflate -rusage $DIR/touch/rusage.mris_inflate.rh.dat $DIR/surf/rh.smoothwm $DIR/surf/rh.inflated

#--------------------------------------------
#@# Curv .H and .K lh
mris_curvature -w $DIR/surf/lh.white.preaparc
rm -f $DIR/surf/lh.white.H
ln -s $DIR/surf/lh.white.preaparc.H lh.white.H
rm -f $DIR/surf/lh.white.K
ln -s $DIR/surf/lh.white.preaparc.K lh.white.K
mris_curvature -thresh .999 -n -a 5 -w -distances 10 10 $DIR/surf/lh.inflated

#--------------------------------------------
#@# Curv .H and .K rh

mris_curvature -w $DIR/surf/rh.white.preaparc
rm -f $DIR/surf/rh.white.H
ln -s $DIR/surf/rh.white.preaparc.H rh.white.H
rm -f $DIR/surf/rh.white.K
ln -s $DIR/surf/rh.white.preaparc.K rh.white.K
mris_curvature -thresh .999 -n -a 5 -w -distances 10 10 $DIR/surf/rh.inflated
#-----------------------------------------
#@# Curvature Stats lh

mris_curvature_stats -m --writeCurvatureFiles -G -o $DIR/stats/lh.curv.stats -F smoothwm $SUB_ID lh curv sulc
#-----------------------------------------
#@# Curvature Stats rh
mris_curvature_stats -m --writeCurvatureFiles -G -o $DIR/stats/rh.curv.stats -F smoothwm $SUB_ID rh curv sulc

#----------------------------------------------- ET2L ---------------------------------------------------
echo -e "\033[48;5;125m \n [INIT]...ET2L \n\033[0m";

Mean_Wall=$PREEMACS_PATH/TEMPLATES/meadn_wall_NMT.nii.gz
HIPO_MASK=$PREEMACS_PATH/TEMPLATES/hipos_amigdalas.nii.gz

##./ET2.sh $SUBJECTS_DIR $SUB_ID $Mean_Wall $HIPO_MASK $reference_image $image_1Warp $txt_from_registration
--------------------------- Iterate over every subject -----------------------#
cp -r $DIRs $DIR/surf_PRE_ET2L
cp -r $DIRm $DIR/mri_PRE_ET2L

####################### SURFACE REGISTRATION ###########################
mris_sphere -rusage $DIR/touch/rusage.mris_sphere.lh.dat -seed 1234 $DIRs/lh.inflated $DIRs/lh.sphere
mris_sphere -rusage $DIR/touch/rusage.mris_sphere.rh.dat -seed 1234 $DIRs/rh.inflated $DIRs/rh.sphere

mris_register -curv -rusage $DIR/touch/rusage.mris_register.lh.dat $DIRs/lh.sphere $FS_PREEMACS_PATH/lh.PREEMACS_34_v1.tif $DIRs/lh.sphere.reg

mris_register -curv -rusage $DIR/touch/rusage.mris_register.rh.dat $DIRs/rh.sphere $FS_PREEMACS_PATH/rh.PREEMACS_34_v1.tif $DIRs/rh.sphere.reg


mris_jacobian $DIRs/lh.white.preaparc $DIRs/lh.sphere.reg $DIRs/lh.jacobian_white

mris_jacobian $DIRs/rh.white.preaparc $DIRs/rh.sphere.reg $DIRs/rh.jacobian_white

mrisp_paint -a 5 $FS_PREEMACS_PATH/lh.PREEMACS_34_v1.tif#6 $DIRs/lh.sphere.reg $DIRs/lh.avg_curv

mrisp_paint -a 5 $FS_PREEMACS_PATH/rh.PREEMACS_34_v1.tif#6 $DIRs/rh.sphere.reg $DIRs/rh.avg_curv


mris_ca_label -l $DIR/label/lh.cortex.label -aseg $DIR/mri/aseg.presurf.mgz -seed 1234 $SUB_ID lh $DIRs/lh.sphere.reg $FS_PREEMACS_PATH/average/lh.DKaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs $DIR/label/lh.aparc.annot
mris_ca_label -l $DIR/label/rh.cortex.label -aseg $DIR/mri/aseg.presurf.mgz -seed 1234 $SUB_ID rh $DIRs/rh.sphere.reg $FS_PREEMACS_PATH/average/lh.DKaparc.atlas.acfb40.noaparc.i12.2016-08-02.gcs $DIR/label/rh.aparc.annot

#--------------------------------------------
#@# Make Pial Surf lh
mri_convert $DIRm/brain.finalsurfs.mgz $ETOOL/brain.finalsurfs.nii.gz

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts/');convertseq('$ETOOL','T1',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake','brain.finalsurfs');exit()" > $ETOOL/info.m

cd $ETOOL
echo "CHANGING CURRENT DIRECTORY TO $ETOOL"
$octave_path -r -nodisplay -nojvm info
rm $ETOOL/info.m

#-------------  1.Get FS labels from NMT
reference_image=$path_job/brain.nii.gz
image_1Warp_05=$NMT_REG/NMT_to_T1_05_1Warp.nii.gz
txt_from_registration_05=$NMT_REG/NMT_to_T1_05_0GenericAffine.txt

mris_make_surfaces -orig_white white.preaparc -orig_pial white.preaparc -max 10 -aseg aseg.presurf -mgz -T1 brain.finalsurfs $SUB_ID lh

mris_make_surfaces -orig_white white.preaparc -orig_pial white.preaparc -max 10 -aseg aseg.presurf -mgz -T1 brain.finalsurfs $SUB_ID rh
mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID

mri_convert  $DIRm/lh.ribbon.mgz $DIRm/lh.ribbon.nii.gz
mri_convert  $DIRm/rh.ribbon.mgz $DIRm/rh.ribbon.nii.gz

fslmaths $DIRm/lh.ribbon.nii.gz -add $DIRm/rh.ribbon.nii.gz $DIRm/ribbon_cross.nii.gz
mrcalc $DIRm/ribbon_cross.nii.gz 2 -eq $DIRm/cross_T1.nii.gz -force
fslmaths $DIRm/cross_T1.nii.gz -binv $DIRm/cross_T1_binv.nii.gz
fslmaths $DIRm/cross_T1_binv.nii.gz -mul $ETOOL/brain.finalsurfs_no_fake.nii.gz $ETOOL/brain.finalsurfs_no_fake_no_T2_cross.nii.gz

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');convertseq('$ETOOL','T1',[1;1;1;1;0;0;0;0],'_fake','brain.finalsurfs_no_fake_no_T2_cross');exit()" > $ETOOL/info.m

cd $ETOOL
echo "CHANGING CURRENT DIRECTORY TO $ETOOL"
$octave_path -r -nodisplay -nojvm info
rm $ETOOL/info.m
fslmaths  $ETOOL/brain.finalsurfs_no_fake_no_T2_cross_fake.nii.gz -mul $DIR_bm/MASK_ATLAS_TO_T1_fake.nii.gz $ETOOL/brain.finalsurfs_no_fake_no_T2_cross_fake.nii.gz

mri_convert $ETOOL/brain.finalsurfs_no_fake_no_T2_cross_fake.nii.gz $DIRm/brain.finalsurfs.mgz

###########################################################################
mris_make_surfaces -orig_white white.preaparc -orig_pial white.preaparc -max 10 -aseg aseg.presurf -mgz -T1 brain.finalsurfs $SUB_ID lh

mris_make_surfaces -orig_white white.preaparc -orig_pial white.preaparc -max 10 -aseg aseg.presurf -mgz -T1 brain.finalsurfs $SUB_ID rh
mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID

# #########################################################################
mri_convert $DIR/mri/orig/T2raw.mgz  $DIR/mri/orig/T2raw.nii.gz
ImageMath 3 $DIR/mri/orig/T2raw.nii.gz TruncateImageIntensity $DIR/mri/orig/T2raw.nii.gz
#  ######################## SURFACE REGISTRATION ###########################

# ########################## PREPARE RIBBON  ##################################
cp $DIR/mri/ribbon.mgz  $ETOOL/ribbon_original.mgz
cp $DIR/mri/ribbon.mgz  $DIR/mri/ribbon_firt.mgz
mv $DIR/mri/ribbon.mgz  $ETOOL/ribbon_sin_T2.mgz
###############################################################################

cd $DIRm
# #
# # # ##################### T2 PIAL SURFACE WITH KISS ERROR ###################

cp $DIR/mri/orig/T2raw.mgz $DIR/mri/orig/T2raw.mgz #NO_TEMPLATE
mri_convert $DIR/mri/orig/T2raw.mgz $DIR/mri/orig/T2raw.nii.gz
mincnlm_nii.sh $DIR/mri/orig/T2raw.nii.gz  $DIR/mri/orig/T2raw_deno.nii.gz
mri_convert $DIR/mri/orig/T2raw_deno.nii.gz $DIR/mri/orig/T2raw.mgz
rm $DIR/mri/orig/T2raw_deno.nii.gz
rm $DIR/mri/orig/T2raw.nii.gz

bbregister --s $SUB_ID --mov $DIR/mri/orig/T2raw.mgz --lta $DIR/mri/transforms/T2raw.auto.lta --init-coreg --T2

cp $DIR/mri/transforms/T2raw.auto.lta $DIR/mri/transforms/T2raw.lta

mri_convert -odt float -at $DIR/mri/transforms/T2raw.lta -rl $DIR/mri/orig.mgz $DIR/mri/orig/T2raw.mgz $DIR/mri/T2.prenorm.mgz

mri_normalize -sigma 0.5 -nonmax_suppress 0 -min_dist 1 -aseg $DIR/mri/aseg.presurf_orig.mgz -surface $DIR/surf/rh.white identity.nofile -surface $DIR/surf/lh.white identity.nofile $DIR/mri/T2.prenorm.mgz $DIR/mri/T2.norm.mgz

mri_mask $DIR/mri/T2.norm.mgz $DIR/mri/brainmask.mgz $DIR/mri/T2.mgz

cp -v $DIR/surf/lh.pial $DIR/surf/lh.woT2.pial
cp -v $DIR/surf/lh.pial $DIR/surf/lh.orig.pial

mris_make_surfaces -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 2 -nsigma_below 5 $SUB_ID lh

# # #mris_make_surfaces -max 7.5 -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2  -max 10 -nsigma_above 3 -nsigma_below 5 $SUB_ID lh

cp -v $DIR/surf/rh.pial $DIR/surf/rh.woT2.pial
cp -v $DIR/surf/rh.pial $DIR/surf/rh.orig.pial

mris_make_surfaces -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 2 -nsigma_below 5 $SUB_ID rh

# # #mris_make_surfaces -max 7.5 -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 3 -nsigma_below 5 $SUB_ID rh
# # ######################## Cortical ribbon mask  ########################

#mris_volmask --label_left_white 10 --label_left_ribbon 15 --label_right_white 20 --label_right_ribbon 25 --save_ribbon $SUB_ID
mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID
# # # ######################## FIX T2 PIAL SURFACE KISS ####################
mv $DIR/mri/ribbon.mgz $ETOOL/ribbon_kiss.mgz

mri_convert $DIR/mri/T1.mgz          $ETOOL/T1.nii.gz
mri_convert $DIR/mri/T2.prenorm.mgz  $ETOOL/T2.prenorm.nii.gz
mri_convert $ETOOL/ribbon_kiss.mgz   $ETOOL/ribbon_kiss.nii.gz
mri_convert $ETOOL/ribbon_sin_T2.mgz $ETOOL/ribbon_sin_T2.nii.gz


fslmaths $ETOOL/ribbon_kiss.nii.gz -add $ETOOL/ribbon_sin_T2.nii.gz $ETOOL/ribbon_sum.nii.gz

mrcalc $ETOOL/ribbon_sum.nii.gz 25  -eq $ETOOL/ribbon_25.nii.gz
mrcalc $ETOOL/ribbon_sum.nii.gz 15 -eq $ETOOL/ribbon_15.nii.gz
fslmaths $ETOOL/ribbon_25.nii.gz -add $ETOOL/ribbon_15.nii.gz $ETOOL/diffence.nii.gz


echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');convertseq('$ETOOL','T1',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake','T1');exit()" > $ETOOL/info.m

cd $ETOOL
echo "CHANGING CURRENT DIRECTORY TO $ETOOL"
$octave_path -r -nodisplay -nojvm info
rm $ETOOL/info.m

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');convertseq('$ETOOL','T2',[1;0.5;0.5;0.5;0;0;0;0],'_no_fake','T2.prenorm');exit()" > $ETOOL/info.m
cd $ETOOL
echo "CHANGING CURRENT DIRECTORY TO $ETOOL"
$octave_path -r -nodisplay -nojvm info
rm $ETOOL/info.m

WarpImageMultiTransform 3 $Mean_Wall $ETOOL/mean_wall_reg.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN

flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $reference_image -dof 6 -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -omat $ETOOL/omat_reg_fs_space.mat -interp nearestneighbour
flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $ETOOL/mean_wall_reg.nii.gz -applyxfm -init $ETOOL/omat_reg_fs_space.mat -out $ETOOL/cross.nii.gz -interp nearestneighbour
fslmaths   $ETOOL/cross.nii.gz -mul $ETOOL/diffence.nii.gz $ETOOL/not_kiss.nii.gz
fslmaths $ETOOL/not_kiss.nii.gz -binv $ETOOL/not_kiss_binv.nii.gz
fslmaths $ETOOL/not_kiss_binv.nii.gz -mul $ETOOL/T2.prenorm_no_fake.nii.gz $ETOOL/T2_pre_pial.nii.gz


# ##################QUIT HIPOS############

WarpImageMultiTransform 3 $HIPO_MASK $ETOOL/Hippos.nii.gz -R $reference_image $image_1Warp $txt_from_registration --use-NN

flirt -ref $DIR_bm/brain_no_fake.nii.gz -in $ETOOL/Hippos.nii.gz -applyxfm -init $ETOOL/omat_reg_fs_space.mat -out $ETOOL/HIPOS_mask.nii.gz -interp nearestneighbour -interp nearestneighbour
#fslmaths $ETOOL/HIPOS_mask.nii.gz -fmean -kernel box 1x1x1 $ETOOL/HIPOS_mask.nii.gz

fslmaths $ETOOL/HIPOS_mask.nii.gz -binv $ETOOL/HIPOS_mask_inverse.nii.gz
fslmaths $ETOOL/T2_pre_pial.nii.gz -mul $ETOOL/HIPOS_mask_inverse.nii.gz $ETOOL/T2_pre_pial.nii.gz

# ########################################

echo "addpath('$PREEMACS_DIR/$SUB_ID/scripts');convertseq('$ETOOL','T2',[1;1;1;1;0;0;0;0],'_fake','T2_pre_pial');exit()" > $ETOOL/info.m

cd $ETOOL
echo "CHANGING CURRENT DIRECTORY TO $ETOOL"
$octave_path -r -nodisplay -nojvm info
rm $ETOOL/info.m

mri_convert $ETOOL/T2_pre_pial_fake.nii.gz $DIR/mri/T2.prenorm.mgz

# #################### SURFACE T2 without kiss #########################

mri_normalize -sigma 0.5 -nonmax_suppress 0 -min_dist 1 -aseg $DIR/mri/aseg.presurf_orig.mgz -surface $DIR/surf/rh.white identity.nofile -surface $DIR/surf/lh.white identity.nofile $DIR/mri/T2.prenorm.mgz $DIR/mri/T2.norm.mgz

mri_mask $DIR/mri/T2.norm.mgz $DIR/mri/brainmask.mgz $DIR/mri/T2.mgz

cp    $DIR/surf/lh.orig.pial $DIR/surf/lh.T1.pial
mv    $DIR/surf/lh.orig.pial $DIR/surf/lh.pial
cp -v $DIR/surf/lh.pial $DIR/surf/lh.woT2.pial

# ####################### FIX T2 PIAL SURFACE KISS 2 ########################
#  ######## Sum_cortical_ribbon_to_T2 only in AMS and cingulate cortex #####

mri_convert $DIR/mri/rh.ribbon.mgz $ETOOL/rh.ribbon.nii.gz #FOR FIX T2 KISS SECOND PART
mri_convert $DIR/mri/lh.ribbon.mgz $ETOOL/lh.ribbon.nii.gz
mri_convert $DIR/mri/T2.mgz  $ETOOL/T2.before.2do.fix.kiss.nii.gz
cp $ETOOL/T2.before.2do.fix.kiss.nii.gz $DIR/mri/T2.before.fix.2ndpart.kiiss.nii.gz
mri_convert $DIR/mri/T2.before.fix.2ndpart.kiiss.nii.gz $DIR/mri/T2.before.fix.2ndpart.kiiss.mgz

#cp $ETOOL/T2.before.2do.fix.kiss.nii.gz $DIR/mri/T2.before.fix.2ndpart.kiiss.mgz

fslmaths $ETOOL/lh.ribbon.nii.gz -binv $ETOOL/lh.ribbon_binv.nii.gz
fslmaths $ETOOL/rh.ribbon.nii.gz -binv $ETOOL/rh.ribbon_binv.nii.gz
#  ############################# lh ####################################

fslmaths $ETOOL/rh.ribbon_binv.nii.gz -mul $ETOOL/T2.before.2do.fix.kiss.nii.gz $ETOOL/T2_wth_rh_hemisphere.nii.gz
mri_convert $ETOOL/T2_wth_rh_hemisphere.nii.gz $DIR/mri/T2.mgz

mris_make_surfaces -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 3 -nsigma_below 5 $SUB_ID lh

#mris_make_surfaces -max 7.5 -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2  -max 10 -nsigma_above 3 -nsigma_below 5 $SUB_ID lh

# ############################# rh ####################################

fslmaths $ETOOL/lh.ribbon_binv.nii.gz -mul $ETOOL/T2.before.2do.fix.kiss.nii.gz $ETOOL/T2_wth_lh_hemisphere.nii.gz
mri_convert $ETOOL/T2_wth_lh_hemisphere.nii.gz $DIR/mri/T2.mgz

cp    $DIR/surf/rh.orig.pial $DIR/surf/rh.T1.pial
mv    $DIR/surf/rh.orig.pial $DIR/surf/rh.pial
cp -v $DIR/surf/rh.pial $DIR/surf/rh.woT2.pial

mris_make_surfaces -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 3 -nsigma_below 5 $SUB_ID rh

#mris_make_surfaces -max 7.5 -orig_white white -orig_pial woT2.pial -aseg aseg.presurf -nowhite -mgz -T1 brain.finalsurfs -T2 $DIR/mri/T2 -max 10 -nsigma_above 3 -nsigma_below 5 $SUB_ID rh


# ######################## Cortical ribbon mask  ########################
mris_volmask --aseg_name aseg.presurf --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID
#mris_volmask --label_left_white 2 --label_left_ribbon 3 --label_right_white 41 --label_right_ribbon 42 --save_ribbon $SUB_ID

mri_vol2surf --mov $DIR/mri/rawavg.mgz --hemi lh --noreshape --interp trilinear --projdist -1 --o $DIR/surf/lh.wm.mgh --regheader $SUB_ID --cortex
mri_vol2surf --mov $DIR/mri/rawavg.mgz --hemi lh --noreshape --interp trilinear --o $DIR/surf/lh.gm.mgh --projfrac 0.3 --regheader $SUB_ID --cortex
mri_concat $DIR/surf/lh.wm.mgh $DIR/surf/lh.gm.mgh --paired-diff-norm --mul 100 --o $DIR/surf/lh.w-g.pct.mgh

mri_vol2surf --mov $DIR/mri/rawavg.mgz --hemi rh --noreshape --interp trilinear --projdist -1 --o $DIR/surf/rh.wm.mgh --regheader $SUB_ID --cortex
mri_vol2surf --mov $DIR/mri/rawavg.mgz --hemi rh --noreshape --interp trilinear --o $DIR/surf/rh.gm.mgh --projfrac 0.3 --regheader $SUB_ID --cortex
mri_concat $DIR/surf/rh.wm.mgh $DIR/surf/rh.gm.mgh --paired-diff-norm --mul 100 --o $DIR/surf/rh.w-g.pct.mgh
########################     Total Time       #########################
lopuu=$(date +%s.%N)
eri=$(echo "$lopuu - $aloita" | bc)
echo -e "\\033[38;5;220m \n TOTAL running time: ${eri} seconds \n \\033[0m"
