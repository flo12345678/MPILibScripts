using JLD
using PyPlot
using Plots
using MPILib

close("all")

centersMM, centersMRI_mm, cM = load("markers.jld","centersMM","centersMRI_mm","cM")

centersMM = centersMM'
centersMRI_mm = centersMRI_mm'
# cMTemp=copy(cM)
# for k=1:3
#   cM[k,1]=cMTemp[k,2]
#   cM[k,2]=-cMTemp[k,3]
#   cM[k,3]=cMTemp[k,1]
# end
cM = MPILib.centerModelMPI'

#figure("Result CentersMRI_mm")
Plots.plot(overright_figure=true,aspect_ratio=:equal,title="Sphere Fiducial center coordinates",xaxis="x [mm]",yaxis="y [mm]",zaxis="z [mm]")

sym=[:circle,:cross,:diamond]
labs=["Mod: middleLeftMiddle","Mod: frontMiddleUp","Mod: backRightDown"]
for k=1:3
  markerModelMeta=(15,sym[k],:blue)
  Plots.scatter!([cM[1,k]],[cM[2,k]],[cM[3,k]], marker=markerModelMeta,lab=labs[k])
end
for k=1:3
  markerModelMeta=(15,sym[k],:orange)
  Plots.scatter!([centersMRI_mm[1,k]],[centersMRI_mm[2,k]],[centersMRI_mm[3,k]], marker=markerModelMeta,lab=labs[k])
end
for k=1:3
  markerModelMeta=(15,sym[k],:red)
  Plots.scatter!([centersMM[1,k]],[centersMM[2,k]],[centersMM[3,k]], marker=markerModelMeta,lab=labs[k])
end


ang90=π/2*3
ang180=π
ang=ang90
RXang=[1 0 0;0 cos(ang) -sin(ang);0 sin(ang) cos(ang)]
RYang=[cos(ang) 0 sin(ang);0 1 0;-sin(ang) 0 cos(ang)]
RZang=[cos(ang) -sin(ang) 0;sin(ang) cos(ang) 0;0 0 1]
r = RXang * centersMM
# for k=1:3
#   markerModelMeta=(15,sym[k],:black)
#   Plots.scatter!([r[1,k]],[r[2,k]],[r[3,k]], marker=markerModelMeta,lab=labs[k])
# end

Tbf, Rbf, tbf = best_fit_transform(centersMRI_mm', centersMM')
T, d = icp(centersMRI_mm', centersMM', max_iterations=1, tolerance=0.01) #, init_pose=inv(Tbf)
display(Tbf)
display(Rbf)
display(tbf)

calcCenterModelBest_fit=inv(Tbf)*cat(1,centersMM,ones(1,3))
#calcCenterModelICP=T*cat(1,centersMM',ones(1,3))
cCenterModel=calcCenterModelBest_fit

for k=1:3
  markerModelMeta=(15,sym[k],:green)
  Plots.scatter!([cCenterModel[1,k]],[cCenterModel[2,k]],[cCenterModel[3,k]], marker=markerModelMeta,lab=labs[k])
end

gui()
