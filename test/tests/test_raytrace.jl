using AlioZoo
using Arrows
import Arrows: traceprop
import AlioZoo: rayintersect_arr
using TensorFlowTarget

function test_raytrace(; width = 6, height = 4, batch_size = 2)
  npixels = width * height
  vec3size = (batch_size, npixels, 3)
  scalarsize = (batch_size, npixels, 1) # (batch_size, w * h)
  outimgsz = (batch_size, npixels, 1)
  rsarr = rayintersect_arr(batch_size, width, height)
  vec3nms = [:rdir, :rorig, :scenter]
  vec3⬨s = [⬨(rsarr, nm) for nm in vec3nms]
  scalarnms = [:sradius, :doesintersect, :t0, :t1]
  scalar⬨s = [⬨(rsarr, nm) for nm in scalarnms]

  d1 = Dict{SubPort, Arrows.AbValues}(vec3▹ => Arrows.AbValues(:size => Size(vec3size)) for vec3▹ in vec3⬨s)
  d2 = Dict{SubPort, Arrows.AbValues}(scalar⬨ => Arrows.AbValues(:size => Size(scalarsize)) for scalar⬨ in scalar⬨s)
  rsarr, d1, d2
end

test_raytrace()

function test_sizes(; batch_size=2, width=5, height=5)
  rsarr = rayintersect_arr_bcast()
  npixels = width * height
  szs = Dict(:sradius => Size([batch_size, 1, 1]),
             :scenter => Size([batch_size, 1, 3]),
             :rdir => Size([batch_size, npixels, 3]),
             :rorig => Size([batch_size, npixels, 3]),
             :doesintersect => Size([batch_size, npixels, 1]),
             :t0 => Size([batch_size, npixels, 1]),
             :t1 => Size([batch_size, npixels, 1]))
  rsarr = rayintersect_arr_bcast()
  rsarr, traceprop!(rsarr, Arrows.namesz(rsarr, szs))
end

test_sizes()
