using MPILib
using Images
include("Functions.jl")
include("HoughTransformation.jl")
savePath="/home/griese/HoughStudies/"

println("loading...")
tic()
createSphere=load("/home/fgriese/.julia/v0.4/MPILib/src/Examples/Testdata/createdOneSphere60-6111.jld")
sphere=createSphere["sphereImage"]
center=createSphere["centerPixel"]
oneSphere=load("/home/fgriese/.julia/v0.4/MPILib/src/Examples/Testdata/oneSphere.jld","oneSphere")
# onSphere center recognition visible (28.5, 8, 5.5)
threeSphere=load("/home/fgriese/.julia/v0.4/MPILib/src/Examples/Testdata/threeSphere.jld","threeSphere")
#prefix="createdOneSphere"
#prefix="oneSphere"
prefix="sphere"
v=sphere
println("loading Time:")
toc()

println("Gauß and Sobel filtering...")
tic()
# Gauß Filter
k=1
sigma = [1 2]
vGauß = Images.imfilter_gaussian(v, [sigma[k], sigma[k], sigma[k]])

# Sobel Filter
vSobel = sobelFilter3D(vGauß)
GaußSobelname="$(prefix)GaußSobel.jld"
#save("$(savePath)$(GaußSobelname)", "vGauß", vGauß, "vSobel", vSobel)
#run(`scp -r $(savePath)$(filename) fgriese@10.168.21.117:/home/fgriese/Documents/HoughStudies/`)
println("Gauß and Sobel Filter Time:")
toc()

println("Hysterese filtering")
tic()
Hysteresename="$(prefix)Hysterese.jld"
vFilterHysterese=vSobel
vFilterHysterese=adjust2gray0255(vFilterHysterese)
indmin=find(x->(x<50), vFilterHysterese)
vFilterHysterese[indmin]=0.0
indmax=find(x->(x>50),vFilterHysterese)
println("Number of voxel: $(length(indmax))")
#save("$(savePath)$(Hysteresename)", "vFilterHysterese", vFilterHysterese)
println("Hysterese filter Time:")
toc()

println("3D-Hough-Transformation...")
abcSpaceName="createdOneSphereabcSpace.jld"
radius=6.5
tic()
abcSpace = houghTransformationSphere(vFilterHysterese,radius,25)
#save("$(savePath)$(abcSpaceName)", "abcSpace", abcSpace)
println("3D-Hough-Transformation Time:")
toc()

tic()
println("Conversion to houghSpace...")
houghSpaceName="$(prefix)HoughSpace.jld"
houghSpace=zeros(size(abcSpace)[1],size(abcSpace)[2],size(abcSpace)[3])
# inds=find(abcSpace[4])
# houghSpace[inds]=abcSpace[inds][4]
for k=1:size(abcSpace)[1]
  for l=1:size(abcSpace)[2]
    for m=1:size(abcSpace)[3]
      houghSpace[k,l,m]=abcSpace[k,l,m][4];
    end
  end
end
println("Conversion to houghSpace Time:")
save("$(savePath)$(houghSpaceName)", "houghSpace", houghSpace)
toc()

println("Find maxima")
tic()
maximaName="$(prefix)Maxima.jld"
num=5
maxima = getmaxima(houghSpace,num)
centers=Array(Tuple, num, num, num)
for i=1:size(maxima)[1]
  (k,l,m)=ind2sub(houghSpace,convert(Int64,maxima[i,2]))
  println(abcSpace[k,l,m])
  centers
end
save("$(savePath)$(maximaName)", "maxima", maxima)
println("Find maxima Time:")
toc()
