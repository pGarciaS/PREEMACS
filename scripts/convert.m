
function [NII]= prepare(SUBJECTS_DIR,space,state)
%help 
%SUBJECTS_DIR='/misc/evarts/Pam/MONKEY_FS/FREESURFER/T1_11/mri/HICPO/'
%%space=[1;0.5;0.5;0.5;0;0;0;0]
%%space=[1;1;1;1;0;0;0;0]
%state= '_no_fake' or '_fake'
path=SUBJECTS_DIR


file_1=strcat('T1')
file_2=strcat('wm.seg')
file_3=strcat('wm.seg_MOD')

    T1=strcat(path,file_1,'.nii.gz');  
    wm.seg=strcat(path,file_2,'.nii.gz');
    wm.seg_MOD=strcat(path,file_3,'.nii.gz');
    
     T1_out=strcat(path,file_1,state,'.nii.gz');
     wm.seg_out=strcat(path,file_2,state,'.nii.gz');
     wm.seg_MOD_out=strcat(path,file_3,state,'.nii.gz');
     
    nii= load_nifti(T1)
    nii.pixdim=space
    save_nifti(nii,T1_out)

    
    nii= load_nifti(wm.seg)
    nii.pixdim=space
    save_nifti(nii,wm.seg_out)
    
    nii= load_nifti(wm.seg_MOD)
    nii.pixdim=space
    save_nifti(nii,wm.seg_MOD_out)
end
