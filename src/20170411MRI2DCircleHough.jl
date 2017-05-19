ENV["MPILIB_UI"]="Gtk"
using MPILib
using PyCall
using PyPlot
using Plots
using Combinatorics
using JLD

@pyimport skimage.transform as transform
@pyimport skimage.feature as cannyAlg
@pyimport numpy as np
@pyimport skimage.draw as drawJulia
@pyimport skimage.util as img_as_ubyte
@pyimport skimage.color as colorSkimage
@pyimport matplotlib.pyplot as pltJulia
#cv2 = pyimport("cv2") install first long way
#http://docs.opencv.org/trunk/d7/d9f/tutorial_linux_install.html
# cmake-gui

close("all")

mriPath = joinpath("/home/griese//Desktop/20160901SphereFID/","FID_test_04_20160901_009_T2st_0TE77_48TR_sag_0001.dcm")
mri = loaddata_dicom(mriPath)
mriPixelSpacing = [pixelspacing(mri)...]*1000
mriSize = [size(mri)...]
# showMultiImages(mri, 1)
d_SphMax_mm = 2.9
r_SphMax_mm = d_SphMax_mm/2
r_SphMax_pix = r_SphMax_mm/mriPixelSpacing[2]
d_SphL1_mm = d_SphMax_mm - mriPixelSpacing[1] # sliceThickness is not taken into account
r_SphL1_mm = d_SphL1_mm/2
r_SphL1_pix = r_SphL1_mm/mriPixelSpacing[2]
d_SphL2_mm = d_SphL1_mm - mriPixelSpacing[1] # sliceThickness is not taken into account
r_SphL2_mm = d_SphL2_mm/2
r_SphL2_pix = r_SphL2_mm/mriPixelSpacing[2]

toleranceMax = 0.1
toleranceL1 = 0.1
toleranceL2 = 0.1

sigma = 3
low_threshold=10
high_threshold=50
radiusStep=0.1
peaks = 5
cToleranceX_vox =2
cToleranceY_vox =cToleranceX_vox
rawMRI = data(mri).data;

oneSlice = rawMRI[5,:,:];
#showImage(oneSlice, fignum=1)
# fig, ax = subplots(ncols=1, nrows=1)
# oneSliceColor = colorSkimage.gray2rgb(oneSlice)
# for k=1#:length(cx)
#     circy, circx = drawJulia.circle_perimeter(50, 50, 9)
#     println(circy,typeof(circy),size(circy))
#     println(circx,typeof(circx),size(circx))
#     for l=1:length(circy)
#       oneSliceColor[circx[l], circy[l],1] = 220
#       oneSliceColor[circx[l], circy[l],2] = 20
#       oneSliceColor[circx[l], circy[l],3] = 20
#     end
# end
#imshow(oneSliceColor, cmap="gray")

stackSize = size(rawMRI,1)

type SliceMeta
  index::Int64
  accums
  cx
  cy
  radii
  maxAccum
  maxIndex
  parent
  childPlus
  childMinus
  SliceMeta(index,accums,cx,cy,radii,maxAccum,maxIndex)=new(index,accums,cx,cy,radii,maxAccum,maxIndex,nothing,nothing,nothing)
end

