export CircleFunction, SphereFunction, GetFOVSize, GetFOVDriveFieldSize, getmaxima,
adjust2gray0255, volumeRendering4D, volumeRendering3D, plot3DoverTime, sobelFilter3D,
getminima, createSphere

@doc "Function can be placed here..."
function CircleFunction(x,radius)
    f=[radius*cos(x) radius*sin(x)]
    return f
end

@doc "theta von 0:2*pi und rho von 0:2*pi"->
function SphereFunction(theta,rho,radius)
  # if (!(0<theta<pi))
  #   error("theta is bigger than pi or smaller than 0")
  # end
  # if (!(0<phi<2*pi))
  #   error("phi is bigger than 2* pi or smaller than 0")
  # end
    f=[radius.*cos(theta).*sin(rho) radius.*sin(theta).*sin(rho) radius.*cos(rho)]
    return f
end


@doc "Calc FOV in mm, `amplitude` in mT [A_x A_y A_z] und `gradient` in T/m
[G_x G_y G_z]"->
function GetFOVSize(amplitude::Vector,gradient::Vector)
    fov=2*amplitude./gradient;
    return vec(fov);
end

@doc "Calc FOV in mm, `amplitude` in mT [A_x A_y A_z], `amplitudeFF` in mT
[AFF_x,AFF_y AFF_z] `gradient` in T/m [G_x G_y G_z]"->
function GetFOVDriveFieldSize(amplitude::Vector,amplitudeFF::Vector,gradient::Vector)
    fovFF=2*(amplitudeFF+amplitude)./gradient;
    return vec(fovFF);
end

@doc "Render 3D data"->
function volumeRendering3D(Data)
  window = glscreen()
  volume = visualize(Data)
  view(volume, window)
  renderloop(window)
end

@doc "get maxima"->
function getmaxima(data3D, num)
  data = copy(data3D);
  dim = length(size(data))
  maxima=zeros(num, dim+2)

  for k=1:num
    (max,ind) = findmax(data)
    if dim==3
      (indx ,indy, indz) = ind2sub(data, ind)
      maxima[k,:]=[max, ind, indx, indy, indz]
      data[indx,indy,indz]=0.0
    end
    if dim==2
      (indx ,indy) = ind2sub(data, ind)
      maxima[k,:]=[max, ind, indx, indy]
      data[indx,indy]=0.0
    end
  end
  maxima
end

function getmaxima{K,V}(d::Dict{K,V})
  value,index=findmax(collect(values(d)))
  tuple = collect(keys(d))[index]
  tuple, value
end

function getmaxima{K,V}(d::Dict{K,V}, num; suppressRadius=0)
  dcopy = copy(d);
  maxima=Dict{K,V}()
  for k=1:length(d)
    value,index=findmax(collect(values(dcopy)))
    tuple = collect(keys(dcopy))[index]
    tuple, value
    if suppressRadius==0
      maxima[tuple]=value
    else
      if k==1
        maxima[tuple]=value
      end
      isAdd=false
      for key in keys(maxima)
        if abs(tuple[2]-key[2])<=suppressRadius &&  abs(tuple[3]-key[3])<=suppressRadius &&  abs(tuple[4]-key[4]) <= suppressRadius
          isAdd=false
          break
        else
          isAdd=true
        end
      end
      if isAdd
        maxima[tuple]=value
      end
    end
    delete!(dcopy, tuple)
    if length(maxima)==num
      return maxima
    end

  end
  maxima
end



@doc "get minima"->
function getminima(data3D, num)
  data = copy(data3D);
  dim = length(size(data))
  minima=zeros(num, dim+2)

  for k=1:num
    (min,ind) = findmin(data)
    if dim==3
      (indx ,indy, indz) = ind2sub(data, ind)
      minima[k,:]=[min, ind, indx, indy, indz]
      data[indx,indy,indz]=typemax(eltype(data))
    end
    if dim==2
      (indx ,indy) = ind2sub(data, ind)
      minima[k,:]=[min, ind, indx, indy]
      data[indx,indy]=typemax(eltype(data))
    end
  end
  minima
end

@doc "Adjust to gray value between 0-255"->
function adjust2gray0255{T<:Real}(image::Array{T,2})
  max=maximum(image);
  min=minimum(image);
  res=255*(image-min)/(max-min)
end

@doc "Adjust to gray value between 0-255"->
function adjust2gray0255{T<:Real}(image::Array{T,3})
  max=maximum(image);
  min=minimum(image);
  res=255*(image-min)/(max-min)
end

@doc "Render 3D Volume data over time expecting Array x,y,z,t
repeats 10 time cycles"->
function volumeRendering4D(data; repetions=10)

  window = glscreen()
  volumedata = data[:,:,:,1];
  vol = Signal(volumedata);
  timeFrames = size(data)[4]
  outer_task = current_task()
  task=@async begin
  try
    # show time cycle 10 times
    for o=1:repetions
      for k=1:timeFrames
        push!(vol, data[:,:,:,k];)
        sleep(0.05)
      end
    end
  catch e
    Base.throwto(outer_task, CapturedException(e, catch_backtrace()))
  end
  end

  volume = visualize(vol)
  view(volume, window)
  renderloop(window)
end

