#/bin/bash

#Arun Garimella
#9 Nov 2021

# May 13 2024 Luis Concha
# Removed default installations

# Check installation of the following programs
 
#Do not change after this

#FSL
echo "Checking FSL"
if [ ! -d "$FSLDIR" ]; then
		echo "FSL not installed"; 
		exit $ERRCODE; 
fi
echo "  FSL is found at ${FSLDIR}" 

#FREESURFER
echo "Checking Freesurfer"
	if [ ! -d "$FREESURFER_HOME" ]; then
		echo "Freesurfer not installed"; 
		exit $ERRCODE; 
	fi
echo "  FREESURFER is found at ${FREESURFER_HOME}" 

#MATLAB
echo "Checking MATLAB"
if [ -z $(which matlab) ]; then
		echo "matlab not installed"; 
		exit $ERRCODE; 
fi
matlab_bin=$(which matlab)
export matlab_path=$(dirname $matlab_bin)
echo "  MATLAB is found at ${matlab_path}" 

#MRTRIX
echo "Checking MRTRIX"
if [ -z $(which mrcalc) ]; then
		echo "MRTRIX not installed"; 
		exit $ERRCODE; 
fi
mrcalc_bin=$(which mrcalc)
MRTRIX_DIR=$(dirname $mrcalc_bin)
echo "  MRTRIX is found at ${MRTRIX_DIR}" 

#ANTS
echo "Checking ANTS"
if [ ! -d $ANTSPATH ]; then
		echo "ANTS not installed"; 
		exit $ERRCODE; 
fi
export ants_path=$ANTSPATH
echo "  ANTs is found at ${ants_path}" 


