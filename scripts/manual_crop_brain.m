function image_crop=manual_crop_brain(path_job,nii,coords, outname)
        %%% nii. after crop 
        addpath([path_job]);
        nii_in=([path_job nii]);
        crop_out=([path_job outname]);
        nii=load_nifti(nii_in);
        
        coords=str2num(coords)
        
        voxel_size_x=nii.pixdim(2,1);
        voxel_size_y=nii.pixdim(3,1);
        voxel_size_z=nii.pixdim(4,1);
        
        
        dif_CA_CP= coords(1,3)-coords(1,6); % This says how uneven the image ca and cp is
        
        if dif_CA_CP >= 9
            
            axis_x_start= coords(1,1)-round(33/voxel_size_x);
                     if  axis_x_start >= 0; axis_x_start=num2str(axis_x_start);end  
                     if  axis_x_start <= 0; axis_x_start = 1;axis_x_start=num2str(axis_x_start);end  
            axis_x_end=num2str(round(33/voxel_size_x)+coords(1,1));
        
            axis_y_start=coords(1,4)-round(55/voxel_size_y);
                     if  axis_y_start >= 0;axis_y_start=num2str(axis_y_start);end  
                     if  axis_y_start <= 0; axis_y_start = 1;axis_y_start=num2str(axis_y_start);end 
            axis_y_end=num2str(round(30/voxel_size_y)+coords(1,2));  

            axis_z_start=coords(1,3)-round(35/voxel_size_z);
                     if  axis_z_start >= 0;axis_z_start=num2str(axis_z_start);end  
                     if  axis_z_start <= 0; axis_z_start = 1;axis_z_start=num2str(axis_z_start);end 
            axis_z_end=num2str(round(39/voxel_size_z)+coords(1,6)); 
 
        image_crop=['-axis 0 ',axis_x_start, ' ',axis_x_end ];
        image_crop=[image_crop,' -axis 1 ', axis_y_start,' ' ,axis_y_end];
        image_crop=[image_crop,' -axis 2 ',axis_z_start,' ' ,axis_z_end];
        
        s='''';
        eval([ 'dlmwrite(' s crop_out s ',image_crop,' s 'delimiter' s ',' s '' '' s ')' ])

            
        end
        
if dif_CA_CP <=8
        
        axis_x_start= coords(1,1)-round(33/voxel_size_x);
                     if  axis_x_start >= 0; axis_x_start=num2str(axis_x_start);end  
                     if  axis_x_start <= 0; axis_x_start = 1;axis_x_start=num2str(axis_x_start);end  
        axis_x_end=num2str(round(33/voxel_size_x)+coords(1,1));
        
        
        axis_y_start=coords(1,5)-round(35/voxel_size_y) %atras 
        %axis_y_start=coords(1,4)-round(42/voxel_size_y); end %atras (127
        %es el centro 
                     if  axis_y_start >= 0;axis_y_start=num2str(axis_y_start);end  
                     if  axis_y_start <= 0; axis_y_start = 1;axis_y_start=num2str(axis_y_start);end 
        axis_y_end=num2str(round(33/voxel_size_y)+coords(1,2)); %adelante  


        axis_z_start=coords(1,3)-round(34/voxel_size_z);
                     if  axis_z_start >= 0;axis_z_start=num2str(axis_z_start);end  
                     if  axis_z_start <= 0; axis_z_start = 1;axis_z_start=num2str(axis_z_start);end 
        axis_z_end=num2str(round(34/voxel_size_z)+coords(1,6)); 
 
        image_crop=['-axis 0 ',axis_x_start, ' ',axis_x_end ];
        image_crop=[image_crop,' -axis 1 ', axis_y_start,' ' ,axis_y_end];
        image_crop=[image_crop,' -axis 2 ',axis_z_start,' ' ,axis_z_end]
        
        s='''';
        eval([ 'dlmwrite(' s crop_out s ',image_crop,' s 'delimiter' s ',' s '' '' s ')' ])
end
end
