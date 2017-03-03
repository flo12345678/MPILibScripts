using MPILib
using GLAbstraction, GeometryTypes, GLWindow, GLVisualize
include("Functions.jl")
close("all")

tic()
pixelSpacing=[1 1 1];
xSize=50;
ySize=40;
zSize=30;
sphereImage=zeros(xSize,ySize,zSize);

numberOfPoints=500;
#sphere function
theta=linspace(0,2*pi,2*numberOfPoints)
rho=linspace(0,pi,numberOfPoints)

grid_a = vec(broadcast((x,y) -> x, theta, rho'))
grid_b = vec(broadcast((x,y) -> y, theta, rho'))

radius=6
#sphere=SphereFunction(grid_a,grid_b, 1)
radi=collect(0.5:0.5:radius)
#radius=1.425
# sphere=SphereFunction(grid_a,grid_b, 0.1)
# radi=collect(0.2:0.1:radius);

# moving in the middle of Image
relmovex=0 #in mm
relmovey=0 #in mm
relmovez=0#in mm
xMove=(xSize/2)*pixelSpacing[1]+relmovex
yMove=(ySize/2)*pixelSpacing[2]+relmovey
zMove=(zSize/2)*pixelSpacing[3]+relmovez

for i=1:length(radi)
  sphereTemp=SphereFunction(grid_a, grid_b, radi[i])
  xSphere=sphereTemp[:,1]
  ySphere=sphereTemp[:,2]
  zSphere=sphereTemp[:,3]
  xSphereMove=xSphere+xMove
  ySphereMove=ySphere+yMove
  zSphereMove=zSphere+zMove
  xSpherePixel=xSphereMove/pixelSpacing[1]
  ySpherePixel=ySphereMove/pixelSpacing[2]
  zSpherePixel=zSphereMove/pixelSpacing[3]
  xSpherePixelRound=round(Int64,xSpherePixel,RoundNearestTiesAway)
  ySpherePixelRound=round(Int64,ySpherePixel,RoundNearestTiesAway)
  zSpherePixelRound=round(Int64,zSpherePixel,RoundNearestTiesAway)
  for k=1:length(xSpherePixelRound)
      xIndex=convert(Int64,xSpherePixelRound[k])
      yIndex=convert(Int64,ySpherePixelRound[k])
      zIndex=convert(Int64,zSpherePixelRound[k])
      sphereImage[xIndex,yIndex,zIndex]=1/sqrt(radi[i])
  end
  #sphere=cat(1, sphere, sphereTemp)
end

# xSphere=sphere[:,1]
# ySphere=sphere[:,2]
# zSphere=sphere[:,3]


# figure(1000)
# ax = gca(projection="3d")
# plot3D(xSphere,ySphere,zSphere, "*", color="red")



centerxPixel=(xSize/2)+relmovex
centeryPixel=(ySize/2)+relmovey
centerzPixel=(zSize/2)+relmovez
centerxMM=xMove
centeryMM=yMove
centerzMM=zMove
centerPixel=[centerxPixel, centeryPixel, centerzPixel]
centerMM=[centerxMM, centeryMM, centerzMM]

# xSphereMove=xSphere+xMove
# ySphereMove=ySphere+yMove
# zSphereMove=zSphere+zMove
# figure(1001)
# ax = gca(projection="3d")
# plot3D(xSphereMove,ySphereMove,zSphereMove, "*", color="blue")

# xSpherePixel=xSphereMove/pixelSpacing[1]
# ySpherePixel=ySphereMove/pixelSpacing[2]
# zSpherePixel=zSphereMove/pixelSpacing[3]

# figure(1002)
# ax = gca(projection="3d")
# plot3D(xSpherePixel,ySpherePixel,zSpherePixel, "*", color="blue")

# xSpherePixelRound=round(Int64,xSpherePixel,RoundNearestTiesAway)
# ySpherePixelRound=round(Int64,ySpherePixel,RoundNearestTiesAway)
# zSpherePixelRound=round(Int64,zSpherePixel,RoundNearestTiesAway)
#
# for i=1:length(xSpherePixelRound)
#     xIndex=convert(Int64,xSpherePixelRound[i])
#     yIndex=convert(Int64,ySpherePixelRound[i])
#     zIndex=convert(Int64,zSpherePixelRound[i])
#     sphereImage[xIndex,yIndex,zIndex]=1
# end
sphereImageDisp=Images.Image(sphereImage)

#@async volumeRendering3D(sphereImage)
# create julia data files
save("Testdata/createdOneSphere$(radius)$(relmovex)$(relmovey)$(relmovez)$(pixelSpacing[1])$(pixelSpacing[2])$(pixelSpacing[3]).jld",
 "sphereImage", sphereImage, "centerPixel", centerPixel, "pixelSpacing", pixelSpacing,
 "radius", radius)
toc()
