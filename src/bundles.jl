import AlioAnalysis: Sampler
import Arrows: NmAbVals, AbVals, Size
using NamedTuples

# ## Bundles
# "Arrow and associated data"
# struct ArrowBundle
#   fwdarr::Arrow
#   xabv::XAbVals
#   gen # Generator
#   # template
# end

"Arrow bundle for MD2Hash"
function md2bundle(; solveconstraints = true,
                     batch_size = 32,
                     nrounds = 2,
                     bitlength = 256,
                     kwargs...)
  f = md2hash(nrounds)
  if solveconstraints
    invf = f |> invert
    xabv = NmAbVals(pnm => AbVals(:size => Size([batch_size, 1]))
    for pnm in Arrows.port_sym_names(invf))
    traceprop!(invf, xabv)


    invf, wirer = Arrows.solve_scalar(invf)
    @grab wirer
    xabv = NmAbVals(pnm => AbVals(:size => Size([batch_size, 1]))
    for pnm in Arrows.port_sym_names(wirer))
    traceprop!(wirer, xabv)
    @assert false "even got here"


    traceprop!(invf, xabv)
    @grab invfwired
    @grab invfwiredwrapped = Arrows.wraponehot(invfwired, bitlength)
  end


  
  xabv = NmAbVals(pnm => AbVals(:size => Size([batch_size, 1, bitlength]))
                  for pnm in Arrows.port_sym_names(invfwiredwrapped))
  xgen = Sampler(()->[Arrows.onehot(rand(0:255, batch_size, 1), bitlength)
                      for nm ∈ Arrows.in_port_sym_names(f)])
  pgff = Arrows.wraponehot(pgf(f, pgf, xabv), bitlength)
  md2bundle = @NT(fwdarr = f,
                  xabv = xabv,
                  gen = xgen,
                  pgff = pgff,
                  invf = invfwiredwrapped)
end

"All bundles"
allbundles() = [md2bundle()]

const allbundlegens = [md2bundle]

all_benchmark_arrows() = [fwd_2d_linkage(),
                          trc()]
# Deprecate this
"All pairs of (Arrow, XAbVals)"
all_benchmark_arrow_xabv() = [md2hash(2),
                              (fwd_2d_linkage(), NmAbVals()),
                              (trc(), trcabv())]
