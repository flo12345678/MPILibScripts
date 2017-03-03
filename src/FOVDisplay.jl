using PyPlot
include("Functions.jl")
# FOV in mm
num=10;
fov=[50.0,50.0,25.0];
center=[0.0 0.0 0.0]
x=linspace(-fov[1]/2, fov[1]/2, num);
y=linspace(-fov[2]/2, fov[2]/2, num);
z=linspace(-fov[3]/2, fov[3]/2, num);

cubeNodes=[[-fov[1]/2 -fov[2]/2 -fov[3]/2];
           [fov[1]/2 -fov[2]/2 -fov[3]/2];
           [-fov[1]/2 fov[2]/2 -fov[3]/2];
           [-fov[1]/2 -fov[2]/2 fov[3]/2];
           [-fov[1]/2 fov[2]/2 fov[3]/2];
           [fov[1]/2 fov[2]/2 -fov[3]/2];
           [fov[1]/2 -fov[2]/2 fov[3]/2];
           [fov[1]/2 fov[2]/2 fov[3]/2];
           ];
#combinations=collect(combinations(cubeEdges,3));
cubeEdge1=zeros(Float64,num,3);
cubeEdge2=zeros(Float64,num,3);
cubeEdge3=zeros(Float64,num,3);
cubeEdge4=zeros(Float64,num,3);
cubeEdge5=zeros(Float64,num,3);
cubeEdge6=zeros(Float64,num,3);
cubeEdge7=zeros(Float64,num,3);
cubeEdge8=zeros(Float64,num,3);
cubeEdge9=zeros(Float64,num,3);
cubeEdge10=zeros(Float64,num,3);
cubeEdge11=zeros(Float64,num,3);
cubeEdge12=zeros(Float64,num,3);

# Punkte plotten geht nicht so einfach...
#plot3D([5],[3],[2],"*",color="green")
for i=1:num
  cubeEdge1[i,:]=[x[i] -fov[2]/2 -fov[3]/2];
end
for i=1:num
  cubeEdge2[i,:]=[x[i] fov[2]/2 -fov[3]/2];
end
for i=1:num
  cubeEdge3[i,:]=[x[i] -fov[2]/2 fov[3]/2];
end
for i=1:num
  cubeEdge4[i,:]=[x[i] fov[2]/2 fov[3]/2];
end
for i=1:num
  cubeEdge5[i,:]=[-fov[1]/2 y[i] -fov[3]/2];
end
for i=1:num
  cubeEdge6[i,:]=[fov[1]/2 y[i] -fov[3]/2];
end
for i=1:num
  cubeEdge7[i,:]=[-fov[1]/2 y[i] fov[3]/2];
end
for i=1:num
  cubeEdge8[i,:]=[fov[1]/2 y[i] fov[3]/2];
end
for i=1:num
  cubeEdge9[i,:]=[-fov[1]/2 -fov[2]/2 z[i]];
end
for i=1:num
  cubeEdge10[i,:]=[fov[1]/2 -fov[2]/2 z[i]];
end
for i=1:num
  cubeEdge11[i,:]=[-fov[1]/2 fov[2]/2 z[i]];
end
for i=1:num
  cubeEdge12[i,:]=[fov[1]/2 fov[2]/2 z[i]];
end

fig =figure()
ax = gca(projection="3d")

