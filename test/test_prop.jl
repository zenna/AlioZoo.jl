using NamedTuples
using Arrows
import Arrows: PropType, ok
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

test_props()

function test_inv_props()
  renderarr = render_arrow(opt)
  invrenderarr = aprx_invert(renderarr)
  voxels, img = ⬨(invrenderarr, :voxel), ⬨(invrenderarr, :img)
  voxelsz = Size([opt.batch_size, opt.res, opt.res, opt.res])
  imgsz = Size([opt.batch_size, opt.width * opt.height])
  tprp = Arrows.traceprop!(invrenderarr, Dict(voxels => PropType(:size => voxelsz),
                                         img => PropType(:size => imgsz)))
  foreach(println, (get(tprp, prt) for prt in ▹(invrenderarr, is(θp))))
end

test_inv_props()