stack = Array{Nullable{SliceMeta},1}(stackSize)
sliceCanny=0
# first Level
for k=1:stackSize
  sliceCannyMask = cannyAlg.canny(rawMRI[k,:,:], sigma=sigma, low_threshold=low_threshold, high_threshold=high_threshold)
  #showImage(sliceCanny, fignum=k)

  hough_radii = np.arange(r_SphMax_pix - toleranceMax, r_SphMax_pix + toleranceMax, radiusStep)
  hough_res = transform.hough_circle(sliceCannyMask, hough_radii)

  # Select the most prominent 5 circles
  accums, cx, cy, radii = transform.hough_circle_peaks(hough_res, hough_radii, total_num_peaks=peaks)
  if length(accums)!= 0
    maxValue, maxIndex = findmax(accums)
    sliceMeta = SliceMeta(k, accums, cx, cy, radii, maxValue, maxIndex)
    sliceMeta.parent=nothing

    stack[k]=Nullable(sliceMeta)
    println("index:", sliceMeta.index," cx:",sliceMeta.cx," cy:",sliceMeta.cy," radii:",sliceMeta.radii," maxValue:",sliceMeta.maxAccum," maxIndex:",sliceMeta.maxIndex)
    #fig, ax = subplots(ncols=1, nrows=1)
    # figure(k)
    # #sliceCannyColor = colorSkimage.gray2rgb(rawMRI[k,:,:])
    # sliceCanny=convert(Array{Float64,2},sliceCannyMask)
    # sliceCannyColor = colorSkimage.gray2rgb(sliceCanny)
    # if maxIndex!= zero(0)
    #   #convert(Int64,floor(radii[maxIndex]))
    #   #println("radius:", radii[maxIndex],"floorradius_vox:", convert(Int64,floor(radii[maxIndex])))
    #   circy, circx = drawJulia.circle_perimeter(cx[maxIndex], cy[maxIndex], convert(Int64,floor(radii[maxIndex])))
    #   #println(circy,typeof(circy),size(circy))
    #   #println(circx,typeof(circx),size(circx))
    #   for l=1:length(circy)
    #       sliceCannyColor[circx[l], circy[l],1] = 220
    #       sliceCannyColor[circx[l], circy[l],2] = 20
    #       sliceCannyColor[circx[l], circy[l],3] = 20
    #   end
    # end
    # imshow(sliceCannyColor, cmap="gray")
  else
    stack[k]=Nullable{SliceMeta}()
  end
end



# second level
for k=1:stackSize
  if !isnull(stack[k])
    slice=stack[k].value

    # second level search plus one
    if k+1 <= stackSize
      sliceCannyMask = cannyAlg.canny(rawMRI[k+1,:,:], sigma=sigma, low_threshold=low_threshold, high_threshold=high_threshold)
      hough_radii = np.arange(r_SphL1_pix - toleranceMax, r_SphL1_pix + toleranceMax, radiusStep)
      hough_res = transform.hough_circle(sliceCannyMask, hough_radii)
      accums, cx, cy, radii = transform.hough_circle_peaks(hough_res, hough_radii, total_num_peaks=peaks)
      if length(accums)!= 0
        if length(accums)!= 0
          cxOrtho=Array{Int64,1}()
          cyOrtho=Array{Int64,1}()
          accumsOrtho =Array{Float64,1}()
          radiiOrtho =Array{Float64,1}()
          cxOrthoParent=Array{Int64,1}()
          cyOrthoParent=Array{Int64,1}()
          accumsOrthoParent =Array{Float64,1}()
          radiiOrthoParent =Array{Float64,1}()
          for l=1:length(cx)
            for m=1:length(slice.cx)
              if abs(cx[l]-slice.cx[m])<=cToleranceX_vox && abs(cy[l]-slice.cy[m])<=cToleranceY_vox
                push!(cxOrtho,cx[l])
                push!(cyOrtho,cy[l])
                push!(accumsOrtho,accums[l])
                push!(radiiOrtho,radii[l])
                push!(cxOrthoParent,slice.cx[m])
                push!(cyOrthoParent,slice.cy[m])
                push!(accumsOrthoParent,slice.accums[m])
                push!(radiiOrthoParent,slice.radii[m])
              end
            end
          end
          if length(accumsOrtho)!= 0
            maxValue, maxIndex = findmax(accumsOrtho)
            slicePlus=SliceMeta(k+1, accumsOrtho, cxOrtho, cyOrtho, radiiOrtho, maxValue, maxIndex)
            slice.cx =cxOrthoParent
            slice.cy =cyOrthoParent
            slice.accums =accumsOrthoParent
            slice.radii =radiiOrthoParent
            slicePlus.parent = slice
            slice.childPlus = slicePlus
          end
        end
      end

    end

    #second level search minus one
    if k-1 > 0
      sliceCannyMask = cannyAlg.canny(rawMRI[k-1,:,:], sigma=sigma, low_threshold=low_threshold, high_threshold=high_threshold)
      hough_radii = np.arange(r_SphL1_pix - toleranceMax, r_SphL1_pix + toleranceMax, radiusStep)
      hough_res = transform.hough_circle(sliceCannyMask, hough_radii)
      accums, cx, cy, radii = transform.hough_circle_peaks(hough_res, hough_radii, total_num_peaks=peaks)
      if length(accums)!= 0
        cxOrtho=Array{Int64,1}()
        cyOrtho=Array{Int64,1}()
        accumsOrtho =Array{Float64,1}()
        radiiOrtho =Array{Float64,1}()
        cxOrthoParent=Array{Int64,1}()
        cyOrthoParent=Array{Int64,1}()
        accumsOrthoParent =Array{Float64,1}()
        radiiOrthoParent =Array{Float64,1}()
        for l=1:length(cx)
          for m=1:length(slice.cx)
            if abs(cx[l]-slice.cx[m])<=cToleranceX_vox && abs(cy[l]-slice.cy[m])<=cToleranceY_vox
              push!(cxOrtho,cx[l])
              push!(cyOrtho,cy[l])
              push!(accumsOrtho,accums[l])
              push!(radiiOrtho,radii[l])
              push!(cxOrthoParent,slice.cx[m])
              push!(cyOrthoParent,slice.cy[m])
              push!(accumsOrthoParent,slice.accums[m])
              push!(radiiOrthoParent,slice.radii[m])
            end
          end
        end
        if length(accumsOrtho)!= 0
          maxValue, maxIndex = findmax(accumsOrtho)
          sliceMinus=SliceMeta(k-1, accumsOrtho, cxOrtho, cyOrtho, radiiOrtho, maxValue, maxIndex)
          slice.cx =cat(1,slice.cx,cxOrthoParent)
          slice.cy =cat(1,slice.cy,cyOrthoParent)
          slice.accums =cat(1,slice.accums,accumsOrthoParent)
          slice.radii =cat(1,slice.radii,radiiOrthoParent)
          slicePlus.parent = slice
          slice.childMinus = sliceMinus
        end
      end
    end
    maxValue, maxIndex = findmax(slice.accums)
    slice.maxAccum=maxValue
    slice.maxIndex=maxIndex
    stack[k] = Nullable(slice)
  end #end if
