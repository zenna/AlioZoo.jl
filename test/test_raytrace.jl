using AlioZoo
import Arrows: traceprop!
import AlioZoo: rayintersect_arr
using TensorFlowTarget

function test_sizes(; batch_size=2, width=5, height=5)
  rsarr = rayintersect_arr()
  npixels = width * height
  szs = NmAbValues(:sradius => AbValues(:size => Size([batch_size, 1, 1])),
                   :scenter => AbValues(:size => Size([batch_size, 1, 3])),
                   :rdir => AbValues(:size => Size([batch_size, npixels, 3])),
                   :rorig => AbValues(:size => Size([batch_size, npixels, 3])),
                   :doesintersect => AbValues(:size => Size([batch_size, npixels, 1])),
                   :t0 => AbValues(:size => Size([batch_size, npixels, 1])),
                   :t1 => AbValues(:size => Size([batch_size, npixels, 1])))
  rsarr = rayintersect_arr()
  rsarr, traceprop!(rsarr, szs)
end
