  function NewMat=preemacs_autocrop(path_job,nii,outname)
        %% nii. after preemacs_square_crop and fslmul per original image with square FOV
 
        %%% data in and out
        
        addpath([path_job]);
        nii_in=([path_job nii]);
        crop_out=([path_job outname]);
        nii=load_nifti(nii_in);      
        
        %%%%%%%%%%%%%% Process %%%%
        
        sizefov= size(nii.vol,1);
        size_only_mat=zeros(sizefov,2);
        
        for i=1:sizefov % Get size per slice 
                
                          M1 = nii.vol(i,:,:,:); 
                          M2 = reshape(M1,[sizefov sizefov]);
        
                            zero_value=find(M2~=0);
                            val=isempty(zero_value);
             
                          if  val==0
                                 size_only_mat(i,1)=find(any(M2>0,2),1,'first');
                                 size_only_mat(i,2)=find(any(M2>0,2),1,'last');
                          end          
        
        end
         
       max_mat=max(size_only_mat); % Get de max value all slices
       
       size_fov_row_start=find(any(size_only_mat>0,2),1,'first');
       size_fov_row_end=find(any(size_only_mat>0,2),1,'last');
       
       start=(size_fov_row_end-size_fov_row_start)+1;
       end_mat=(max_mat(1,2)-max_mat(1,1))+1;
       
       %%%%%%%%%%%%%%%%%%%%%%% Cropping %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       NewMat(start,end_mat)= zeros;
       row_start_1=1;
          
       for i=1:sizefov
        
                        M1 = nii.vol(:,:,i,:); 
                        M2 = reshape(M1,[sizefov sizefov]);   
                        M3 = M2;
        
                        M2( :, ~any(M2,1) ) = [];
                        M2( ~any(M2,2), : ) = [];
     
        
             zero_value=find(M2~=0);
             val=isempty(zero_value);
             

                          if  val==0
                                newM2=M3(size_fov_row_start:size_fov_row_end,max_mat(1,1): max_mat(1,2)) ;                         
                                NewMat(:,:,row_start_1) = newM2;
                                row_start_1=row_start_1+1;
                              
                          end
                          
       end
        
       %%%%%%%%%%%%%% Out %%%%%%%%%%%%%% 
       clear nii.vol
       nii.vol=NewMat;
       save_nifti(nii,crop_out);
  end 