end #end for

# filter stack after second level
twoChildsStack=Array{Nullable{SliceMeta},1}()
oneChildsStack=Array{Nullable{SliceMeta},1}()
for k=1:stackSize
  if !isnull(stack[k])
    slice=stack[k].value
    if slice.childPlus!=nothing && slice.childMinus!=nothing
      push!(twoChildsStack,slice)
    elseif slice.childPlus!=nothing || slice.childMinus!=nothing
      push!(oneChildsStack,slice)
    end
  end
end

# show candidates
for cand in twoChildsStack
  c=cand.value
  figure(c.index*100+2)
  sliceColor = colorSkimage.gray2rgb(rawMRI[c.index,:,:])
  sliceColor[c.cy[c.maxIndex], c.cx[c.maxIndex],1] = 1
  sliceColor[c.cy[c.maxIndex], c.cx[c.maxIndex],2] = 255
  sliceColor[c.cy[c.maxIndex], c.cx[c.maxIndex],3] = 1

  circx, circy = drawJulia.circle_perimeter(c.cy[c.maxIndex],c.cx[c.maxIndex], convert(Int64,floor(c.radii[c.maxIndex])))
  for l=1:length(circy)
      sliceColor[circx[l], circy[l],1] = 1
      sliceColor[circx[l], circy[l],2] = 255
      sliceColor[circx[l], circy[l],3] = 1
  end
  imshow(sliceColor, cmap="gray")

  cP=c.childPlus
  figure(c.index*100+3)
  sliceColor = colorSkimage.gray2rgb(rawMRI[cP.index,:,:])
  sliceColor[cP.cy[cP.maxIndex], cP.cx[cP.maxIndex],1] = 1
  sliceColor[cP.cy[cP.maxIndex], cP.cx[cP.maxIndex],2] = 255
  sliceColor[cP.cy[cP.maxIndex], cP.cx[cP.maxIndex],3] = 1

  circx, circy = drawJulia.circle_perimeter(cP.cy[cP.maxIndex],cP.cx[cP.maxIndex], convert(Int64,floor(cP.radii[cP.maxIndex])))
  for l=1:length(circy)
      sliceColor[circx[l], circy[l],1] = 1
      sliceColor[circx[l], circy[l],2] = 255
      sliceColor[circx[l], circy[l],3] = 1
  end
  imshow(sliceColor, cmap="gray")

  cM=c.childMinus
  figure(c.index*100+1)
  sliceColor = colorSkimage.gray2rgb(rawMRI[cM.index,:,:])
  sliceColor[cM.cy[cM.maxIndex], cM.cx[cM.maxIndex],1] = 1
  sliceColor[cM.cy[cM.maxIndex], cM.cx[cM.maxIndex],2] = 255
  sliceColor[cM.cy[cM.maxIndex], cM.cx[cM.maxIndex],3] = 1

  circx, circy = drawJulia.circle_perimeter(cM.cy[cM.maxIndex],cM.cx[cM.maxIndex], convert(Int64,floor(cM.radii[cM.maxIndex])))
  for l=1:length(circy)
      sliceColor[circx[l], circy[l],1] = 1
      sliceColor[circx[l], circy[l],2] = 255
      sliceColor[circx[l], circy[l],3] = 1
  end
  imshow(sliceColor, cmap="gray")

