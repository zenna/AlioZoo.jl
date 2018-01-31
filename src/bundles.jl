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
function md2bundle(; batch_size = 32, nrounds = 2, bitlength = 256, kwargs...)
  f = md2hash(nrounds)
  xabv = NmAbVals(pnm => AbVals(:size => Size([batch_size, 1, bitlength]))
                  for pnm in Arrows.port_sym_names(f))
  xgen = Sampler(()->[Arrows.onehot(rand(0:255, batch_size, 1), bitlength)
                      for nm ∈ Arrows.in_port_sym_names(f)])
  pgff = Arrows.wraponehot(pgf(f, pgf, xabv), bitlength)
  md2bundle = @NT(fwdarr = f,
                  xabv = xabv,
                  gen = xgen,
                  pgff = pgff)
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
