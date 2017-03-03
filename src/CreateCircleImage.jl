using MPILib
include("Functions.jl")
include("HoughTransformCircle2D.jl")
include("HoughTransformCircle2DDirection.jl")
include("HoughTransformCircle2DScale.jl")
close("all")
prefix="/home/fgriese/ownCloud/Organisation/OwnPresentations/2016/20160830ReneFragen/images/"
pixelSpacing=[1 2];
xSize=60;
ySize=50;
circleImage=zeros(xSize,ySize);

numberOfPoints=200;
x=linspace(0,2*pi,numberOfPoints)

radius=6;
radi=collect(0.1:0.1:radius)
circle=[0 0]
for i=1:length(radi)
  circleTemp=CircleFunction(x,radi[i])
  circle=cat(1, circle, circleTemp)
end
xCircle=circle[:,1]
yCircle=circle[:,2]
figure(1000)
plot(xCircle,yCircle,"*",color="red")

# moving in the middle of Image
relmovex=0.25 #in mm
relmovey=0.25 #in mm
xMove=(xSize/2)*pixelSpacing[1]+relmovex
yMove=(ySize/2)*pixelSpacing[2]+relmovey

xCircleMove=xCircle+xMove
yCircleMove=yCircle+yMove
figure(1001)
plot(xCircleMove,yCircleMove,"*",color="blue")

xCirclePixel=xCircleMove/pixelSpacing[1]
yCirclePixel=yCircleMove/pixelSpacing[2]
figure(1002)
plot(xCircleMove,yCircleMove,"*",color="green")

xCirclePixelRound=round(Int64,xCirclePixel,RoundNearestTiesAway)
yCirclePixelRound=round(Int64,yCirclePixel,RoundNearestTiesAway)

for i=1:length(xCirclePixelRound)
    xIndex=convert(Int64,xCirclePixelRound[i])
    yIndex=convert(Int64,yCirclePixelRound[i])
    circleImage[xIndex,yIndex]=1
end

# for i=1:length(xCirclePixelRound)
#     xIndex=convert(Int64,xCirclePixelRound[i]+20)
#     yIndex=convert(Int64,yCirclePixelRound[i]+25)
#     circleImage[xIndex,yIndex]=1
# end

figure(2000)
imshow(circleImage,cmap=ColorMap("gray"),interpolation="none")
v=circleImage
savefig("$(prefix)OrigCircle2D$(radius)$(relmovex)$(relmovey)$(pixelSpacing[1])$(pixelSpacing[2]).png")
################################################################################
# Segementation
println("Gauß and Sobel filtering...")
tic()
# Gauß Filter
# k=1
# sigma = [1 2]
# vGauß = Images.imfilter_gaussian(v, [sigma[k], sigma[k], sigma[k]])

# Sobel Filter
vSobel,sobX,sobY = sobelFilter2D(v)
figure(2001)
imshow(vSobel,cmap=ColorMap("gray"),interpolation="none")
savefig("$(prefix)SobelCircle2D$(radius)$(relmovex)$(relmovey)$(pixelSpacing[1])$(pixelSpacing[2]).png")
GaußSobelname="$(prefix)GaußSobel.jld"
sobel=Images.Image(vSobel)
#gauß=Images.Image(vGauß)
#save("$(savePath)$(GaußSobelname)", "vGauß", vGauß, "vSobel", vSobel)
#run(`scp -r $(savePath)$(filename) fgriese@10.168.21.117:/home/fgriese/Documents/HoughStudies/`)
println("Gauß and Sobel Filter Time:")
toc()

