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

  signal_connect(m["button1"], "clicked") do widget
    @Gtk.sigatom begin
      @async begin
        println("start while")
        process = @spawnat Workers[1] begin
          println("before error")
          try
              createError()
          catch ex
            println(catch_stacktrace())
            println(fieldnames(ex))
            println(ex)
            println("end catch")
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

  showall(w)
  return w, m
end

function createError()
  try
    a=zeros(1)
    a[2]
  catch exception
    #rethrow(exception)
    println(catch_stacktrace())
    println(ex)
    println("end catch createError")
  end
end
