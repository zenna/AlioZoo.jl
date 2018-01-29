using NamedTuples
using Arrows
import Arrows: AbVals
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
  tprp = Arrows.traceprop!(renderarr, Dict(voxels => AbVals(:size => voxelsz),
                                    img => AbVals(:size => imgsz)))
end

"a"
sub_port_abval(abtval::Arrows.TraceAbVals, abvtype::Symbol, sprts::Vector{SubPort}) =
  Dict(sprt=>abtval[trace_value(sprt)][abvtype] for sprt in sprts)

# fakeinputs() =
#   map(shape->rand(shape...), get.(collect(values(sub_port_abval(abtval, :size, get_in_sub_ports(invrenderarr))))))

function test_inv_props()
  renderarr = render_arrow(opt)
  voxels, img = ⬨(renderarr, :voxel), ⬨(renderarr, :img)
  voxelsz = Size([opt.batch_size, opt.res, opt.res, opt.res])
  imgsz = Size([opt.batch_size, opt.width * opt.height])
  invrenderarr = aprx_invert(renderarr, inv, Dict(voxels => AbVals(:size => voxelsz),
                                                  img => AbVals(:size => imgsz)))
  @assert is_wired_ok(invrenderarr)
  voxels, img = ⬨(invrenderarr, :voxel), ⬨(invrenderarr, :img)
  abtvals = Arrows.traceprop!(invrenderarr, Dict(voxels => AbVals(:size => voxelsz),
                                         img => AbVals(:size => imgsz)))
  pports = get_sub_ports(invrenderarr, is(θp))
  # Dict(pport=>trace_value(pport) in keys(tprp) for pport in pports)
  renderarr, invrenderarr, abtvals
end

function get_input_shapes(abtvals::Arrows.TraceAbVals, arr::CompArrow)
  abval = sort(collect(sub_port_abval(abtvals, :size, get_in_sub_ports(arr))),
                by=x->x[1].port_id)
  get.([v for (k, v) in abval])
end

function genfakeinputs(shapes)
  (shape->rand(shape...)).(shapes)
end

function run_inverse_render()
  renderarr, invrenderarr, abtvals = test_inv_props()
  shapes = get_input_shapes(abtvals, invrenderarr)
  invrenderarrjl = julia(invrenderarr)
  fakeinputdata = genfakeinputs(shapes)
  invrenderarrjl(fakeinputdata...)
end

function train_inv_render()
  renderarr, invrenderarr, abtvals = test_inv_props()
  invrenderarr = Arrows.psl(invrenderarr)
  superarr = Arrows.supervised(renderarr, invrenderarr)
  suploss = Arrows.supervisedloss(superarr)
  voxels = ⬨(suploss, :voxel)
  voxelsz = Size([opt.batch_size, opt.res, opt.res, opt.res])
  abtvals = Arrows.traceprop!(suploss, Dict(voxels => AbVals(:size => voxelsz)))
  #
  nnettarr = first(filter(tarr -> deref(tarr) isa Arrows.UnknownArrow, Arrows.simpletracewalk(x->x, suploss)))
  tvals = Arrows.trace_values(nnettarr)
  sizes = [abtvals[tval][:size]  for tval in tvals]
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
