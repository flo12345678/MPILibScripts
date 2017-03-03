using MPILib
using Images
using ImageView
# filename = tempname()*".zip"
# dir = tempname()
# mkpath(dir)

#download("http://www.dclunie.com/images/pixelspacingtestimages.zip", filename)
#run(`unzip $filename -d $dir`)
#open(dcm_parse, joinpath(dir, "DISCIMG/IMAGES/MGIMAGEA"))

f=open(dcm_parse,"/home/fgriese/Documents/Daten/DICOMData/MausMRT/DICOM/IM_0002");
dicomdata=getPixelData(f);

MRIData=loaddata_analyze("/home/fgriese/Documents/Daten/NIFTIDATA/t1_se_cor_FS_256Te8.6TR200NSA4.nii");
niidata=MRIData.data[:,:,23];

diff=dicomdata-niidata;
max_nii=maximum(niidata)
min_nii=minimum(niidata)

max_dicom=maximum(dicomdata)
min_dicom=minimum(dicomdata)

view(dicomdata)
view(niidata)

view(diff)

println("$max_nii")
println("$min_nii")
