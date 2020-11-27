        function data_conform=conform2(path_job,nii,path_out,outname)
        addpath([path_job]);
        nii_in=([path_job nii]);
        nii_out=([path_out outname])
        nii=load_nifti(nii_in);
            NewMat=conform_function(nii.vol);
            nii.vol=NewMat;
            nii.pixdim(5:8)=0;
            data_conform=nii;
            save_nifti(nii,nii_out);
        end

%%%%%
function NewMat = conform_function(example)
Mycell = squeeze(num2cell(example,[1 2]));
fov =size(example);
max_dim =max(fov);

if (max_dim <= 256)
    sizefov = 256;
    val_fov=1;
        elseif max_dim <= 320
            sizefov= 320;
            val_fov=2;
        elseif max_dim >= 321
            sizefov=520;
            val_fov=3;
end

if max_dim >=461
    sizefov = 520;
    val_fov=4;
end

NewMat = zeros(sizefov,sizefov);

M1 = Mycell{1,1};
HeightMatrix = size(M1,1);
WidthMatrix = size(M1,2);
slice_num=length(Mycell);

original_slice_num=length(Mycell);

fix_slice_size = 2;
if val_fov ==1 && original_slice_num ~= 256; fix_slice_size=1; end
if val_fov ==2 && original_slice_num ~= 320; fix_slice_size=1; end
if val_fov ==3 && original_slice_num ~= 460; fix_slice_size=1; end
if val_fov ==4 && original_slice_num ~= 520; fix_slice_size=1; end

if fix_slice_size==1

idxS=(sizefov-slice_num)/2;
BoolVec1 = [mod(idxS,1)==0];
if(BoolVec1 == 0) %is integer
                slice_num=slice_num+1;
                Mycell(slice_num)={zeros(HeightMatrix,WidthMatrix)};
end

T = cell(sizefov,1);
T(1:sizefov) = {zeros(sizefov,sizefov)};
place_start=((sizefov-slice_num)/2);
end_place=place_start+slice_num;
end_place=end_place-1;

if max_dim == sizefov-1
    place_start =1;
end

count.l=1;
for h=place_start:end_place;
    T(h)=Mycell(count.l,:);
    count.l=count.l+1;
end
end

if fix_slice_size == 2
     T=Mycell;
 end

for i = 1:length(T);

    ImgMatrix = zeros(sizefov,sizefov);
    % M1= squeeze(example(1,:,:));
    M1 = T{i,1};
    %-----Get Dimensions of the Image----%
    HeighImgMatrix = size(ImgMatrix,1);
    WidthImgMatrix = size(ImgMatrix,2);
    %--Get Dimensions of each Matrix of the
    %-- Orgiginal Image------------------%
    HeightMatrix = size(M1,1);
    WidthMatrix = size(M1,2);
    %------------------------------------%
    idxH = (HeighImgMatrix - HeightMatrix)/2;
    idxW = (WidthImgMatrix - WidthMatrix)/2;

    BoolVec = [mod(idxH,1)==0,mod(idxW,1)==0];

    Addnan;

    Row = idxH+size(M1,1);
    Columns = idxW+ size(M1,2);
    ImgMatrix(idxH+1:Row,idxW+1:Columns )=M1;
    NewMat(:,:,i) = ImgMatrix;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    function    Addnan
        if(sum(BoolVec) == 0) %is integer
            %disp('Square Matrix not found!')
            M1 = [M1;zeros(1,size(M1,2))];
            M1 = [M1 zeros(size(M1,1),1)];
            HeightMatrix = size(M1,1);
            WidthMatrix = size(M1,2);

            idxH = (HeighImgMatrix - HeightMatrix)/2;
            idxW = (WidthImgMatrix - WidthMatrix)/2;

            %disp('Ready to Complete Image')
        elseif(find(BoolVec) == 1)%Is a decimal number
            M1 = [M1 zeros(size(M1,1),1)];
            WidthMatrix = size(M1,2);
            idxW = (WidthImgMatrix - WidthMatrix)/2;

        elseif(find(BoolVec) == 2)
            M1 = [M1;zeros(1,size(M1,2))];
            HeightMatrix = size(M1,1);
            idxH = (HeighImgMatrix - HeightMatrix)/2;
        else
           % disp('Squared Matrix')
        end
    end
end
