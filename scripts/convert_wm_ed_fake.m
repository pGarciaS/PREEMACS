

function [NII]= prepare(FS_SUB)
%help 
%FS_SUB='/misc/evarts/Pam/MONKEY_FS/FREESURFER/T1_11/mri/HICPO/'
path2=FS_SUB

    wm=strcat(path2,'wm.seg_final_no_fake.nii.gz');  
    wm_out=strcat(path2,'wm.seg_final_fake.nii.gz');
     
    nii= load_nifti(wm)
    nii.pixdim=[1;1;1;1;0;0;0;0]
    save_nifti(nii,wm_out)

end
