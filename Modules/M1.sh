#!/bin/bash

help() {
echo -e "
Usage: `basename $0` -id -t1_path -t2_path -out_path [Options]
	             id:           Subject ID
	        t1_path:           T1_path on .nii.gz format
	        t2_path:           T2_path on .nii.gz format
               out_path:          Output path

Module 1. Volume orientation, image crop, intensity non-uniformity (INU) correction,
          image averaging, resampling and conform.

OPTIONS
-sphinx:                 Reorient to sphinx position
-mc:                     if the automatic crop fails (default) do manual crop.
                         Open fslview to id the coordinates (x y z) of
                         anterior and posterior commisures
-mcc:                    if the automatic crop fails add coordinates (x y z) of
                         anterior and posterior commisure. After perform all module 1
                         you can find the file in out_path/file_to_coords.txt. You must add
                         the coords here and run again using this option.
-av_FS:                  FS method or HCP method (default)
-qc_LR:                  Based on vitame E capsule verify left-rigth side
-tmp:			               don´t remove temporal files
Pam Garcia
INB May,2020
np.pam.garcia@gmail.com
"
}

#  FUNCTION: PRINT INFO
Info() {
Col="38;5;129m" # Color code
echo  -e "\033[$Col\n[INFO]..... $1 \033[0m"
}

#------------------------------------------------------------------------------#
#			 Declaring variables & WARNINGS


if [ $# -lt 1 ]
 then
        echo -e "\e[0;36m\n[ERROR]... Argument missing \n\e[0m\t\t"
 	help
 	exit 1
 fi
#------------------------------------------------------------------------------#
#                             CHECK PATHS

source ./pathFile.sh

############Do not modify paths below this unless sure##########################

curr_path=$( pwd )
PREEMACS_PATH="$(dirname -- $curr_path)"

templates_path=$PREEMACS_PATH/templates
scripts_path=$PREEMACS_PATH/scripts

#------------------------------------------------------------------------------#
#                                  Options
#Defaults
no_sphinx=1
manual_crop=1
coords=1
average_FS=1
qc_LR=1
tmp=1

for arg in "$@"
do
  case "$arg" in
  -h|-help)
    help
    exit 1
  ;;
  -id)
   SUB_ID=$2
   shift;shift
  ;;
  -t1_path)
   T1_image_path=$2
   shift;shift
  ;;
  -t2_path)
   T2_image_path=$2
   shift;shift
  ;;
  -out_path)
   PREEMACS_DIR=$2
   shift;shift
  ;;
  -sphinx)
   no_sphinx=2
   	echo -e "\e[0;36m\n[INFO] ... Fix the acquision position "
   shift;shift
  ;;
  -mc)
   manual_crop=2
	echo -e "\e[0;36m\n[INFO] ... Manual crop "
   shift;shift
  ;;
   -mcc)
   coords=2
	echo -e "\e[0;36m\n[INFO] ... Manual crop with coords "
   shift;shift
  ;;
  -average_FS)
   average_FS=2
	echo -e "\e[0;36m\n[INFO] ... Average using FS command"
   shift;shift
  ;;
  -qc_LR)
   qc_LR=2
        echo -e "\e[0;36m\n[INFO] ... Left/Right quality control"
   shift;shift
  ;;
  -tmp)
   tmp_path=2
   shift;shift
  ;;
   esac
done

#------------------------------------------------------------------------------#
# 			WARNINGS
# Enough arguments?
Note(){
echo -e "\t\t$1\t\033[38;5;197m$2\033[0m"
}
arg=($SUB_ID $T1_image_path $T2_image_path $PREEMACS_DIR)
if [ "${#arg[@]}" -lt 4 ]; then
Note "-id "      "\t$SUB_ID"
Note "-t1_path " "\t$T1_image_path"
Note "-t2_path " "\t$T2_image_path"
Note "-out_path " "\t$PREEMACS_DIR"
echo -e "\e[0;36m\n[ERROR]...  Insufficient arguments \n\e[0m\t\t"

help; exit 0; fi


#----------------------- Files struct------------------------------------------------------#


if [[ $manual_crop -eq 1 && $coords -eq 1 ]]; then

