
function [NII]= fake_space(path_before_FS,seq,space,state,file_name)
%help
%FS_SUB='/misc/evarts2/PREEMACS_PREPROCESSING/5_FREESURFER_NATIVE_SPACE/'
%%space=[1;0.5;0.5;0.5;0;0;0;0]
%%space=[1;1;1;1;0;0;0;0]
%state= '_no_fake' or '_fake'
%seq= MRI_sequence T1 or T2
%file_name= without .nii.gz
path=path_before_FS

    seq=strcat(path,file_name,'.nii.gz');
    seq_out=strcat(path,file_name,state,'.nii.gz');

    nii= load_nifti(seq)
    nii.pixdim=space
    save_nifti(nii,seq_out)
    NII=1;

end
