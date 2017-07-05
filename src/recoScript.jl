println("start reco script")
using MPILib

# for x in ARGS
#   println("args: $(x)")
# end

SFPath = "/opt/mpidata/20141121_130749_CalibrationScans_1_1/61/"
datadir = "$(ARGS[1])/"
println(datadir)
meas = ["$(ARGS[2])"]
robLogPath="$(ARGS[3])"
f = ARGS[4]
(positions, positionsByFrame, frameRange, frames, brukerFile)=loadInfoRobLog(robLogPath)
warn(f)
f = f[2:end-1]
framesSplit=split(f,",")
frames=map(x->parse(Int64,x), framesSplit)
#framgesRange=ARGS[4]
#positionsByFrame = ARGS[5]


recoargsdefault = Dict{Symbol,Any}(
  :minFreq => 80e3,
  :iterations => 3,
 )

### High Level Interface ###

recoargs = copy(recoargsdefault)
recoargs[:frames] = frames
recoargs[:nAverages] = 1
recoargs[:iterations] = 3
recoargs[:lambd] = 0.01
recoargs[:SNRThresh] = 1.5
recoargs[:minFreq] = 80e3
recoargs[:maxFreq] = 1250e3
recoargs[:SFPath] = SFPath

c = getrecodata(recoargs, datadir, meas, file_ext=".mdf")
d=first(first(c))
e=deepcopy(c)
f=deepcopy(c)

data4D=d.data
@time cutOff,components4D,centerofmassdata4D = calcCenterOfMass(data4D, 0.5)

e[1][1].data=cutOff
f[1][1].data=components4D


cen=centerofmassdata4D'
Sx=cen[:,1]
Sy=cen[:,2]
Sz=cen[:,3]

# figure(100)
# clf()
# plot3D(Sx, Sy, Sz, "*", color="red")

@time Δr,mx,my,mz,xerr,yerr,zerr,relThresholds = calcSysErrThresh(data4D)

# figure(10);
# clf();
# #title("Error position estimation\nof statistical sample")
# xlabel("relative Threshold Θ")
# ylabel("Error [Voxeldistance]")
# errorbar(relThresholds, mx, yerr=xerr, fmt="bD", label="μx");
# errorbar(relThresholds, my, yerr=yerr, fmt=">", color="lightgreen", label="μy");
# errorbar(relThresholds, mz, yerr=zerr, fmt="rs", color="red", label="μz");
# legend(loc="upper left", ncol=3)

println("end reco script")
