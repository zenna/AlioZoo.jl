# from https://www.nayuki.io/res/cryptographic-primitives-in-plain-python/md2hash.py

using Revise
using Arrows



function md2box(idx::Arrows.AbstractPort)
  res = Arrows.compose!(vcat(idx), Arrows.MD2SBoxArrow())[1]
end


function inverse_md2box(idx::Arrows.AbstractPort)
  res = Arrows.compose!(vcat(idx), Arrows.InverseMD2SBoxArrow())[1]
end

function compress(block, state, checksum)
  newstate = Array{Any, 1}(size(state)...)
  foreach(1:16) do  i
    b = block[i]
    newstate[i] = state[i]
    newstate[i + 16] = b
    newstate[i + 32] = b ⊻ newstate[i]
  end

  t = Arrows.promote_constant(block[1] |> Arrows.anyparent, 0)
  rounds = 18
  foreach(1:rounds) do i
    foreach(1:length(newstate)) do j
      t = newstate[j] = newstate[j] ⊻ md2box(t)
    end
    if i != rounds
      next_t = t + i - 1
      t = ifelse(next_t .> 0xFF, next_t .- 0x100, next_t)
    end
  end
  foreach(link_to_parent!, newstate)
end


c = CompArrow(:compress, 16, 0);
block = in_sub_ports(c);
state = [0 for i in 1:48];
newstate = compress(block, state, 0)
println(c(1:16...))

inv_c = c |> Arrows.duplify |> Arrows.invert
md2_pgf = c |> pgf

(md2_pgf >> inv_c)(1:16...)
wirer, info = Arrows.solve(inv_c);