plot3D(cubeEdge1[:,1],cubeEdge1[:,2],cubeEdge1[:,3],"*",color="blue")
plot3D(cubeEdge2[:,1],cubeEdge2[:,2],cubeEdge2[:,3],"*",color="blue")
plot3D(cubeEdge3[:,1],cubeEdge3[:,2],cubeEdge3[:,3],"*",color="blue")
plot3D(cubeEdge4[:,1],cubeEdge4[:,2],cubeEdge4[:,3],"*",color="blue")
plot3D(cubeEdge5[:,1],cubeEdge5[:,2],cubeEdge5[:,3],"*",color="blue")
plot3D(cubeEdge6[:,1],cubeEdge6[:,2],cubeEdge6[:,3],"*",color="blue")
plot3D(cubeEdge7[:,1],cubeEdge7[:,2],cubeEdge7[:,3],"*",color="blue")
plot3D(cubeEdge8[:,1],cubeEdge8[:,2],cubeEdge8[:,3],"*",color="blue")
plot3D(cubeEdge9[:,1],cubeEdge9[:,2],cubeEdge9[:,3],"*",color="blue")
plot3D(cubeEdge10[:,1],cubeEdge10[:,2],cubeEdge10[:,3],"*",color="blue")
plot3D(cubeEdge11[:,1],cubeEdge11[:,2],cubeEdge11[:,3],"*",color="blue")
plot3D(cubeEdge12[:,1],cubeEdge12[:,2],cubeEdge12[:,3],"*",color="blue")
plot3D(cubeNodes[:,1],cubeNodes[:,2],cubeNodes[:,3],"*",color="red")
plot3D([center[1]; center[1]],[center[2]; center[2]],[center[3]; center[3]],"*",color="red")
show()

#Plot fiducial spheres
numberOfPoints=25;
#sphere function
theta=linspace(0,pi,numberOfPoints)
phi=linspace(0,2*pi,numberOfPoints)

grid_a = vec(broadcast((x,y) -> x, theta, phi'))
grid_b = vec(broadcast((x,y) -> y, theta, phi'))

radius=2.5;
sphere=SphereFunction(grid_a,grid_b,radius)
centerSp1=[-20 0 0]
centerSp2=[7.5 -12.5 -6.725]
centerSp3=[20 20 7.5]
distanceSp1Sp2 = norm(centerSp1-centerSp2)
distanceSp1Sp3 = norm(centerSp1-centerSp3)
distanceSp2Sp3 = norm(centerSp2-centerSp3)

sphere1=sphere.+centerSp1;
sphere2=sphere.+centerSp2;
sphere3=sphere.+centerSp3;
plot3D(sphere1[:,1], sphere1[:,2], sphere1[:,3], "+", color="green")
plot3D(sphere2[:,1], sphere2[:,2], sphere2[:,3], "+", color="orange")
plot3D(sphere3[:,1], sphere3[:,2], sphere3[:,3], "+", color="black")

plot3D([centerSp1[1]; centerSp2[1]],[centerSp1[2]; centerSp2[2]],[centerSp1[3]; centerSp2[3]],color="red")
plot3D([centerSp1[1]; centerSp3[1]],[centerSp1[2]; centerSp3[2]],[centerSp1[3]; centerSp3[3]],color="red")
plot3D([centerSp2[1]; centerSp3[1]],[centerSp2[2]; centerSp3[2]],[centerSp2[3]; centerSp3[3]],color="red")
println(distanceSp1Sp2)
println(distanceSp1Sp3)
println(distanceSp2Sp3)
#
# fovFrame=zeros(Float64,num*num*num,3);
# ii=1;
# for i=1:length(x)
#   for j=1:length(y)
#     for k=1:length(z)
#       fovFrame[ii,:]=[x[i]  y[j]  z[k]];
#       ii+=1;
#     end
#   end
# end
# rotFrame=fovFrame*CreateRotateMatrix3Dx(45);
#
# fig =figure()
# ax = gca(projection="3d")
# for i=45:45:90
# #surf = plot_surface(X, Y, Z, rstride=1, cstride=1, linewidth=1, antialiased=false)
# plot3D(fovFrame[:,1],fovFrame[:,2],fovFrame[:,3],"*",color="red")
#
# rotFrame=fovFrame*CreateRotateMatrix3Dx(i);
# plot3D(rotFrame[:,1],rotFrame[:,2],rotFrame[:,3],"*",color="green")
# #axis("x","y","z")
#
#
# sleep(100)
# end
# show()
