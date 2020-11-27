function ones_reg_ants=crop_ants(path_job,nii,outname)
        addpath([path_job]);
        nii_in=([path_job nii]);
        %nii_out=([outname]);
        nii=load_nifti(nii_in);
            nii.vol(nii.vol~=0)=1;
%                     save_nifti(nii,nii_out);
                        save_nifti(nii,outname);
                    ones_reg_ants=nii.vol;

end