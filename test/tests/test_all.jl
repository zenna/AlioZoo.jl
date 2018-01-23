# Run tests on set of arrows

using Arrows
import Arrows: XAbValues
import AlioZoo: all_benchmark_arrow_xabv

"""
In words, what I want is a push button tool which will take
all the arrows from some canonical test and then for each one do
a sequence of tests:

1. Construct its parametric inverse
2. Construct its pgf
3. Verify pgf is working
4. Derive all constraints

Then quantitative analysis
5. Try a preimage attack

"""
function suite(arr::Arrow, xabv::XAbValues)
  @assert is_valid(arr)
  println("\nTesting ", arr)
  println("xabv", xabv)
  invarr = invert(arr, inv, xabv)
  @assert is_valid(invarr)
  pgfarr = pgf(arr, pgf, xabv)
  invarr
  constraints = Arrows.all_constraints(invarr, xabv)
end

function test_all_benchmark_arrows()
  for (arr, xabv) in AlioZoo.all_benchmark_arrow_xabv()
    suite(arr, xabv)
  end
end
