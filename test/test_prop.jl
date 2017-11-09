using NamedTuples
using Arrows
import Arrows: AbValues
using AlioZoo
opt = @NT(width = 128, height = 128, nsteps = 5, res = 32, batch_size = 5,
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

"a"
sub_port_abval(abtval::Arrows.AbTraceValues, abvtype::Symbol, sprts::Vector{SubPort}) =
  Dict(sprt=>abtval[trace_value(sprt)][abvtype] for sprt in sprts)

# fakeinputs() =
#   map(shape->rand(shape...), get.(collect(values(sub_port_abval(abtval, :size, get_in_sub_ports(invrenderarr))))))

function test_inv_props()
  renderarr = render_arrow(opt)
  duplify!(renderarr)
  voxels, img = ⬨(renderarr, :voxel), ⬨(renderarr, :img)
  voxelsz = Size([opt.batch_size, opt.res, opt.res, opt.res])
  imgsz = Size([opt.batch_size, opt.width * opt.height])
  invrenderarr = aprx_invert(renderarr, inv, Dict(voxels => AbValues(:size => voxelsz),
                                                  img => AbValues(:size => imgsz)))
  @assert is_wired_ok(invrenderarr)
  voxels, img = ⬨(invrenderarr, :voxel), ⬨(invrenderarr, :img)
  abtvals = Arrows.traceprop!(invrenderarr, Dict(voxels => AbValues(:size => voxelsz),
                                         img => AbValues(:size => imgsz)))
  pports = get_sub_ports(invrenderarr, is(θp))
  # Dict(pport=>trace_value(pport) in keys(tprp) for pport in pports)
  invrenderarr, abtvals
  # foreach(println, (get(tprp, prt) for prt in ▹(invrenderarr, is(θp))))
end

function get_input_shapes(abtvals::Arrows.AbTraceValues, arr::CompArrow)
  abval = sort(collect(sub_port_abval(abtvals, :size, get_in_sub_ports(arr))),
                by=x->x[1].port_id)
  get.([v for (k, v) in abval])
end

function genfakeinputs(shapes)
  (shape->rand(shape...)).(shapes)
end

function run_inverse_render()
  invrenderarr, abtvals = test_inv_props()
  shapes = get_input_shapes(abtvals, invrenderarr)
  invrenderarrjl = julia(invrenderarr)
  fakeinputdata = genfakeinputs(shapes)
  invrenderarrjl(fakeinputdata...)
end

domathing(x::Tuple) = "TUPLE$x"
domathing(x::Array) = size(x)

function showintypesize2(arr, args)
  println("IN ", typeof(deref(arr)), ": ", name(deref(arr))," ", map(size, args)...)
end

function showsize(args...)
  println("OUT ", domathing.(args)...)
end

# invrenderarr, abtvals = test_inv_props()
# shapes = get_input_shapes(abtvals, invrenderarr)
# fakeinputdata = genfakeinputs(shapes)
# interpret(invrenderarr, fakeinputdata, Arrows.JuliaTarget.JLTarget, (args...)->println(typeof.(args)),(args...)->println(typeof.(args)))
#
#
# for (sp, shape) in zip(get_in_sub_ports(invrenderarr), shapes)
#   println(sp, ": ", shape)
# end
