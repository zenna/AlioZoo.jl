using NamedTuples
using Arrows
import Arrows:PropType
using AlioZoo
opt = @NT(width = 128, height = 128, nsteps = 15, res = 32, batch_size = 10,
          phong = false, density = 2)


"Test construction of render array that takes voxel_grid"
function render_arrow(opt)
  carr = CompArrow(:render, [:voxel], [:img])
  voxels, img = ⬨(carr)
  img_sprt = AlioZoo.render(voxels, AlioZoo.STD_ROTATION_MATRIX, opt)
  link_ports!(img_sprt, img)
  carr
end

function test_props()
  renderarr = render_arrow(opt)
  voxels, img = ⬨(renderarr)
  voxelsz = Size([opt.batch_size, opt.res, opt.res, opt.res])
  imgsz = Size([opt.batch_size, opt.width * opt.height])
  Arrows.traceprop!(renderarr, Dict(voxels => PropType(:size => voxelsz),
                                    img => PropType(:size => imgsz)))
end


# Want to be able to to
# 1. f(x::T) = [a, b, c]
# 2 .Fro ma