mkdir $PREEMACS_DIR/$SUB_ID
mkdir $PREEMACS_DIR/$SUB_ID/crop
mkdir $PREEMACS_DIR/$SUB_ID/crop/antsREg
mkdir $PREEMACS_DIR/$SUB_ID/image_conform
mkdir $PREEMACS_DIR/$SUB_ID/N4_T1
mkdir $PREEMACS_DIR/$SUB_ID/N4_T2
mkdir $PREEMACS_DIR/$SUB_ID/orig
mkdir $PREEMACS_DIR/$SUB_ID/scripts
mkdir $PREEMACS_DIR/$SUB_ID/reorient
mkdir $PREEMACS_DIR/$SUB_ID/mask
mkdir $PREEMACS_DIR/$SUB_ID/HCP
fi

mkdir $PREEMACS_DIR/$SUB_ID/tmp



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

#------------------------Module 1 --------------------------------------------------------#

time_start=$(date +%s.%N)
echo -e "\e[0;36m\n[INFO]..... Run Module 1 \n\033[0m"

#-----------------------------------------------------------------------------------------#

if [[ $manual_crop -eq 1 && $coords -eq 1 ]]; then

cd $T1_image_path
num_ima=1
for file in *.nii.gz; do cp $T1_image_path/$file $PREEMACS_DIR/$SUB_ID/orig/raw_${num_ima}_T1.nii.gz; num_ima=$[num_ima +1];  done

#if T2
cd $T2_image_path
for file in *.nii.gz; do cp $T2_image_path/$file $PREEMACS_DIR/$SUB_ID/orig/raw_${num_ima}_T2.nii.gz; num_ima=$[num_ima +1 ]; done

#----------------------- Volume Orientation------------------------------------------------#

if [ $no_sphinx -eq 2 ]; then

cd $PREEMACS_DIR/$SUB_ID/orig/
				    for d in *nii.gz; do
					     ${FREESURFER_HOME}/mri_convert $d $d --sphinx #correct image to sphinx position
			            done
fi

## Volume orientation based on header Info without

cd $PREEMACS_DIR/$SUB_ID/orig/
				    for d in *nii.gz; do
						${FSLDIR}/bin/fslreorient2std $d $reorient_path/${d/.nii.gz/}_REO.nii.gz
						${MRTRIX_DIR}/mrinfo $reorient_path/${d/.nii.gz/}_REO.nii.gz > $TMP/${d/.nii.gz/}_REO.txt
						grep strides $TMP/${d/.nii.gz/}_REO.txt > $TMP/${d/.nii.gz/}_strides.txt
					  orient=$(awk '{ print $4 }' $TMP/${d/.nii.gz/}_strides.txt)
					  correct_orient=1

## Fix general orientation without taking into account the position of vitamin E capsule
if [ ${orient} != ${correct_orient} ]; then

		${FSLDIR}/bin/fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
		${FSLDIR}/bin/fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  -x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
		${FSLDIR}/bin/fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
		cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz

fi

## Fix orientation  based on the position of vitamin E capsule
if [ $qc_LR -eq 2 ]; then

    if [ ${orient} != ${correct_orient} ]; then

	echo "Error Orientation"
	${FSLDIR}/bin/fslview $reorient_path/${d/.nii.gz/}_REO.nii.gz &
        cp $reorient_path/${d/.nii.gz/}_REO.nii.gz $TMP/${d/.nii.gz/}_REO_original.nii.gz

		echo -e "> Is the vitamin E capsule on the right side? Y or N or NI (no info) and close fsl"
		read -p "Orientation: " orientation

	        if [[ $orientation == N ]]; then
		${FSLDIR}/bin/fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
		${FSLDIR}/bin/fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
		${FSLDIR}/bin/fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
			cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz
                fi

               if [[ $orientation == Y ]]; then
		${FSLDIR}/bin/fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
		${FSLDIR}/bin/fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  -x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
		${FSLDIR}/bin/fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
			cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz

               fi

                if [[ $orientation == NI ]]; then
		${FSLDIR}/bin/fslorient -deleteorient $reorient_path/${d/.nii.gz/}_REO.nii.gz
		${FSLDIR}/bin/fslswapdim $reorient_path/${d/.nii.gz/}_REO.nii.gz  x y z $TMP/${d/.nii.gz/}_fix_REO.nii.gz
		rm $reorient_path/${d/.nii.gz/}_REO.nii.gz
		${FSLDIR}/bin/fslorient -setqformcode 1  $TMP/${d/.nii.gz/}_fix_REO.nii.gz
			cp $TMP/${d/.nii.gz/}_fix_REO.nii.gz $reorient_path/${d/.nii.gz/}_REO.nii.gz

               fi

	fi
