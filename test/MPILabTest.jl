addprocs(16)
@everywhere ENV["MPILIB_UI"]="Gtk"
@everywhere using MPILib
# ENV["MPILIB_UI"]="Gtk"
# using MPILib
win, m = MPILab()

if !isinteractive()
    c = Condition()
    signal_connect(win, :destroy) do widget
        notify(c)
    end
    wait(c)
end
println("Finished")