end

type Candidate3DPos
  x
  y
  z
  xyz
  Candidate3DPos(x,y,z)=new(x,y,z,[x y z])
end

# calc 3d coords of candidates
candidates= Array{Candidate3DPos,1}(length(twoChildsStack))
for (k,cand) in enumerate(twoChildsStack)
  c=cand.value
  cx_mm=c.cy[c.maxIndex]*mriPixelSpacing[3]
  cy_mm=-c.index*mriPixelSpacing[1]
  cz_mm=c.cx[c.maxIndex]*mriPixelSpacing[2]
  candidates[k] = Candidate3DPos(cx_mm,cy_mm,cz_mm)
end

# plot candidates
# figure(10000)
# colors = ["blue","red","green","black"]
# Plots.plot(overright_figure=true)
# Plots.plot!(xaxis="y [mm]",yaxis="x [mm]",zaxis="z [mm]")
# for (k,cand) in enumerate(candidates)
#   a1=Plots.scatter!([cand.x],[cand.y],[cand.z],color=colors[k]);
# end
# Plots.plot!(aspect_ratio=:equal)
# gui()

# combination "select 3" out of candidates
combis = combinations(collect(1:length(candidates)),3)
candidateSets = collect(combis)

# Test all combination with sanity check
valid=Array{Bool,1}(length(candidateSets))
results=Array{Any,1}(length(candidateSets))
errors=Array{Any,1}(length(candidateSets))
measArray=Array{Any,1}(length(candidateSets))
for (k,set) in enumerate(candidateSets)
  meas=Array{Float64,2}(3,3)
  combi = candidates[set]
  for (l,c) in enumerate(combi)
    meas[l,:]=c.xyz
  end
  valid[k],results[k],errors[k], = sanityCheck(meas, MPILib.centerModel, tolerance = 1.0)
  measArray[k] = meas
end

# choose combination with minimal errors
miniError=10
miniIndex=0
for k=1:length(valid)
  if valid[k]
    error = norm(errors[k])
    if error < miniError
      miniError = error
      miniIndex = k
    end
  end
end
result = candidates[candidateSets[miniIndex]]
centersMRI_mm = measArray[miniIndex]
miniError
centersMRI_mm



SFPath = "/opt/mpidata/20141121_130749_CalibrationScans_1_1/61/"
datadir = "/opt/mpidata/20160905_145222_ThreeSphereFID_1_1/"
recoargsdefault = Dict{Symbol,Any}(
  :minFreq => 80e3,
  :iterations => 3,
 )
recoargs = copy(recoargsdefault)
recoargs[:frames] = 1:3000
recoargs[:nAverages] = 100
recoargs[:iterations] = 1
recoargs[:lambd] = 0.1
recoargs[:SNRThresh] = 5
recoargs[:minFreq] = 80e3
recoargs[:maxFreq] = 1250e3
#recoargs[:bEmpty] = BrukerFile(datadir*"3")
recoargs[:SFPath] = SFPath
#meas = ["25","26","27"]
meas = ["27"]
c = getrecodata(recoargs, datadir, meas, file_ext=".nii")

e25=c[1]
data3D=e25.data[:,:,:,28]
mpiPixelSpacing=collect(axisvalues(c[1]))[1:3]
mpiPixelSpacing=map(x->step(x),mpiPixelSpacing)*1000
mpiSize=collect(size(c[1])[1:3])

relThresh=0.45
numOfMaxima=3

d1 = e25[Axis{:time}(28)]
d2 = reshape(d1.data.data,size(d1)...,1)
d3 = AxisArray(d2,ImageAxes.axes(d1)...,Axis{:time}(1.0))
d4 = ImageMeta(d3, properties(e25))
props = properties(e25)

