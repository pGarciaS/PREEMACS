#/bin/bash

#Arun Garimella
#9 Nov 2021

# May 13 2024 Luis Concha
# Removed default installations

# Check installation of the following programs
 

# User should have installed the following tools:
# fsl (tested with version 6.0.4.1)
# freesurfer (tested with version 7.4.1)
# Matlab (tested with version R2023a)
# MRtrix (tested with version 3.0.4)
# ANTS (tested with version 2.4.4)
# pytorch (python module, tested with version 2.3.0)

#####
# This file is to be run as this:
# source pathFile.sh
####











#Do not change after this
isOK=1

#FSL
echo "Checking FSL ..."
if [ ! -d "$FSLDIR" ]; then
	echo "FSL not installed"; 
	isOK=0 
else
	echo "  FSL is found at ${FSLDIR}" 
fi

#FREESURFER
echo "Checking Freesurfer ..."
if [ ! -d "$FREESURFER_HOME" ]; then
	echo "Freesurfer not installed"; 
	isOK=0 
else
	echo "  FREESURFER is found at ${FREESURFER_HOME}" 
fi

#MATLAB
echo "Checking MATLAB ..."
if [ -z $(which matlab) ]; then
	echo "matlab not installed"; 
	isOK=0 
else 
	matlab_bin=$(which matlab)
	export matlab_path=$(dirname $matlab_bin)
	echo "  MATLAB is found at ${matlab_path}" 
fi

#MRTRIX
echo "Checking MRTRIX ..."
if [ -z $(which mrcalc) ]; then
	echo "MRTRIX not installed"; 
	isOK=0 
else
	mrcalc_bin=$(which mrcalc)
	MRTRIX_DIR=$(dirname $mrcalc_bin)
	echo "  MRTRIX is found at ${MRTRIX_DIR}" 
fi

#ANTS
echo "Checking ANTS ..."
if [ ! -d $ANTSPATH ]; then
	echo "ANTS not installed"; 
	isOK=0 
else
	export ants_path=$ANTSPATH
	echo "  ANTs is found at ${ants_path}" 
fi

# Pytorch
echo "Checking pytorch ..."
python -c "import torch"
if [ $? -ne 0 ]; then
	echo "pytorch not installed"; 
	isOK=0  
else
	echo "  Pytorch module exists." 
fi

if [ $isOK -eq 1 ]
then
  echo "All requirements are installed and configured, OK lets go!"
else
  echo "[ERROR] There are unmet dependencies. Please configure accordingly and run again."
fi