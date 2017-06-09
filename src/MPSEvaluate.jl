using MPILib
close("all")

expnos=["1","2"].*".mdf"
Names=["Resovist","BeadsMOT1"]
color=["o-b","o-r"]

for (i,ex) in enumerate(expnos)
   u=loadMPSData(ex)

   #u_=squeeze(mean(u,2))
   n=10
   u_ = MPILib.prepareForVisu(u,n)

   uFFT=abs(rfft(u_))

   uSP=uFFT[1:30*2*n]
   uOdd= uFFT[11:2*n:30*2*n]
   uEven= uFFT[1:2*n:30*2*n]


   figure(1),semilogy(abs(uSP),color[i],lw=2,label=Names[i])
   legend()
   figure(2),semilogy(abs(uOdd),label=Names[i])
   legend()
   figure(3),semilogy(abs(uEven),label=Names[i])
   legend()
   figure(4),semilogy(abs(uOdd)./maximum(uOdd),label=Names[i])
   legend()
   figure(),semilogy(abs(uSP),label=Names[i])
   legend()
end
