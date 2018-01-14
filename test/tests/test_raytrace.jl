using AlioZoo
using Arrows
import AlioZoo: rayintersect_arr
using TensorFlowTarget

"Test ray trace arrow can be constructed"
function test_raytrace(batch_size=2, width=5, height=5)
  rayintersect_arr(batch_size, width, height)
end

# test_raytrace()

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
  invtabv = traceprop!(invarr, nmabv)
  randin = [randsz(get(invtabv, prt)[:size]) for prt in ▹(invarr)]
  invarr(randin...)
end

# test_run_invert()