centersMM, valid, = @time performSanityCheck(d4, relThresh, numOfMaxima)
cM = MPILib.centerModel
fovMPI=mpiSize.*mpiPixelSpacing
fovMRI=[0 0 1;1 0 0;0 1 0]*(mriSize.*mriPixelSpacing)
fovMPICenter=fovMPI./2
fovMRICenter=fovMRI./2
transCenterMPIMRI=fovMRICenter.-fovMPICenter

# DataViewerWidget
permMRI=applyPermutions(mri,[3,1,2],[2])
centersMRI_mm[:,2]=centersMRI_mm[:,2]+fovMRI[2]
save("markers.jld","centersMM",centersMM,"centersMRI_mm",centersMRI_mm,"cM",cM)

# mipMPIX,mipMPIY,mipMPIZ=mips(data3D.data)
# figure("MPI 1 vielleicht X"),imshow(mipMPIX,interpolation="none",cmap="gray")
# figure("MPI 2 vielleicht Y"), imshow(mipMPIY,interpolation="none",cmap="gray")
# figure("MPI 3 vielleicht Z"), imshow(mipMPIZ,interpolation="none",cmap="gray")
# for k=1:6 # 3 correct
#   for l=1:8 # 3 correct
# MRIPermFlip=applyPermutions(rawMRI,permuteCombinations()[k],flippings()[l])
# mipMRIX,mipMRIY,mipMRIZ=mips(MRIPermFlip)
# figure("MRI 1 $(k),$(l) vielleicht X"),imshow(mipMRIX,interpolation="none",cmap="gray")
# figure("MRI 2 $(k),$(l) vielleicht Y"), imshow(mipMRIY,interpolation="none",cmap="gray")
# figure("MRI 3 $(k),$(l) vielleicht Z"), imshow(mipMRIZ,interpolation="none",cmap="gray")
# readline(STDIN)
# end
# end
# figure("Result CentersMRI_mm")
# markerMRIMeta=(15,:circle,:orange)
# Plots.plot(overright_figure=true,aspect_ratio=:equal,title="Sphere Fiducial center coordinates",xaxis="y [mm]",yaxis="x [mm]",zaxis="z [mm]")
# Plots.scatter!([centersMRI_mm[1,1]],[centersMRI_mm[1,2]],[centersMRI_mm[1,3]], marker=markerMRIMeta,lab="Meas: middleLeftMiddle")
# Plots.scatter!([centersMRI_mm[2,1]],[centersMRI_mm[2,2]],[centersMRI_mm[2,3]], marker=(15,:cross,:orange), lab="Meas: frontMiddleUp")
# Plots.scatter!([centersMRI_mm[3,1]],[centersMRI_mm[3,2]],[centersMRI_mm[3,3]], marker=(15,:diamond,:orange), lab="Meas: backRightDown")
# markerModelMeta=(15,:circle,:blue)
#
# Plots.scatter!([cM[1,1]],[cM[1,2]],[cM[1,3]], marker=markerModelMeta,lab="Meas: middleLeftMiddle")
# Plots.scatter!([cM[2,1]],[cM[2,2]],[cM[2,3]], marker=(15,:cross,:blue), lab="Meas: frontMiddleUp")
# Plots.scatter!([cM[3,1]],[cM[3,2]],[cM[3,3]], marker=(15,:diamond,:blue), lab="Meas: backRightDown")
# markerMPIMeta=(15,:circle,:red)
# Plots.scatter!([centersMM[1,1]],[centersMM[1,2]],[centersMM[1,3]], marker=markerMPIMeta, lab="Meas: middleLeftMiddle")
# Plots.scatter!([centersMM[2,1]],[centersMM[2,2]],[centersMM[2,3]], marker=(15,:cross,:red), lab="Meas: frontMiddleUp")
# Plots.scatter!([centersMM[3,1]],[centersMM[3,2]],[centersMM[3,3]], marker=(15,:diamond,:red), lab="Meas: backRightDown")




# mipx1,mipy1,mipz1=mips(centersData3D[:,:,:,1])
# figure(4), imshow(mipx1,interpolation="none")
# figure(5), imshow(mipy1,interpolation="none")
# figure(6), imshow(mipz1,interpolation="none")


# dw = DataViewer()
# MPILib.updateData!(dw,c)
# MPILib.updateData!(dw,c,permMRI)

# cv2[:HoughCircles](oneSlice)
# circles = cv2.HoughCircles(img,cv2[:HOUGH_GRADIENT],1,20,param1=50,param2=30,minRadius=0,maxRadius=0)
