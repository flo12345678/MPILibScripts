using MPILib
using Images
using Plots

using GLAbstraction, GeometryTypes, GLWindow, GLVisualize
using Reactive

# load volume/images
data4D=loaddata_analyze("/home/fgriese/Documents/Daten/MPIData/Measurements/RobotMoveCube/MovingCube20x20x10_0001.nii");
pixelSpacing=data4D.properties["pixelspacing"]*1000 # Convert to millimeter
data4D=data4D[:,:,:,750:1250];
dimx=size(data4D)[1]
dimy=size(data4D)[2]
dimz=size(data4D)[3]
dimt=size(data4D)[4]

numOfMaxima=3;
maximadata4D=zeros(dimx,dimy,dimz,dimt);
centerofmassdata4D=zeros(dimt,3);

for k=1:size(data4D)[4]
  maxima=getmaxima(data4D[:,:,:,k],numOfMaxima)
  xindices=convert(Array{Int64,1},maxima[:,3])
  yindices=convert(Array{Int64,1},maxima[:,4])
  zindices=convert(Array{Int64,1},maxima[:,5])
  for l=1:length(xindices)
    maximadata4D[xindices[l],yindices[l],zindices[l],k]=maxima[l,1]
  end
  centerofmassdata4D[k,:]=MPILib.centerOfMass(squeeze(maximadata4D[:,:,:,k]))
end

@async volumeRendering4D(maximadata4D)

#plotlyjs()
gr()
#pyplot()
# Plots.plot(centerofmassdata4D[:,1],centerofmassdata4D[:,2],centerofmassdata4D[:,3], color="red")
# gui()

plot3DoverTime(centerofmassdata4D, isContinues=false)
