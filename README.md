# **PREEMACS**
pipeline for PREprocessing and Extraction of the MACaque brain Surface

PREEMACS, a pipeline that standardizes the preprocessing of structural MRI images (T1- and T2-weighted) and carries out an automatic surface extraction of the macaque brain.

Module 1 
Volume orientation, image cropping, intensity non-uniformity correction, and volume averaging, ending with skull-stripping through a convolutional neural network.

Module 2 
Quality control using an adaptation of MRIqc method to extract objective quality metrics that are then used to determine the likelihood of accurate brain surface estimation. 

Module 3 
This estimates the white matter and pial surfaces from the T1-weighted volume (T1w) using an NHP customized version of FreeSurfer v6.
In order to customized FreeSurfer to NHP based on 33 subjects from (29) PRIME-DE (Milham et al., 2018) and (4) UNAM-INB data sets, PREEMACS has developed.

1) PREEMACS FreeSurfer segmentation atlas, with cortical and subcortical labels

2) PREEMACS Rhesus parameterization template that includes the Rhesus curvature and sulcal pattern templates for individual monkey WM surface registration

3) PREEMACS Rhesus average surface for final mapping of vertices across all animals

