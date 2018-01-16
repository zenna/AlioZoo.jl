using Base.Test
using AlioZoo
import AlioZoo: rayintersect_arr, trc
using Arrows
using TensorFlowTarget

"Test ray trace arrow can be constructed"
function test_raytrace(batch_size=2, width=5, height=5)
  rayintersect_arr(batch_size, width, height)
end

test_raytrace()

function test_trc(nspheres=3, batch_size=2, width=5, height=5)
  arr = trc(nspheres, batch_size, width, height)
end

test_trc()

function test_run_invert(batch_size=2, width=5, height=5)
  nmabv = NmAbValues(:sradius => AbValues(:size => Size([batch_size, 1, 1])),
                     :scenter => AbValues(:size => Size([batch_size, 1, 3])),
                     :rdir => AbValues(:size => Size([batch_size, width * height, 3])),
                     :rorig => AbValues(:size => Size([batch_size, width * height, 3])),
                     :doesintersect => AbValues(:size => Size([batch_size, width * height, 1])),
                     :t0 => AbValues(:size => Size([batch_size, width * height, 1])),
                     :t1 => AbValues(:size => Size([batch_size, width * height, 1])))
  rsarr = rayintersect_arr(batch_size, width, height)
  invarr = invert(rsarr, inv, nmabv)
  @test is_wired_ok(invarr)
end

test_run_invert()

function test_trc_invert(nspheres=3, batch_size=2, width=5, height=5)
  nmabv = NmAbValues(:rdir => AbValues(:size => Size([batch_size, width * height, 3])),
                     :rorig => AbValues(:size => Size([batch_size, width * height, 3])),
                     :doesintersect => AbValues(:size => Size([batch_size, width * height, 1])))
  for i = 1:nspheres
    nmabv[Symbol(:scenter, i)] = AbValues(:size => Size([batch_size, 1, 3]))
    nmabv[Symbol(:sradius, i)] = AbValues(:size => Size([batch_size, 1, 1]))
  end

  trcarr = test_trc(nspheres, batch_size, width, height)
  invarr = invert(trcarr, inv, nmabv)
  @test is_wired_ok(invarr)
end

test_trc_invert()
