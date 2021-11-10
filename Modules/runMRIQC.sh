#!/bin/bash

help() {
echo -e "
Usage: `basename $0` -dataDir -templateDir -n4dir -id
  dataDir:      Location of Bids data directory
  templateDir:  Location of template files
  n4dir:        Location of N4biasfield corrected T1 and T2 files
  id:       Ids of target t1w files

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
    -n4Dir)
    n4Dir=$2
    shift;shift
   ;;
    -templateDir)
    templateDir=$2
    shift;shift
   ;;
    esac
 done

python3 ../scripts/mriqc/runMRIQC.py "${bidsdir}" "${templateDir}" "${n4Dir}" "${subId}"

echo "Script has finished executing succesfully"
