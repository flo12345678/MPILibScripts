using MPILib
using Images
using GLVisualize, GLWindow, GLAbstraction
using JLD

close("all")
savePath="/home/griese/HoughStudies/"

println("loading...")
tic()
#createSphere=load("/home/griese/.julia/v0.4/MPILib/src/Examples/Testdata/createdOneSphere1.4250000.250.250.5.jld")
#createSphere=load("/home/griese/.julia/v0.4/MPILib/src/Examples/Testdata/createdOneSphere60.00.00.0111.jld")
#createSphere=load("/home/griese/.julia/v0.4/MPILib/src/Examples/Testdata/createdOneSphere60.250.250.25111.jld")
#createSphere=load("/home/griese/.julia/v0.4/MPILib/src/Examples/Testdata/createdOneSphere60.50.50.5111.jld")
#createSphere=load("/home/griese/.julia/v0.4/MPILib/src/Examples/Testdata/createdOneSphere60.750.750.75111.jld")
# createSphere=load("/home/griese/.julia/v0.4/MPILib/src/Examples/Testdata/createdOneSphere6111111.jld")
# sphere=createSphere["sphereImage"]
# center=createSphere["centerPixel"]
# pixelSpacing=createSphere["pixelSpacing"]
# radius=createSphere["radius"]
# sizing=[50 40 30]
# pixelSpacing=[1 1 1]
# radius=6
# moveXYZ=[0 0 0]
# numPointsAngles=500
# sVImg=createSphere(sizing, radius, moveXYZ, pixelSpacing, numPointsAngles)
#SaveAndCopyImg(sVImg,"Sphere")

# oneSphere=load("/home/griese/.julia/v0.4/MPILib/src/Examples/Testdata/oneSphere.jld")
# sphere=oneSphere["oneSphere"]
# center=[28.5 8 5.5] # oneSphere center recognition visible (28.5, 8, 5.5)
# pixelSpacing=oneSphere["pixelSpacing"]
# radius=1.45

# threeSphere=load("/home/griese/.julia/v0.4/MPILib/src/Examples/Testdata/threeSphere.jld")
# sphere=threeSphere["threeSphere"]
# center=[28 8 5;95 58 16;75 115 20] # threeSphere center recognition visible
# pixelSpacing=threeSphere["pixelSpacing"]
# radius=1.425

# origOneSphere=load("/home/fgriese/.julia/v0.4/MPILib/src/Examples/Testdata/origOneSphere.jld")
# sphere=origOneSphere["origOneSphere"]
# center=[28 8 5;95 58 16;75 115 20] # threeSphere center recognition visible
# pixelSpacing=origOneSphere["pixelSpacing"]
# radius=1.45

MRIData=loaddata_analyze("/mnt/results/mridata/20160901_ThreeSphereFID/Nifti/T2st_0TE77_48TR_sag.nii")
origThreeSphere=loadDICOMStack("/mnt/results/mridata/20160901_ThreeSphereFID/Dicom")
#sphere=origThreeSphere.Volume[1].data
sphere=MRIData.data
cutSphere=sphere[80:end,:,:]
center=[28 8 5;95 58 16;75 115 20] # threeSphere center recognition visible
pixelSpacing=origThreeSphere.Volume[1].properties["pixelspacing"]
radius=1.45


#prefix="createdOneSphere"
#prefix="oneSphere"
prefix="threeSphere"
v=cutSphere
#v=sphere
#v=sVImg.data
showMultiImages(v,3,fignum=1)
println("loading Time:")
toc()

println("Gauß filtering...")
tic()
sigfac = 1
sigma = [sigfac; sigfac; sigfac]
vGauß = Images.imfilter_gaussian(v, sigma)
gauß = Images.Image(vGauß)
showMultiImages(gauß.data ,3,fignum=4)
println("Gauß filtering time: $(toc())")

println("Sobel filtering...")
tic()
# Sobel Filter
vSobel, sobX,sobY,sobZ = sobelFilter3D(copy(v),factor=2)
sobel=Images.Image(vSobel)
#SaveAndCopyImg(sobel, "Sobel")
showMultiImages(sobel.data,3,fignum=7)
println("Sobel Filter Time:")
toc()

println("Non maximum suppression")
tic()
vNMS=nonMaximumSuppression(copy(vSobel), copy(sobX), copy(sobY), copy(sobZ))
nMS=Images.Image(vNMS)
showMultiImages(nMS.data,3,fignum=10)
println("Non maximum suppression Time: $(toc())")


