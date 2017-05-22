using Interpolations
using PyPlot
using Images
using AxisArrays
close("all")
m=[4,8] # discretization
mFine=[16,32]
w1=[0,128]# mm
w2=[0,64] # mm
h=m#[m[1]/w1[2],m[2]/w2[2]]
hFine=m./mFine
hFineGrid=[w1[2]/mFine[1],w2[2]/mFine[2]]

x1=zeros(m[1],m[2])
for k=1:m[1]
  x1[k,:]=k#*h[1]#w1[1]+(k-0.5)*h[1]
end
x2=zeros(m[1],m[2])
for k=1:m[2]
  x2[:,k]=k#*h[2]#w2[1]+(k-0.5)*h[2]
end

data=zeros(m...)
data[2,:]=255
dataAxisArray = AxisArray(data, Axis{:x}(1:m[1]),Axis{:y}(1:m[2]))
itp = interpolate(data, BSpline(Linear()), OnCell())


x1Fine=zeros(mFine...)
for k=1:mFine[1]
  x1Fine[k,:]=k*hFine[1]#w1[1]+(k-0.5)*hFine[1]
end
x2Fine=zeros(mFine...)
for k=1:mFine[2]
  x2Fine[:,k]=k*hFine[1]#w2[1]+(k-0.5)*hFine[2]
end

x1FineGrid=zeros(mFine...)
for k=1:mFine[1]
  x1FineGrid[k,:]=w1[1]+(k-0.5)*hFineGrid[1]
end
x2FineGrid=zeros(mFine...)
for k=1:mFine[2]
  x2FineGrid[:,k]=w2[1]+(k-0.5)*hFineGrid[2]
end
t=[0,12]
x2FineGrid=x2FineGrid+t[2]

dataFine=zeros(mFine...)
for k=1:mFine[1]
  for l=1:mFine[2]
    dataFine[k,l] = itp[x1Fine[k,l], x2Fine[k,l]]
  end
end

itpFine = interpolate(dataFine, BSpline(Linear()), OnCell())
for k=1:mFine[1]
  for l=1:mFine[2]
    dataFine[k,l] = itpFine[x1Fine[k,l], x2Fine[k,l]]
  end
end

figure("Original")
imshow(data,cmap="gray",interpolation="none")
figure("Fine")
imshow(dataFine,cmap="gray",interpolation="none")
