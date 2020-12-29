#!/bin/bash

help() {
echo -e "
Usage: `basename $0` -dataDir -maskDir -id -outDir
  dataDir:      Location of Bids data directory
  maskDir:	Location of binary masks 
  id:           Subject ID
  outDir:       Output directory

  Make sure to run BM.sh before using this script.
  Please ensure that Ants is accesible and ready to use. For more information on installation, refer to https://antsx.github.io/ANTsRCore/index.html .
  The script expects one nifti file in the anat directory of each subject to run succesfully.
  For more information on BIDs data format, please refer to https://bids.neuroimaging.io/ .

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


cd "${outputDir}/"

if [[ ! -e $subId ]]; then
    mkdir $subId
    cd $subId
fi

#integrate the out_mask part into this script from the original file. 
#Running N4bias field correction with macaque paramters
N4BiasFieldCorrection -d 3 -b [100] -i ${bidsdir}/${subId}/anat/*.nii.gz  -o [bias_corrected.nii.gz,bias_image.nii.gz]
fslmaths ${maskDir}/${subId}/brain_mask.nii.gz  -thr 0.0001 out_mask.nii.gz
fslmaths bias_corrected.nii.gz -mul out_mask.nii.gz out_file.nii.gz
cd -

echo "Script has finished executing succesfully\n"
