#/bin/bash

#Arun Garimella
#9 Nov 2021

# Check installation of the following programs
fslOut=/home/inb/lconcha/fmrilab_software/fsl_5.0.6
freesurferOut=/usr/local/freesurfer/bin
matlabOut=/usr/local/MATLAB/R2021a/bin/matlab
mrtrixOut=/home/kilimanjaro2/anaconda3/envs/mrtrix/bin
antsOut=/opt/ANTs/bin
 
#Do not change after this

#FSL
echo "Checking FSL"
if [ ! -d "$FSLDIR" ]; then
	export FSLDIR=${fslOut}
	if [ ! -d "$FSLDIR" ]; then
		echo "FSL not installed"; 
		exit $ERRCODE; 
	fi
fi
echo "FSL is found at ${FSLDIR}" 

#FREESURFER
echo "Checking Freesurfer"
#if [ ! -d "$FREESURFER_HOME" ]; then
	export FREESURFER_HOME=${freesurferOut}
	if [ ! -d "$FREESURFER_HOME" ]; then
		echo "Freesurfer not installed"; 
		exit $ERRCODE; 
	fi
	echo "Freesurfer is found at ${FREESURFER_HOME}" 
	source $FREESURFER_HOME/SetUpFreeSurfer.sh
#fi
echo "FREESURFER is found at ${FREESURFER_HOME}" 

#MATLAB
echo "Checking MATLAB"
if [ ! -f "$matlab_path" ]; then
	export matlab_path=${matlabOut}
	if [ ! -f "$matlab_path" ]; then
		echo "matlab not installed"; 
		exit $ERRCODE; 
	fi
fi
echo "MATLAB is found at ${matlab_path}" 

#MRTRIX
echo "Checking MRTRIX"
if [ ! -d "$MRTRIX_DIR" ]; then
	export MRTRIX_DIR=${mrtrixOut}
	if [ ! -d "$MRTRIX_DIR" ]; then
		echo "MRTRIX not installed"; 
		exit $ERRCODE; 
	fi
fi
echo "MRTRIX is found at ${MRTRIX_DIR}" 

#ANTS
echo "Checking ANTS"
if [ ! -d "$ants_path" ]; then
	export ants_path=${antsOut}
	if [ ! -d "$ants_path" ]; then
		echo "ANTS not installed"; 
		exit $ERRCODE; 
	fi
fi
echo "ANTs is found at ${ants_path}" 