println("Hysterese filtering")
tic()
Hysteresename="$(prefix)Hysterese.jld"
cutoffPercent=0.15
cutoff=maximum(vNMS)*cutoffPercent
hysterThreshold=[cutoff 2*cutoff]
vHyster, binaryMask = hysteresisThreshold(copy(vNMS), hysterThreshold)
edgeind=find(binaryMask)
println("Number of voxel: $(length(edgeind))")
#save("$(savePath)$(Hysteresename)", "vFilterHysterese", vFilterHysterese)
hyster=Images.Image(vHyster)
#SaveAndCopyImg(hyster, "Hyster")
showMultiImages(hyster.data,3,fignum=13)
println("Hysterese filter Time:")
toc()

tic()
#accu,accuValue=houghTransform3DSimple(v,collect(radius),180,90, pixelSpacing)
#accu,accuValue=houghTransform3DRand(v,collect(radius),400000, pixelSpacing)
accuDirect, accuVDirect = houghTransformSphere3DDirection(vHyster,collect(radius), vSobel, sobX, sobY, sobZ, pixelSpacing)
accu, accuV=houghTransformSphere3D(vHyster,collect(radius),200 ,100, pixelSpacing)
maxikey=getmaxima(accu, 3, suppressRadius=1)
maxiDirectKey=getmaxima(accuDirect, 3, suppressRadius=1)

centers=convertToCenterArray(maxikey)
centersDirect=convertToCenterArray(maxiDirectKey)

centersInPixel=centers./pixelSpacing'
centersDirectInPixel=centersDirect./pixelSpacing'

# SanityCheck
centerModel=MPILib.centerModel
valid, result, error=sanityCheck(centers, centerModel, tolerance=1.0)
validDirect, resultDirect, errorDirect=sanityCheck(centersDirect, centerModel, tolerance=1.0)

figure(100)
ax = gca(projection="3d")
title("Sphere Fiducial center coordinates")
xlabel("x"); ylabel("y"); zlabel("z")
plot3D([centers[1,1]],[centers[1,2]],[centers[1,3]], "*", color="red", label="Meas: middleLeftMiddle")
plot3D([centers[2,1]],[centers[2,2]],[centers[2,3]], "+", color="red", label="Meas: frontMiddleUp")
plot3D([centers[3,1]],[centers[3,2]],[centers[3,3]], "D", color="red", label="Meas: backRightDown")

plot3D([centerModel[1,1]],[centerModel[1,2]],[centerModel[1,3]], "*", color="blue" ,label="Model: middleLeftMiddle")
plot3D([centerModel[2,1]],[centerModel[2,2]],[centerModel[2,3]], "+", color="blue",label="Model: frontMiddleUp")
plot3D([centerModel[3,1]],[centerModel[3,2]],[centerModel[3,3]], "D", color="blue",label="Model: backRightDown")

legend(loc="lower right", ncol=2)

maxima=getmaxima(accu,9)
maximaValue=getmaxima(accuV,9)
println("Hough Time: $(toc())")

tic()
houghSpace=zeros(size(v,1),size(v,2),size(v,3))
for tuple in accu
  coords=tuple[1]
  houghSpace[convert(Int64,coords[2]),convert(Int64,coords[3]),convert(Int64,coords[4])]=tuple[2]
end
houghSpaceeImg=Images.Image(houghSpace)
#SaveAndCopyImg(houghSpaceeImg,"Hough")

houghSpaceDirect=zeros(size(v,1),size(v,2),size(v,3))
for tuple in accuDirect
  coords=tuple[1]
  houghSpaceDirect[convert(Int64,coords[2]),convert(Int64,coords[3]),convert(Int64,coords[4])]=tuple[2]
end
houghSpaceDirectImg=Images.Image(houghSpaceDirect)
#SaveAndCopyImg(houghSpaceDirectImg,"HoughDirect")
# save("Resultdata/houghSpacee$(prefix)$(radius)$(relmovex)$(relmovey)$(relmovez)$(pixelSpacing[1])$(pixelSpacing[2])$(pixelSpacing[3]).jld",
#  "houghSpace", houghSpace, "centerPixel", centerPixel, "pixelSpacing", pixelSpacing,
#  "radius", radius)
 toc()
# @async volumeRendering3D(houghSpace)

# show slices
#clf()

showMultiImages(houghSpaceeImg.data,3,fignum=19)

showMultiImages(houghSpaceDirectImg.data,3,fignum=22)
