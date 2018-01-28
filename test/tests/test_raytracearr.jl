using Base.Test
using AlioZoo
import AlioZoo: rayintersect_arr, trc
using Arrows

"Test ray trace arrow can be constructed"
function test_raytrace(batch_size=2, width=5, height=5)
  @grab arr = rayintersect_arr(batch_size, width, height)
end

"Make a batch of `arr` of size `batch_size`"
function batch(arr::Array, batch_size::Integer)
  newshape = (1, size(arr)...)
  repeat(reshape(arr, newshape), inner = (batch_size, (1 for i = 1:ndims(arr))...))
end

function test_raytrace_execute(batch_size=1, width=480, height=320)
  rtarr = rayintersect_arr(batch_size, width, height)
  
  # Get input scene
  rdir, rorig = AlioZoo.rdirs_rorigs(width, height)
  rdir = batch(rdir, batch_size)
  rorig = batch(rorig, batch_size)  
  sphere = AlioZoo.example_spheres()[2]
  sradius = batch(reshape([sphere.radius], (1,1)), batch_size)
  scenter = batch(reshape(sphere.center, (1, 3)), batch_size)
  # Need to totalize forward arrow because we don't have proper control flow
  # and bad branch leads to inverse values of sqrt 
  rtarr = Arrows.aprx_totalize(rtarr)
  @grab rdir
  @grab rorig
  @grab scenter
  @grab sradius
  @grab rtarr
  rtarr(rdir, rorig, scenter, sradius)
end

out = test_raytrace_execute()

@assert false

function test_trc(nspheres=3, batch_size=2, width=5, height=5)
  arr = trc(nspheres, batch_size, width, height)
end

test_trc()

function test_run_invert(batch_size=2, width=5, height=5)
  nmabv = AlioZoo.rtabv(batch_size, width, height)
  rsarr = rayintersect_arr(batch_size, width, height)
  invarr = invert(wrap(rsarr), inv, nmabv)
  @test is_valid(invarr)
end

test_run_invert()

function test_trc_invert(nspheres=1, batch_size=2, width=5, height=5)
  nmabv = NmAbValues(:rdir => AbValues(:size => Size([batch_size, width * height, 3])),
                     :rorig => AbValues(:size => Size([batch_size, width * height, 3])),
                     :doesintersect => AbValues(:size => Size([batch_size, width * height, 1])))
  for i = 1:nspheres
    nmabv[Symbol(:scenter, i)] = AbValues(:size => Size([batch_size, 1, 3]))
    nmabv[Symbol(:sradius, i)] = AbValues(:size => Size([batch_size, 1, 1]))
  end

  trcarr = test_trc(nspheres, batch_size, width, height)
  @test is_valid(trcarr)
  invarr = invert(trcarr, inv, nmabv)
  @test is_valid(invarr)
end

test_trc_invert()

function test_constraints(batch_size=2, width=5, height=5)
  nmabv = AlioZoo.rtabv(batch_size, width, height)
  rsarr = rayintersect_arr(batch_size, width, height)
  invarr = invert(wrap(rsarr), inv, nmabv)
  info = Arrows.ConstraintInfo()
  Arrows.symbol_in_ports!(invarr, info, nmabv)
  interpret(Arrows.sym_interpret, invarr, info.inp)
end

constraints = test_constraints()