fi

done

#----------------------- Image Crop ------------------------------------------------#

	for d in *.nii.gz; do
		nii_in=${d/.nii.gz/}_REO.nii.gz
		nii_out=${d/.nii.gz/}_CROP_REO.nii.gz
		path_out=$image_conform

## Image conform 256 or 520 take into account the original FOV
	cd $scripts
	echo "addpath('$scripts_path');data_conform=conform2('$path_job/reorient/','$nii_in','$path_out/','$nii_out');exit()" > $scripts/info.m
	$matlab_path -batch info
	rm $scripts/info.m

	done

cd $image_conform
ls *.nii.gz > $image_conform/file_to_coords.txt

##  Do registration to NMT in order to obtain the geometric space and do the crop

if [[ $manual_crop -eq 1 && $coords -eq 1 ]]; then
Info "Doing crop"
cd $image_conform

	for d in *T1_CROP_REO.nii.gz; do  #Have an option for incorrect orientation (mabybe only my image have a bad orientation)

		nii_out=$image_conform/$d
	$ants_path/antsRegistrationSyN.sh -d 3 -f $templates_path/NMT_05.nii.gz -t r -m $nii_out -o $path_ants_reg/${d/.nii.gz/}_REG_
	done

	for d in *T2_CROP_REO.nii.gz; do  #Have an option for incorrect orientation (mabybe only my image have a bad orientation)

		nii_out=$image_conform/$d
	$ants_path/antsRegistrationSyN.sh -d 3 -f $templates_path/NMT_05.nii.gz -t r -m $nii_out -o $path_ants_reg/${d/.nii.gz/}_REG_
	done


 	rm $path_ants_reg/*_CROP_REO_REG_0GenericAffine.mat
 	rm $path_ants_reg/*_CROP_REO_REG_Warped.nii.gz


## Do crop based on the NMT registration

cd $path_ants_reg

	for d in *nii.gz; do
		reg_file=$d
	     	original_file=$image_conform/${d/_REG_InverseWarped.nii.gz/}.nii.gz

## Outs crop step
nii_out1=$TMP/${d/.nii.gz/}_ones.nii.gz
nii_out2=${d/.nii.gz/}_square_ones.nii.gz
nii_out3=${d/.nii.gz/}_crop.nii.gz
out_not_square_FOV=${d/.nii.gz/}_not_square_FOV.nii.gz
out_square_FOV=${d/.nii.gz/}_square_FOV.nii.gz

### Precise image binarization
	cd $scripts
echo "addpath('$scripts_path');ones_reg_ants=crop_ants('$path_ants_reg/','$reg_file','$nii_out1');exit()" > $scripts/info.m
$matlab_path -batch info
	rm $scripts/info.m
	cd ../

### Get data to native space
	${FSLDIR}/bin/fslmaths $nii_out1 -mul $original_file $TMP/$out_not_square_FOV
### Get dimensions of square FOV
	cd $scripts
echo "addpath('$scripts_path');NewMat=preemacs_square_crop('$TMP/','$out_not_square_FOV','$nii_out2');exit()" > $scripts/info.m
$matlab_path -batch info
	rm $scripts/info.m
	cd ../
### Get image native space with square FOV
	${FSLDIR}/bin/fslmaths $TMP/$nii_out2 -mul $original_file $TMP/$out_square_FOV
### Crop image
	cd $scripts
echo "addpath('$scripts_path');NewMat=preemacs_autocrop('$TMP/','$out_square_FOV','$nii_out3');exit()" > $scripts/info.m
$matlab_path -batch info
	rm $scripts/info.m
	cd ../

cp $TMP/$nii_out3 $path_crop/.

### Doing crop for split the head wih the best dimentions

size=${d/.nii.gz/}_crop.txt
nii_prefinal_crop=${d/.nii.gz/}_crop.nii.gz
echo $nii_prefinal_crop

cd $scripts
echo "addpath('$scripts_path');image_crop=crop_only_brain_3('$TMP/','$nii_prefinal_crop','$size');exit()" > $scripts/info.m
$matlab_path -batch info
rm $scripts/info.m
cd ../
					var=$(cat $TMP/$size)
final_crop=${d/_CROP_REO_REG_InverseWarped.nii.gz/}_final_crop.nii.gz
${MRTRIX_DIR}/mrcrop $var $TMP/$nii_prefinal_crop $TMP/$final_crop
cp $TMP/$final_crop $path_crop/.

done

fi

#-----------------------------------------Manual ------------------------------------------#

if [[ $manual_crop -eq 2 && $coords -eq 1 ]]; then
cp $image_conform/*.nii.gz ${TMP}/.
cd $image_conform

	for d in *.nii.gz; do

		        ${FSLDIR}/bin/fslview $d &


				echo -e "> Coords of ANTERIOR COMMISURE (AC) POSTERIOR COMMISURE (PC) 71 88 147 71 71 146 (see the example .png)"
				read -p "Coords: " coords ###

size=${d/.nii.gz/}_crop.txt

cd $scripts
echo "addpath('$scripts_path');image_crop=manual_crop_brain('$TMP/','$d','$coords','$size');exit()" > $scripts/info.m
$matlab_path -batch info
rm $scripts/info.m
cd ../
					var=$(cat $TMP/$size)

final_crop=${d/_CROP_REO.nii.gz/}_final_crop.nii.gz

echo $final_crop
${MRTRIX_DIR}/mrcrop $var $TMP/$d $TMP/$final_crop
cp $TMP/$final_crop $path_crop/.
cd $image_conform
					done

fi

fi
#------------------------Manual crop with txt ---------------------------------------------------------------------#

if [[ $coords -eq 2 ]]; then

rm $PREEMACS_DIR/$SUB_ID/N4_T1/*.nii.gz
rm $PREEMACS_DIR/$SUB_ID/N4_T2/*.nii.gz

cd $image_conform
cp $image_conform/*.nii.gz ${TMP}/.

	for d in *.nii.gz; do
		name=$d
                cat $image_conform/file_to_coords.txt
		grep $name $image_conform/file_to_coords.txt | colrm 1 25  > $TMP/coords.txt

coords=$(cat $TMP/coords.txt)
size=${d/.nii.gz/}_crop.txt

cd $scripts
echo "addpath('$scripts_path');image_crop=manual_crop_brain('$TMP/','$d','$coords','$size');exit()" > $scripts/info.m
$matlab_path -batch info
rm $scripts/info.m
cd ../
					var=$(cat $TMP/$size)

final_crop=${d/_CROP_REO.nii.gz/}_final_crop.nii.gz

echo $final_crop
${MRTRIX_DIR}/mrcrop $var $TMP/$d $TMP/$final_crop
cp $TMP/$final_crop $path_crop/.
cd $image_conform
					done

fi


#----------------------- Intensity Non-Uniformity (INU) correction ------------------------------------------------#

Info "  Intensity Non-Uniformity (INU) correction "
cd $path_crop
  for d in *T1_final_crop.nii.gz; do  N4_file=${d/.nii.gz/}_N4.nii.gz ; $ants_path/N4BiasFieldCorrection -d 3 -b [100] -i $d -o $N4_T1_path/$N4_file ; done
  for d in *T2_final_crop.nii.gz; do  N4_file=${d/.nii.gz/}_N4.nii.gz ; $ants_path/N4BiasFieldCorrection -d 3 -b [100] -i $d -o $N4_T2_path/$N4_file ; done
#-------------------------------------- Average and Resampling  ---------------------------------------------------#

Info "Average and Resampling"

if [ $average_FS -eq 1 ]; then

## Average T1
	cd $N4_T1_path
	number_images=$(ls -l | wc -l)
	echo $number_images

	if [[ $number_images == 2 ]];
	 then
		 cp $N4_T1_path/*.nii.gz  $path_job/T1_preproc.nii.gz
		 ${MRTRIX_DIR}/mrresize -voxel 0.5 $path_job/T1_preproc.nii.gz $path_job/T1_preproc.nii.gz -force
	fi

	if [[ $number_images > 2 ]];
	  then

	  $scripts_path/AnatomicalAverage -s $templates_path/NMT_05.nii.gz -o $path_job/T1_preproc.nii.gz $N4_T1_path/*.nii.gz
	  ${MRTRIX_DIR}/mrresize -voxel 0.5 $path_job/T1_preproc.nii.gz $path_job/T1_preproc.nii.gz -force
    fi

## Average T2

	cd $N4_T2_path
	number_images=$(ls -l | wc -l)
	echo $number_images

	if [[ $number_images == 2 ]];
	 then
		 cp $N4_T2_path/*.nii.gz  $path_job/T2_preproc.nii.gz
		 ${MRTRIX_DIR}/mrresize -voxel 0.5 $path_job/T2_preproc.nii.gz $path_job/T2_preproc.nii.gz -force
	 fi


    if [[ $number_images > 2 ]];
	  then
	  $scripts_path/AnatomicalAverage -s $templates_path/NMT_05.nii.gz -o $path_job/T2_preproc.nii.gz $N4_T2_path/*.nii.gz
	  ${MRTRIX_DIR}/mrresize -voxel 0.5 $path_job/T2_preproc.nii.gz $path_job/T2_preproc.nii.gz -force
	 fi

fi

### FS Average option
if [ $average_FS -eq 2 ]; then
## Average T1
	cd $N4_T1_path
	number_images=$(ls -l | wc -l)
	echo $number_images

if [[ $number_images == 2 ]];
 then
	 cp $N4_T1_path/*.nii.gz  $path_job/T1_preproc.nii.gz
	 ${MRTRIX_DIR}/mrresize -voxel 0.5 $path_job/T1_preproc.nii.gz $path_job/T1_preproc.nii.gz -force
 fi


if [[ $number_images > 2 ]];
  then
         ${FREESURFER_HOME}/mri_motion_correct.fsl -o $path_job/T1_preproc.nii.gz -wild *.nii.gz
	 ${MRTRIX_DIR}/mrresize -voxel 0.5 $path_job/T1_preproc.nii.gz $path_job/T1_preproc.nii.gz -force
	 rm $path_job/T1_preproc.nii.gz.mri_motion_correct.fsl.log
	 rm $path_job/T1_preproc.nii.gz.mri_motion_correct.fsl.log.old
  fi

## Average T2
     cd $N4_T2_path
	 number_images=$(ls -l | wc -l)
	 echo $number_images

if [[ $number_images == 2 ]];
 then
	 cp $N4_T2_path/*.nii.gz  $path_job/T2_preproc.nii.gz
	 ${MRTRIX_DIR}/mrresize -voxel 0.5 $path_job/T2_preproc.nii.gz $path_job/T2_preproc.nii.gz -force
 fi

if [[ $number_images > 2 ]];
 then
   ${FREESURFER_HOME}/mri_motion_correct.fsl -o $path_job/T2_preproc.nii.gz -wild *.nii.gz
	 ${MRTRIX_DIR}/mrresize -voxel 0.5 $path_job/T2_preproc.nii.gz $path_job/T2_preproc.nii.gz -force
	 rm $path_job/T2preproc.nii.gz.mri_motion_correct.fsl.log
  fi
fi

#------------------------------------- Conform 256 to PREEMACS brainmask tool -------------------------------------------#

Info "Conform"
cd $path_job/

			nii_in=T1_preproc.nii.gz
      nii_out=T1_conform.nii.gz

cd $scripts
echo "addpath('$scripts_path');data_conform=conform2('$path_job/','$nii_in','$path_job/','$nii_out');exit()" > $scripts/info.m
$matlab_path -batch info
rm $scripts/info.m

${FSLDIR}/bin/fslroi $path_job/$nii_in $path_job/$nii_in 0 1

rm $path_job/T1_preproc.nii.gz

#------------------------------------------------------------------------------#
# 			Removes Temoral Files
Info "Deleting temporal files"
   if [ $tmp -eq 1 ]; then
   rm -R $TMP
   fi

#------------------------------------------------------------------------------#
# 			Module 1 end

# Ending time
time_end=$(date +%s.%N)
time_elapsed=$(echo "$time_end - $time_start" | bc)
time_elapsed=`echo print $time_elapsed/60 | perl`
echo -e "\033[38;5;220m\nTOTAL running time: ${time_elapsed} minutes \n\033[0m"
