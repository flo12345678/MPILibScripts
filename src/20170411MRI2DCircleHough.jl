using MPILib
using PyCall

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

mriPath = joinpath("/home/griese/Desktop/20160901SphereFID/","FID_test_04_20160901_009_T2st_0TE77_48TR_sag_0001.dcm")
mri = loaddata_dicom(mriPath)
mriPixelSpacing = [pixelspacing(mri)...]*1000
mriSize = [size(mri)...]
# showMultiImages(mri, 1)
d_SphMax_mm = 2.85
r_SphMax_mm = d_SphMax_mm/2
r_SphMax_pix = r_SphMax_mm/mriPixelSpacing[2]
d_SphL1_mm = d_SphMax_mm - mriPixelSpacing[1] # sliceThickness is not taken into account
r_SphL1_mm = d_SphL1_mm/2
r_SphL1_pix = r_SphL1_mm/mriPixelSpacing[2]
d_SphL2_mm = d_SphL1_mm - mriPixelSpacing[1] # sliceThickness is not taken into account
r_SphL2_mm = d_SphL2_mm/2
r_SphL2_pix = r_SphL2_mm/mriPixelSpacing[2]

toleranceMax = 0.4
toleranceL1 = 0.4
toleranceL2 = 0.4

sigma = 3
low_threshold=10
high_threshold=50
radiusStep=0.1
peaks =3

rawMRI = data(mri).data;

oneSlice = rawMRI[5,:,:];
showImage(oneSlice, fignum=1)
stackSize = size(rawMRI,1)

type SliceMeta
  index::Int64
  accums
  cx
  cy
  radii
  maxAccum
end

stack = Array{SliceMeta,1}(stackSize)

for k=1:stackSize
  sliceCanny = cannyAlg.canny(rawMRI[k,:,:], sigma=sigma, low_threshold=low_threshold, high_threshold=high_threshold)
  #showImage(sliceCanny, fignum=k)

  hough_radii = np.arange(r_SphMax_pix - toleranceMax, r_SphMax_pix, radiusStep)
  hough_res = transform.hough_circle(sliceCanny, hough_radii)

  # Select the most prominent 5 circles
  accums, cx, cy, radii = transform.hough_circle_peaks(hough_res, hough_radii, total_num_peaks=peaks)
  sliceMeta = SliceMeta(k,accums, cx, cy, radii, length(accums)!=0?maximum(accums):zero(0))
  if length(accums)!=0
    # first level search plus one
    if k+1 <= stackSize

    end

    #first level search minus one
    if k-1 > 0
      
    end
  end
  stack[k]=sliceMeta
end

for i=1:32
     println(stack[i].index," ",stack[i].cx," ",stack[i].cy," ",stack[i].radii," ",stack[i].maxAccum)
end
# fig, ax = subplots(ncols=1, nrows=1)
# oneSliceColor = colorSkimage.gray2rgb(oneSlice)
# for k=1#:length(cx)
#     circy, circx = drawJulia.circle_perimeter(cx[k], cy[k], convert(Int64,floor(radii[k])))
#     println(circy,typeof(circy),size(circy))
#     println(circx,typeof(circx),size(circx))
#     for l=1:length(circy)
#       oneSliceColor[circx[l], circy[l],1] = 220
#       oneSliceColor[circx[l], circy[l],2] = 20
#       oneSliceColor[circx[l], circy[l],3] = 20
#     end
# end
# imshow(oneSliceColor, cmap="gray")
# show()

# cv2[:HoughCircles](oneSlice)
# circles = cv2.HoughCircles(img,cv2[:HOUGH_GRADIENT],1,20,param1=50,param2=30,minRadius=0,maxRadius=0)
