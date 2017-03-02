using MPILib
# test data
volume=ones(Float64,9,9,9)
volume[4,5,3]=5.0
volume[4,4,3]=3.0
volume[4,5,2]=3.0
volume[3,3,2]=3.0

close("all")
showMultiImages(volume,3,fignum=1)

result, binaryMask=hysteresisThreshold(volume, [3.0 4.0])
showMultiImages(result,3,fignum=4)
