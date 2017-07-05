using Gtk, GtkUtilities, Gtk.ShortNames, Cairo, MPILib, ImageMetadata

import Base: getindex
export TestDrawingWindow, emptyFunction, drawRectangle, calcMeta, createRectangle, getSliceSizes

type TestDrawingWindow
  builder
  grid
end

getindex(m::TestDrawingWindow, w::AbstractString) = G_.object(m.builder, w)

function TestDrawingWindow()
  uifile = joinpath(Pkg.dir("MPILibScripts"),"src","UI","builder","TestDrawing.xml")
  b = Builder(filename=uifile)
  m = TestDrawingWindow(b, nothing)
  w = m["window1"]
  m.grid = m["grid1"]
  m.grid[1,1] = Canvas()
  image = zeros(RGB{N0f8},50,50)
  image[1:10,:] = RGB{N0f8}(1.0,1.0,1.0)
  showall(w)

  imSize = size(image)
  xy,xz,yz = getSliceSizes([50, 50, 25], [2,2,1])
  xyOffset = [0,0]
  drawAll(m.grid[1,1],image, imSize, xy, xyOffset)
  println("hallo")
  m.grid[1,1].mouse.button3press = @guarded (widget, event) -> begin
    ctx = getgc(m.grid[1,1])

    reveal(m.grid[1,1])
    println(event.x," ",event.y)
    h = height(ctx)
    w = width(ctx)
    println("h ",h, "w", w)
    p = [event.x,event.y]
    #println("center", center(ctx))
    println(typeof(ctx))
    @guarded Gtk.draw(m.grid[1,1]) do widget
      drawAll(m.grid[1,1],image, imSize, xy, xyOffset)
      println("mouse event")
      drawRectangle(ctx, h,w,p, imSize, xy, xyOffset, rgb=[0,0,1],lineWidth=3.0)
    end
    #m.grid[1,1].mouse.button3press=emptyFunction

    # xx = event.x / w*size(image,2) + 0.5
    # yy = event.y / h*size(image,1) + 0.5
    #
    # xx = !flipX ? xx : (size(image,2)-xx+1)
    # yy = !flipY ? yy : (size(image,1)-yy+1)

   end

  return w, m
end

function emptyFunction(widget::Gtk.GtkCanvas, event::Gtk.GdkEventButton)
end

function drawAll(control,image, imSize, xy, xyOffset)
  @guarded Gtk.draw(control) do widget
      ctx = getgc(control)
      copy!(ctx,image)
      h = height(ctx)
      w = width(ctx)
      p = [w/2,h/2] # changed order because of image coord system
      println("redraw event")
      drawRectangle(ctx, h,w,p, imSize, xy, xyOffset,lineWidth=5.0)
  end
end

function drawRectangle(ctx,h,w, p, imSize, xy, xyOffset;rgb=[0,1,0], lineWidth=3.0)
  cIA, sFac = calcMeta(p,h,w, imSize)
  set_source_rgb(ctx, rgb...)
  createRectangle(ctx, p, cIA, sFac, xy, xyOffset)
  set_line_width(ctx, lineWidth)
  Cairo.stroke(ctx)
end

function calcMeta(p,h,w,imSize)
  cDA = [w/2,h/2]
  cIA = [imSize[1]/2,imSize[2]/2]
  sFac = cDA ./ cIA
  println("cIA", cIA, "sFac", sFac)
  return cIA, sFac
end

function createRectangle(ctx, cDA, cIA, sFac, xy, xyOffset)
  lowCX = cDA[1] - sFac[1] * xy[1]/2 + sFac[1] * xyOffset[1]
  lowCY= cDA[2] - sFac[2] * xy[2]/2 + sFac[1] * xyOffset[2]
  highCX =lowCX + sFac[1]*xy[1]
  highCY =lowCY + sFac[2]*xy[2]
  move_to(ctx, lowCX, lowCY)
  line_to(ctx, highCX, lowCY)
  move_to(ctx, lowCX, lowCY)
  line_to(ctx, lowCX, highCY)
  move_to(ctx, highCX, lowCY)
  line_to(ctx, highCX, highCY)
  move_to(ctx, lowCX, highCY)
  line_to(ctx, highCX, highCY)
end

function getSliceSizes(fov_mm, pixelSpacing)
  fov_vox = fov_mm ./ pixelSpacing
  xy = [fov_vox[1],fov_vox[2]]
  xz = [fov_vox[1],fov_vox[3]]
  yz = [fov_vox[2],fov_vox[3]]
  return xy,xz,yz
end