println("Hysterese filtering")
tic()
Hysteresename="$(prefix)Hysterese.jld"
vFilterHysterese=vSobel
#vFilterHysterese=adjust2gray0255(vFilterHysterese)
# 20 % cut off Filter
cutOff=maximum(vFilterHysterese)*0.2
indmin=find(x->(x<cutOff), vFilterHysterese)
vFilterHysterese[indmin]=0.0
indmax=find(x->(x>cutOff),vFilterHysterese)
println("Number of voxel: $(length(indmax))")
#save("$(savePath)$(Hysteresename)", "vFilterHysterese", vFilterHysterese)
hyster=Images.Image(vFilterHysterese)
figure(2001)
imshow(vFilterHysterese,cmap=ColorMap("gray"),interpolation="none")
save("$(prefix)HystereseCircle2D$(radius)$(relmovex)$(relmovey)$(pixelSpacing[1])$(pixelSpacing[2])Raw.png",grayim(vFilterHysterese))
savefig("$(prefix)HystereseCircle2D$(radius)$(relmovex)$(relmovey)$(pixelSpacing[1])$(pixelSpacing[2]).png")
println("Hysterese filter Time:")
toc()

tic()
rounddigit=0
discreteTheta=10000
scale=1
accu,accuValue=houghTransformCircle2D(vFilterHysterese, collect(radius),discreteTheta, pixelSpacing, rounddigit=rounddigit)
accuDirect,accuValueDirection=houghTransformCircle2DDirection(vFilterHysterese,collect(radius),pixelSpacing, vSobel, sobX, sobY, rounddigit=rounddigit)
radiusScale=[radius/pixelSpacing[1] radius/pixelSpacing[2]]
houghSpaceScale,houghSpaceScaleValue=houghTransformCircle2DScale(vFilterHysterese, radiusScale, discreteTheta, scale)
maxi3=getmaxima(accu,3)
maxi3Value=getmaxima(accuValue,3)
maxi9=getmaxima(accu,9)
maxi9Value=getmaxima(accuValue,9)
toc()
println("Top 3 Maxima")
printDict(maxi3)
#printDict(maxi3Value)
println("Top 9 Maxima")
printDict(maxi9)
#printDict(maxi9Value)
maxiDirect3=getmaxima(accuDirect,3)
println("Top 3 Maxima Direct")
printDict(maxiDirect3)
# create Hough Image
disfact=10^rounddigit
houghImage=zeros(convert(Int64,size(v,1)*disfact*pixelSpacing[1]),convert(Int64,size(v,2)*disfact*pixelSpacing[2]))
for tuple in accu
  xind=convert(Int64,tuple[1][2]*disfact)
  yind=convert(Int64,tuple[1][3]*disfact)
  value=tuple[2]
  houghImage[xind,yind]=value
end
figure(2002)
imshow(houghImage,cmap=ColorMap("gray"),interpolation="none")
savefig("$(prefix)HoughSpaceCircle2D$(radius)$(relmovex)$(relmovey)$(pixelSpacing[1])$(pixelSpacing[2])$(rounddigit).png")

houghImageDirect=zeros(convert(Int64,size(v,1)*disfact*pixelSpacing[1]),convert(Int64,size(v,2)*disfact*pixelSpacing[2]))
for tuple in accuDirect
  xind=convert(Int64,tuple[1][2]*disfact)
  yind=convert(Int64,tuple[1][3]*disfact)
  value=tuple[2]
  houghImageDirect[xind,yind]=value
end
figure(2003)
imshow(houghImageDirect,cmap=ColorMap("gray"),interpolation="none")
savefig("$(prefix)HoughSpaceCircle2DDirect$(radius)$(relmovex)$(relmovey)$(pixelSpacing[1])$(pixelSpacing[2])$(rounddigit).png")


figure(2004)
imshow(squeeze(houghSpaceScale), cmap=ColorMap("gray"), interpolation="none")
savefig("$(prefix)HoughSpaceCircle2DScale$(radius)$(relmovex)$(relmovey)$(pixelSpacing[1])$(pixelSpacing[2])$(scale).png")
println("Top 3 Scale HoughSpace")
scaleMaxima=getmaxima(houghSpaceScale,3)
scaleMaxima[:,3]=scaleMaxima[:,3]*pixelSpacing[1]
scaleMaxima[:,4]=scaleMaxima[:,4]*pixelSpacing[2]
println(scaleMaxima)
