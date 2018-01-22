using Arrows
using AlioZoo
using Base.Test


function test_md2()
    carr = AlioZoo.md2hash(2)
    @test carr(1:16...) == (148, 97, 205, 220, 205, 167, 218, 220,
                            138, 57, 196, 176, 107, 2, 205, 199)
    inv_carr = carr |> Arrows.duplify |> Arrows.invert
    md2_pgf = carr |> pgf
    @test (md2_pgf >> inv_carr)(1:16...) == (1:16...)
end

test_md2()

function test_solver()
  hash_carr = AlioZoo.md2hash(2)
  inv_carr = hash_carr |> invert
  wired, wirer = Arrows.solve_md2(inv_carr)
  hash_pgf = hash_carr |> pgf
  inputs = 1:16
  outputs = map(zip(◂(hash_pgf), hash_pgf(inputs...))) do out
    p, v = out
    name(p), v
  end
  outputs = Dict(outputs)
  inputs_wired = [outputs[p] for p in name.(▸(wired))]
  @test wired(inputs_wired...) == (inputs...)
end

test_solver()

function generate_function(context, expr)
  M = Module()
  for (k,v) in context
         eval(M, :($k = $v))
  end
  eval(M, :(using Arrows))
  eval(M, expr)
end
