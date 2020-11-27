function NewMat=preemacs_square_crop(path_job,nii,outname)
        %% nii. after crop1 (not square FOV)
        %%% This function do a mask for crop only the voxels related with the
        %%% monkey head, erreasing the neck and face
        
        %%% data in and out
        
        addpath([path_job]);
        nii_in=([path_job nii]);
        crop_out=([path_job outname]);
        nii=load_nifti(nii_in);
        
        %%%%%%%%%%%%%% Process %%%%
        
        sizefov= size(nii.vol,1);
        y_slice_half=(size(nii.vol,1)/2); %Get the max size

        M1 = nii.vol(y_slice_half,:,:,:); 
        M2 = reshape(M1,[sizefov sizefov]);
        
        col_start_1=find(any(M2>0,2),1,'first');
        col_end_1=find(any(M2>0,2),1,'last');
           
        size_only_mat=zeros(sizefov,4);
        
        for i=1:sizefov % Get size per slice 
                
                          M1 = nii.vol(i,:,:,:); 
                          M2 = reshape(M1,[sizefov sizefov]);
        
                            zero_value=find(M2~=0);
                            val=isempty(zero_value);
             
                          if  val==0
                                 size_only_mat(i,1)=find(any(M2>0,1),1,'first');

                          end          
        
        end
         
       size_fov_row_start=find(any(size_only_mat>0,2),1,'first');
       size_fov_row_end=find(any(size_only_mat>0,2),1,'last');
       
       %%%%%%%%%%%%%%%%%%%%%%% Ones %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       NewMat(sizefov,sizefov)= zeros;
  
       for i=1:sizefov
                   
        
                         M1 = nii.vol(:,:,i,:); 
                         M2 = reshape(M1,[sizefov sizefov]);   

                         zero_value=find(M2~=0);
                         val=isempty(zero_value);
                         
                         M0(sizefov,sizefov)= zeros;
                        

                          if  val==0
                                M0(size_fov_row_start:size_fov_row_end,col_start_1:col_end_1)=ones;    
                          end
             NewMat(:,:,i) = M0;
       clear M0;                   
       end
        
       %%%%%%%%%%%%%% Out %%%%%%%%%%%%%% 
       clear nii.vol
       nii.vol=NewMat;
       save_nifti(nii,crop_out);
end