using DataFrames
import DataStructures: DefaultDict

function generate_dataset(n)
  hash_carr = AlioZoo.md2hash(2)
  inv_carr = hash_carr |> invert
  wired = Arrows.solve_md2(inv_carr)
  hash_pgf = hash_carr |> pgf
  hash_pgf_f = julia(hash_pgf)
  parameters = DefaultDict(Array{Any, 1})
  for i ∈ 1:100000
    inputs = [rand(0:255) for j ∈ 1:16];
    foreach(zip(▸(hash_pgf), inputs)) do in_
      p, v = in_;
      push!(parameters[name(p).name], v);
    end
    outputs = Dict(map(zip(◂(hash_pgf), hash_pgf_f(inputs...))) do out
      p, v = out;
      name(p), v;
    end)
    foreach(name.(▸(wired))) do n
      push!(parameters[n.name], outputs[n]);
    end
  end
  df = DataFrame(parameters)
  writetable("data/pgf_md2.csv", df)
end

generate_dataset(100*1000)
