using Gtk, Gtk.ShortNames, Cairo, MPILib, ImageMetadata

import Base: getindex
export TestDrawingWindow

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

  showall(w)

  @guarded Gtk.draw(m.grid[1,1]) do widget
   ctx = getgc(m.grid[1,1])
   h = height(ctx)
   w = width(ctx)
   im = rand(RGB{N0f8},50,50)
   imSize = size(im)
  #  xsec_ = (size(im,2)-xsec+1)
  #  ysec_ = (size(im,1)-ysec+1)
  #  xx = w*(xsec_-0.5)/size(im,2)
  #  yy = h*(ysec_-0.5)/size(im,1)
  cDA = [w/2,h/2] # changed order because of image coord system
  cIA = [imSize[1]/2,imSize[2]/2]
  sFac = cDA ./ cIA
  println(typeof(ctx),cDA, sFac, cIA)
   copy!(ctx,im)
    set_source_rgb(ctx, 0, 1, 0)
    xy,xz,yz = getSliceSizes([50, 50, 25], [2,2,1])
    drawRectangle(ctx, cDA,cIA, sFac, xy, [0,0])
    drawRectangle(ctx,cDA,cIA, sFac, xz, [10,5])
    set_line_width(ctx, 3.0)
    Cairo.stroke(ctx)
  end

  return w, m
end

function drawLine(ctx,x ,y)

end

function drawRectangle(ctx, cDA, cIA, sFac, xy, xyOffset)
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
