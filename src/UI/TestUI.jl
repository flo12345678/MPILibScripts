using Gtk, Gtk.ShortNames

import Base: getindex
export TestUIWindow

type TestUIWindow
  builder
  dv
end

getindex(m::TestUIWindow, w::AbstractString) = G_.object(m.builder, w)

function TestUIWindow()
  uifile = joinpath(Pkg.dir("MPILibScripts"),"src","UI","builder","TestUIWindow.xml")
  m = TestUIWindow(Builder(filename=uifile), nothing)
  w = m["TestUIWindow"]
  Workers = workers()
  nWorkers = length(Workers)
  lS = m["liststore1"]

  cb = m["combobox1"]
  permutes = permutations()
  for key in keys(permutes)
    push!(lS, (permutes[key], key[1],key[2],key[3]))
  end
  setproperty!(cb,:active,0)

  for key in keys(permutes)
    push!(m["comboboxtext1"], permutes[key])
  end
  setproperty!(m["comboboxtext1"],:active,0)


  signal_connect(m["button1"], "clicked") do widget
    @Gtk.sigatom begin
      @async begin
        println("start while")
        process = @spawnat Workers[1] begin
          println("before error")
          try
              createError()
          catch ex
            println(catch_stacktrace(),"\nException: ", ex)
          #display(ex)
          #println(rethrow(ex))
          #println(backtrace())
          #println(catch_backtrace())
          end
        end
      end
    end
  end

  signal_connect(m["button2"], "clicked") do widget
    println("start background")
  end

  signal_connect(m["button3"], "clicked") do widget
    active = getproperty(cb, :active, Int64)+1
    println(active)
    println(size(lS))
    value1 = lS[active,1]
    value2 = [lS[active,2],lS[active,3],lS[active,4]]
    println(value1)
    println(value2,typeof(value2))
    #text = getproperty(cb, :model, Gtk.GtkListStoreLeaf)

    #println(text)
  end

  showall(w)
  return w, m
end

function createError()
  try
    a=zeros(1)
    a[2]
  catch exception
    println(catch_stacktrace(),"\nException: ", exception)
  end
end

function permutations()
  perms = Dict(
  [1,2,3] => "[1,2,3]",
  [1,3,2] => "[1,3,2]",
  [2,1,3] => "[2,1,3] Isotropic 3D/Coronal MRI",
  [2,3,1] => "[2,3,1] Sagittal MRI",
  [3,1,2] => "[3,1,2] Transversal MRI",
  [3,2,1] => "[3,2,1]"
  )
 return perms
end
