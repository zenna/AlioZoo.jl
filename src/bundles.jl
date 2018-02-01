import AlioAnalysis: Sampler
import Arrows: NmAbVals, AbVals, Size
using NamedTuples

"Arrow bundle for MD2Hash"
function md2bundle(; solveconstraints = true,
                     batch_size = 32,
                     nrounds = 2,
                     bitlength = 256,
                     kwargs...)
  f = md2hash(nrounds)
  if solveconstraints
    invf = invert(f)
    xabv = NmAbVals(pnm => AbVals(:size => Size([batch_size, 1]))
    for pnm in Arrows.port_sym_names(invf))
    traceprop!(invf, xabv)

    # Get XABV for psl in wirer
    invf_wired, wirer = Arrows.solve_scalar(invf)
    invfwiredwrapped = Arrows.wraponehot(invf_wired, bitlength)
    pslxabv = NmAbVals(pnm => AbVals(:size => Size([batch_size, 1, bitlength]))
                       for pnm in Arrows.port_sym_names(invfwiredwrapped))
    traceprop!(invf, xabv)
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
                  pslxabv = pslxabv,
                  invf = invfwiredwrapped,
                  solved = solveconstraints)
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
