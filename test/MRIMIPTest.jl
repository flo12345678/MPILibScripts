using MPILib
fileName="/home/griese/Desktop/BMBF_MPIQuadrat/MRTReference.hdr"
bg = loaddata(fileName);

a=mip(bg,1)
imshow(a,"gray")
b=mip(bg,2)
imshow(b,"gray")
c=mip(bg,3)
imshow(c,"gray")
