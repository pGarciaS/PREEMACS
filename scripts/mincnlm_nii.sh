#!/bin/bash


source `which my_do_cmd`



print_help()
{
  echo "
  `basename $0` <infile.nii[.gz]> <outfile.nii[gz]> [-options <\"option1 option2...\">]

  This is just a wrapper for minclm to handle nifti files. 

  For options, see the documentation of mincnlm.

  Luis Concha
  INB, UNAM
  February, 2013.
"
}


if [ $# -lt 2 ] 
then
  echo " ERROR: Need more arguments..."
  print_help
  exit 1
fi



declare -i i
i=1
skip=1
for arg in "$@"
do
  case "$arg" in
    -h|-help) 
      print_help
      exit 1
    esac
    i=$[$i+1]
done


IN=$1
OUT=$2
#-----------------------------------------------------------------
minc_path=$PREEMACS_PATH/programs
FREESURFER_HOME=/home/inb/lconcha/fmrilab_software/freesurfer_6.0
source $FREESURFER_HOME/SetUpFreeSurfer.sh
#-----------------------------------------------------------------
tmpDir=/tmp/mincnlm_$$
mkdir $tmpDir

suffix=${IN: -2}
isZipped=0
if [[ "$suffix" == "gz" ]]
then
  echo " File is zipped. Unzipping to a temp file..."
  gunzip -c $IN > ${tmpDir}/in.nii
  IN=${tmpDir}/in.nii
  isZipped=1
fi

mncFile=${tmpDir}/mncFile.mnc

#my_do_cmd nii2mnc $IN ${mncFile}
# CAREFUL, mnc2nii is making funny things with image orientation!!!
${FREESURFER_HOME}/mri_convert $IN ${mncFile}
${minc_path}/mincnlm ${mncFile} ${mncFile%.mnc}_denoised.mnc
#my_do_cmd mnc2nii ${mncFile%.mnc}_denoised.mnc ${OUT%.gz}
# CAREFUL, mnc2nii is making funny things with image orientation!!!
${FREESURFER_HOME}/mri_convert ${mncFile%.mnc}_denoised.mnc ${OUT%.gz}


if [ $isZipped -eq 1 ]
then
  gzip -v ${OUT%.gz}
fi

rm -fR $tmpDir