@doc "Plot3D x,y,z data over time"->
function plot3DoverTime(data; isContinues::Bool=true, fignum=1000, repetions=10)
  timeFrames=size(data)[1]
  outer_task=current_task()
  task= @async begin
    try
      figure(fignum)
      for o=1:repetions
        for k=1:timeFrames
          # plot3D is not abled to plot a single point, therefore plot two times the same point
          ax=gca(projection="3d")
          plot3D([data[k,1]; data[k,1]], [data[k,2]; data[k,2]], [data[k,3]; data[k,3]], "*", color="red")
          ax[:set_xlim]([minimum(data[:,1]),maximum(data[:,1])])
          ax[:set_ylim]([minimum(data[:,2]),maximum(data[:,2])])
          ax[:set_zlim]([minimum(data[:,3]),maximum(data[:,3])])
          sleep(0.05)
          if !isContinues
            clf()
          end
        end
        clf()
      end
    catch e
      Base.throwto(outer_task, CapturedException(e, catch_backtrace()))
    end
  end
end

@doc "Render 3D Volume data expecting x,y,z"->
function volumeRendering3D(data)
  window = glscreen()
  volume = visualize(data)
  view(volume, window)
  renderloop(window)
end

function sobelFilter2D(image)
  SX=[1 0 -1; 2 0 -2; 1 0 -1]
  SY=[1 2 1; 0 0 0; -1 -2 -1]
  sobX=Images.imfilter(image,SX*1/8)
  sobY=Images.imfilter(image,SY*1/8)
  sobXY=sqrt(sobX.^2+sobY.^2)
  return sobXY,sobX,sobY
end

@doc "Sobel Filter 3D"->
function sobelFilter3D(volume; factor=2)
  plusMatrix=[1 factor 1; factor 2*factor factor; 1 factor 1]
  zeroMatrix=zeros(3,3)
  minusMatrix=[-1 -factor -1; -factor -2*factor -factor; -1 -factor -1]
  #normalizeFactor=(1/sum(plusMatrix))
  normalizeFactor=(1/32)

  sobelX=zeros(3,3,3)
  sobelX[1,:,:]=plusMatrix
  sobelX[2,:,:]=zeroMatrix
  sobelX[3,:,:]=minusMatrix
  # normalize
  sobelX=sobelX * normalizeFactor
  sobelY=zeros(3,3,3)
  sobelY[:,1,:]=plusMatrix
  sobelY[:,2,:]=zeroMatrix
  sobelY[:,3,:]=minusMatrix
  # normalize
  sobelY=sobelY * normalizeFactor
  sobelZ=zeros(3,3,3)
  sobelZ[:,:,1]=plusMatrix
  sobelZ[:,:,2]=zeroMatrix
  sobelZ[:,:,3]=minusMatrix
  # normalize
  sobelZ=sobelZ * normalizeFactor

  sobX=Images.imfilter(volume,sobelX)
  sobY=Images.imfilter(volume,sobelY)
  sobZ=Images.imfilter(volume,sobelZ)

  sobXYZ=sqrt(sobX.^2+sobY.^2+sobZ.^2)
  return sobXYZ,sobX,sobY,sobZ
end

function printDict{K,V}(d::Dict{K,V})
  for element in d
    println(element)
  end
end
@doc "size in pixel [x y z], radius in mm, moveXYZ in mm, pixelSpacing in mm"->
function createSphere(size, radius, moveXYZ, pixelSpacing, numPointsAngles)
  xSize=size[1];
  ySize=size[2];
  zSize=size[3];
  sphereImage=zeros(xSize,ySize,zSize);
  # Discretization angles for sphere
  theta=linspace(0,2*pi,2*numPointsAngles)
  rho=linspace(0,pi,numPointsAngles)

  grid_a = vec(broadcast((x,y) -> x, theta, rho'))
  grid_b = vec(broadcast((x,y) -> y, theta, rho'))

  radi=linspace(0,radius,10)

  # move center of sphere to the center of image
  xMove=(xSize/2)*pixelSpacing[1]+moveXYZ[1]
  yMove=(ySize/2)*pixelSpacing[2]+moveXYZ[2]
  zMove=(zSize/2)*pixelSpacing[3]+moveXYZ[3]

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
        sphereImage[xIndex,yIndex,zIndex]=1
    end
  end
  centerxPixel=(xSize/2)+moveXYZ[1]
  centeryPixel=(ySize/2)+moveXYZ[2]
  centerzPixel=(zSize/2)+moveXYZ[3]
  centerxMM=xMove
  centeryMM=yMove
  centerzMM=zMove
  centerPixel=[centerxPixel, centeryPixel, centerzPixel]
  centerMM=[centerxMM, centeryMM, centerzMM]
  sphereImageDisp=Images.Image(sphereImage)
  sphereImageDisp.properties["center"]=centerPixel
  sphereImageDisp.properties["pixelspacing"]=pixelspacing
  sphereImageDisp.properties["radius"]=radius
  sphereImageDisp.properties["move"]=moveXYZ
  return sphereImageDisp
end

function SaveAndCopyImg(img, fileName; localSavePath="/home/fgriese/Documents/HoughStudiesSphere3D")
  prefix=Dates.format(now(Dates.UTC),"yyyymmdd_HHMMSS_sss");
  filePath="Testdata/$(prefix)_$(fileName).jld"
  save(filePath,  "img", img)
  run(`scp -r $(filePath) fgriese@10.168.21.117:$(localSavePath)`)
end

function saveAndCopyImgToReco(niiFilename,saveName)
  prefix=Dates.format(now(Dates.UTC),"yyyymmdd_HHMMSS_sss");
  img=loaddata_analyze(niiFilename)
  save("Testdata/Nifti/$(prefix)_$(saveName).jld", "img", img)
end

function convertToCenterArray{K,V}(d::Dict{K,V})
    centers=zeros(length(d),3)
    i=1
    for key in keys(d)
      centers[i,:]=[key[2] key[3] key[4]]
      i=i+1
    end
    centers
end
