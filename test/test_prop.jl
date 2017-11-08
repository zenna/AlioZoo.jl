using NamedTuples
using Arrows
import Arrows: AbValues
using AlioZoo
opt = @NT(width = 128, height = 128, nsteps = 15, res = 32, batch_size = 10,
          phong = false, density = 2.5)


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
  tprp = Arrows.traceprop!(renderarr, Dict(voxels => AbValues(:size => voxelsz),
                                    img => AbValues(:size => imgsz)))
end

# test_props()

function test_inv_props()
  renderarr = render_arrow(opt)
  invrenderarr = invert(renderarr)
  @assert is_wired_ok(invrenderarr)
  voxels, img = ⬨(invrenderarr, :voxel), ⬨(invrenderarr, :img)
  voxelsz = Size([opt.batch_size, opt.res, opt.res, opt.res])
  imgsz = Size([opt.batch_size, opt.width * opt.height])
  tprp = Arrows.traceprop!(invrenderarr, Dict(voxels => AbValues(:size => voxelsz),
                                         img => AbValues(:size => imgsz)))

  pports = get_sub_ports(invrenderarr, is(θp))
  Dict(pport=>trace_value(pport) in keys(tprp) for pport in pports)
  # foreach(println, (get(tprp, prt) for prt in ▹(invrenderarr, is(θp))))
end
# which
# test_inv_props()
#
# :log
# :/
# :-
# :source -  Size propagation
# :dupl - size prop
#
# :inv_dupl - size
#
# :mean - size
# :reduce_var - size
# :reshape - size
#
# Size: any same
# dupl
# invdupl

# Set(Symbol[:scatter_nd, :log, :dupl_15, :mean, :/, :reshape, :inv_dupl_15, :-, , :reduce_var])
