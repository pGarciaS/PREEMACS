#!/bin/bash
print_help() {
echo "
Usage:


	`basename $0` SUB_ID T1 T2

1. Sphinx position
2. All crop or coord (manual crop)

Options
      -Do Reg to D99 to Native space.
		Template_image        :          D99

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
	echo -e "\e[0;36m\n[ERROR]... Argument missing: \n\e[0m\t\tT1_path_N_Points $2 \n\t\tYou need list of ID of each point$4"
	print_help
	exit 1
fi


SUB_ID=$1
T1_image_path=$2
T2_image_path=$3
#----------------------- Files struct------------------------------------------------------#
#mkdir /misc/evarts2/PREEMACS_PREPROCESSING/Module1_m2
PREEMACS_DIR=/misc/evarts2/PREEMACS_PREPROCESSING/Module1_m2
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
############################################# Start process to crop ##########################################
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
					#mri_convert $d $d --sphinx #option_only_for_INB
					#mrresize -voxel 0.5 $d ${d/.nii.gz/}_R.nii.gz
					#fslreorient2std ${d/.nii.gz/}_R.nii.gz ${d/.nii.gz/}_REO_R.nii.gz
					#fslreorient2std ${d/.nii.gz/}.nii.gz ${d/.nii.gz/}_REO.nii.gz
					fslreorient2std $d $reorient_path/${d/.nii.gz/}_REO.nii.gz
### Check orientation ####
#fslhd ${d/.nii.gz/}_REO.nii.gz > $path_job/tmp/head_info.txt
#orient=$(grep qform_xorient $path_job/tmp/head_info.txt | colrm 1 15)

mrinfo $reorient_path/${d/.nii.gz/}_REO.nii.gz > $TMP/${d/.nii.gz/}_REO.txt

grep strides $TMP/${d/.nii.gz/}_REO.txt > $TMP/${d/.nii.gz/}_strides.txt
orient=$(awk '{ print $4 }' $TMP/${d/.nii.gz/}_strides.txt)
correct_orient=1


               if [[ $orientation == NI ]]; then ### poner un condicional de no es ninguna opcion y una de que lo haga con mayuscula o minuscula


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

echo "addpath('/misc/evarts2/SCRIPTS');data_conform=conform2('$path_job/reorient/','$nii_in','$path_out/','$nii_out');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m

done
# ######################################## 3 Do Reg to NMT in order to obtain hte gometric to do the crop
# ########## Puede fallar en imagenes no orientadas en esfinge o con hombros
cd $image_conform

for d in *T1_CROP_REO.nii.gz; do  #Have an option for incorrect orientation (mabybe only my image have a bad orientation)
echo $d
nii_out=$image_conform/$d
antsRegistrationSyN.sh -d 3 -f '/misc/evarts/Pam/MONKEY_FS/IMAGES_FOR_REGISTER/NMT_05.nii.gz' -t r -m $nii_out -o $path_ants_reg/${d/.nii.gz/}_REG_
done

for d in *T2_CROP_REO.nii.gz; do  #Have an option for incorrect orientation (mabybe only my image have a bad orientation)
echo $d
nii_out=$image_conform/$d
antsRegistrationSyN.sh -d 3 -f '/misc/evarts/Pam/MONKEY_FS/IMAGES_FOR_REGISTER/NMT_05.nii.gz' -t r -m $nii_out -o $path_ants_reg/${d/.nii.gz/}_REG_
done


 																				rm $path_ants_reg/*_CROP_REO_REG_0GenericAffine.mat
 				  															rm $path_ants_reg/*_CROP_REO_REG_Warped.nii.gz
#
# ####Poner un control de calidad aqui pq si no le queda tienes que meter las coordenadas
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

echo "addpath('/misc/evarts2/SCRIPTS');ones_reg_ants=crop_ants('$path_ants_reg/','$reg_file','$nii_out1');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd ../


fslmaths $nii_out1 -mul $original_file $TMP/$out_not_square_FOV

cd $scripts
echo "addpath('/misc/evarts2/SCRIPTS');NewMat=preemacs_square_crop('$TMP/','$out_not_square_FOV','$nii_out2');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd ../

fslmaths $TMP/$nii_out2 -mul $original_file $TMP/$out_square_FOV

cd $scripts
echo "addpath('/misc/evarts2/SCRIPTS');NewMat=preemacs_autocrop('$TMP/','$out_square_FOV','$nii_out3');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m
cd ../

cp $TMP/$nii_out3 $path_crop/.
############### Doing crop for splir the head wih the best dimentions

size=${d/.nii.gz/}_crop.txt
nii_prefinal_crop=${d/.nii.gz/}_crop.nii.gz
echo $nii_prefinal_crop
cd $scripts
echo "addpath('/misc/evarts2/SCRIPTS');image_crop=crop_only_brain('$TMP/','$nii_prefinal_crop','$size');exit()" > $scripts/info.m
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



Template_for_Reg='/misc/evarts/Pam/MONKEY_FS/IMAGES_FOR_REGISTER/NMT_05.nii.gz'

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


########## Conform 256 para mask
cd $path_job/

for file in *.nii.gz; do
nii_in=$file
nii_out=T1_conform.nii.gz
cd $scripts

echo "addpath('/misc/evarts2/SCRIPTS');data_conform=conform2('$path_job/','$nii_in','$path_job/','$nii_out');exit()" > $scripts/info.m
/home/inb/soporte/fmrilab_software/MatlabR2018a/bin/matlab -r -nodisplay -nojvm info
rm $scripts/info.m

fslroi $path_job/$nii_out $path_job/$nii_out 0 1 #quitando el ultimo volumen matlab le pone 256x256x256x1

done
