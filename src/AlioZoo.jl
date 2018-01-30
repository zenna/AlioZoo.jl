"Benchmark arrows"
module AlioZoo
using Arrows
import Arrows: add_sub_arr!,
               in_sub_port,
               out_sub_port,
               inv_add,
               inv_mul
include("kinematics/kinematics.jl")
include("invgraphics/voxel_render.jl")
include("invgraphics/util.jl")
include("raytrace/raytrace.jl")
include("raytrace/raytracearr.jl")
include("draw/draw.jl")
include("crypto/md2.jl")
#include("stanford.jl")

all_benchmark_arrows() = [fwd_2d_linkage(),
                          trc()]

"All pairs of (Arrow, XAbVals)"
all_benchmark_arrow_xabv() = [md2hash(2),
                              (fwd_2d_linkage(), NmAbVals()),
                              (trc(), trcabv())]

export fwd_2d_linkage,
       all_example_arrows,
       drawscene,
       md2hash
end
