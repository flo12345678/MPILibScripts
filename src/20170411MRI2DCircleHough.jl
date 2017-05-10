using MPILib
using PyCall
using Plots
using Combinatorics

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

mriPath = joinpath("/home/fgriese/Documents/Daten/DICOMData/20160901SphereFID/","FID_test_04_20160901_009_T2st_0TE77_48TR_sag_0001.dcm")
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
          slicePlus=SliceMeta(k-1, accumsOrtho, cxOrtho, cyOrtho, radiiOrtho, maxValue, maxIndex)
          slice.cx =cat(1,slice.cx,cxOrthoParent)
          slice.cy =cat(1,slice.cy,cyOrthoParent)
          slice.accums =cat(1,slice.accums,accumsOrthoParent)
          slice.radii =cat(1,slice.radii,radiiOrthoParent)
          slicePlus.parent = slice
          slice.childMinus = slicePlus
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
end

# calc 3d coords of candidates
candidates= Array{Candidate3DPos,1}(length(twoChildsStack))
for (k,cand) in enumerate(twoChildsStack)
  c=cand.value
  cx_mm=c.cx[c.maxIndex]*mriPixelSpacing[2]
  cy_mm=c.cy[c.maxIndex]*mriPixelSpacing[3]
  cz_mm=c.index*mriPixelSpacing[1]
  candidates[k] = Candidate3DPos(cx_mm,cy_mm,cz_mm)
end

# plot candidates
colors = ["blue","red","green","black"]
Plots.plot(overright_figure=true)
Plots.plot!(xaxis="y [mm]")
Plots.plot!(yaxis="x [mm]")
Plots.plot!(zaxis="z [mm]")
for (k,cand) in enumerate(candidates)
  a1=Plots.scatter!([cand.x],[cand.y],[cand.z],color=colors[k]);
end
Plots.plot!(aspect_ratio=:equal)
gui()

# combination "select 3" out of candidates
combis = combinations([1,2,3,4,5],3)
candidateSets = collect(combis)

# Test all combination with sanity check

# cv2[:HoughCircles](oneSlice)
# circles = cv2.HoughCircles(img,cv2[:HOUGH_GRADIENT],1,20,param1=50,param2=30,minRadius=0,maxRadius=0)
