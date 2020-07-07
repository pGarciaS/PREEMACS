# **PREEMACS**  
pipeline for **PRE**processing and **E**xtraction of the **MAC**aque brain **S**urface

**PREEMACS** is a set of tools taken from several image processing softwares commonly used for human data analysis, customized for Rhesus monkeys brain surface extraction and cortical thickness analysis.

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/PREEMACS_NHP_FREESURFER.png?raw=true)

## **Module 1** 

Perform volume orientation, image cropping, intensity non-uniformity correction, and volume averaging, ending with skull-stripping through a convolutional neural network.

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/NHP_brainmask.png?raw=true)

## **Module 2** 

Quality control using an adaptation of MRIqc method to extract objective quality metrics that are then used to determine the likelihood of accurate brain surface estimation. 

## **Module 3** 

This module estimates the white matter and pial surfaces from the T1-weighted volume (T1w) using an NHP customized version of FreeSurfer v6.

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/PREEMACS_RESULTS.png?raw=true)

## PREEMACS NHP TEMPLATES

In order to customized FreeSurfer to NHP, PREEMACS  based on 33 subjects from (29) PRIME-DE (Milham et al., 2018) and (4) UNAM-INB data sets has developed.

1) **PREEMACS FreeSurfer segmentation atlas**, with cortical and subcortical labels

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/NHP_FREESURFER_ATLAS.png?raw=true)

2) **PREEMACS Rhesus parameterization template ** that includes the Rhesus curvature and sulcal pattern templates for individual monkey WM surface registration

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/NHP_FREESURFER_TEMPLATE.PNG?raw=true)

3) **PREEMACS Rhesus average surface** for final mapping of vertices across all animals

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/CT_final_analisis._inferno.jpg?raw=true)

