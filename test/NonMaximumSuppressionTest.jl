using MPILib

close("all")

volume=zeros(9,9,9)
volume[3,4,:]=ones(9)
showMultiImages(volume,1:3,fignum=1)
gradXYZ, gradX, gradY, gradZ=sobelFilter3D(volume)

showMultiImages(gradXYZ,1:3,fignum=4)
showMultiImages(gradX,1:3,fignum=7)
showMultiImages(gradY,1:3,fignum=10)
showMultiImages(gradZ,1:3,fignum=13)

nms=nonMaximumSuppression(gradXYZ, gradX, gradY, gradZ)

showMultiImages(nms,1:3,fignum=16)
