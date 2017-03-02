using Plots
using GLVisualize, GLWindow, Reactive

@async begin
  plotlyjs()
  Plots.plot(rand(3),rand(3))
  gui()
end

@async begin
  gr()
  Plots.plot(rand(3),rand(3))
  gui()
end

@async begin
  glvisualize()
  Plots.plot(rand(3),rand(3))
  gui()
end
