#!/bin/bash

help() {
echo -e "
Usage: `basename $0` -dataDir -maskDir -id -outDir
  dataDir:      PREEMACS output directory (M1's -out_path), containing <id>/T1_conform.nii.gz
  maskDir:	Location of binary masks (M1/BM's -out_path, containing <id>/brain_mask.nii.gz)
  id:           Subject ID
  outDir:       Output directory

  Make sure to run M1.sh and BM.sh before using this script -- N4 bias
  correction runs on M1's conformed T1 so it shares a voxel grid with BM's
  mask (both live in PREEMACS' own processed space, not raw scanner space).
  Please ensure that Ants is accesible and ready to use. For more information on installation, refer to https://antsx.github.io/ANTsRCore/index.html .

Arun Garimella
INB May,2020
Arunh.garimella@gmail.com
"
}

#  FUNCTION: PRINT INFO
Info() {
Col="38;5;129m" # Color code
echo  -e "\033[$Col\n[INFO]..... $1 \033[0m"
}

# PATHS 

source ./pathFile.sh

# DO NOT MODIFY BELOW THIS LINE

#------------------------------------------------------------------------------#
#			 Declaring variables & WARNINGS

if [ $# -lt 4 ]
 then
        echo -e "\e[0;36m\n[ERROR]... Argument missing \n\e[0m\t\t"
 	help
 	exit 1
 fi

 for arg in "$@"
 do
   case "$arg" in
   -h|-help)
     help
     exit 1
   ;;
   -dataDir)
    bidsdir=$2
    shift;shift
   ;;
   -id)
    subId=$2
    shift;shift
   ;;
    -outDir)
    outputDir=$2
    shift;shift
   ;;
    -maskDir)
    maskDir=$2
    shift;shift
   ;;
    esac
 done


# Stop on the first failed command below -- without this, e.g. an aborted
# fslmaths (mismatched image sizes) would silently fall through to the
# "finished executing succesfully" message anyway.
set -e

cd "${outputDir}/"

mkdir -p $subId
cd $subId

#integrate the out_mask part into this script from the original file.
#Running N4bias field correction with macaque paramters
${ants_path}/N4BiasFieldCorrection -d 3 -b [100] -i ${bidsdir}/${subId}/T1_conform.nii.gz -o [bias_corrected.nii.gz,bias_image.nii.gz]
${FSLDIR}/bin/fslmaths ${maskDir}/${subId}/brain_mask.nii.gz  -thr 0.0001 out_mask.nii.gz
${FSLDIR}/bin/fslmaths bias_corrected.nii.gz -mul out_mask.nii.gz out_file.nii.gz
cd -

echo "Script has finished executing succesfully\n"
