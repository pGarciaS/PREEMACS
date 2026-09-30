#!/bin/bash

help() {
echo -e "
Usage: `basename $0` -dataDir -templateDir -n4dir -id
  dataDir:      PREEMACS output directory (M1's -out_path), containing <id>/T1_conform.nii.gz
  templateDir:  Location of template files
  n4dir:        Output directory generateN4.sh was run with (-outDir), containing <id>/{bias_corrected,bias_image,out_file,out_mask}.nii.gz
  id:           Subject ID

  Run M1.sh, BM.sh, then generateN4.sh before using this script -- MRIQC
  evaluates M1's conformed T1 (PREEMACS' own processed space), not the raw
  scan, so its inputs must already exist from those earlier steps.
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
    -n4dir)
    n4Dir=$2
    shift;shift
   ;;
    -templateDir)
    templateDir=$2
    shift;shift
   ;;
    esac
 done

/opt/venvs/mriqc/bin/python3 ../scripts/mriqc/runMRIQC.py "${bidsdir}" "${templateDir}" "${n4Dir}" "${subId}"
status=$?

if [ $status -ne 0 ]; then
  echo -e "\e[0;36m\n[ERROR]... runMRIQC.py failed (exit $status) \n\e[0m"
  exit $status
fi

echo "Script has finished executing succesfully"
