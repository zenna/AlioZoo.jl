# from https://www.nayuki.io/res/cryptographic-primitives-in-plain-python/md2hash.py

using Revise
using Arrows

_BLOCK_SIZE = 16

function md2box(idx::Arrows.AbstractPort)
  res = Arrows.compose!(vcat(idx), Arrows.MD2SBoxArrow())[1]
end


function inverse_md2box(idx::Arrows.AbstractPort)
  res = Arrows.compose!(vcat(idx), Arrows.InverseMD2SBoxArrow())[1]
end

"function to compress the information of block into state"
function compress(block, state, checksum, rounds=18)
  newstate = Array{Any, 1}(size(state)...)
  newchecksum = Array{Any, 1}(size(checksum)...)
  foreach(1:16) do  i
    b = block[i]
    newstate[i] = state[i]
    newstate[i + 16] = b
    newstate[i + 32] = b ⊻ newstate[i]
  end

  t = 0
  foreach(1:rounds) do i
    foreach(1:length(newstate)) do j
      t = newstate[j] = newstate[j] ⊻ Arrows.md2box(t)
    end
    if i != rounds
      next_t = t + i - 1
      t = ifelse(next_t .> 0xFF, next_t .- 0x100, next_t)
    end
  end
  l = checksum[end]
  foreach(1:16) do i
    l = checksum[i] ⊻ md2box(block[i] ⊻ l)
    newchecksum[i] = l
  end
  newstate, newchecksum
end


"a hash compress the information of block and checksum in 16 bytes"
function md2hash(rounds=18)
  carr = CompArrow(:compress, 16, 0);
  block = ▹(carr);
  state = [0 for i in 1:48];
  checksum = [0 for i in 1:16];
  state, checksum = compress(block, state, checksum, rounds)
  state, checksum = compress(checksum, state, checksum, rounds)
  foreach(link_to_parent!, state[1:16])
  Arrows.remove_dead_arrows!(carr)
  carr
end



"""
 An alternative to overcome the performance issues of julia is to use
 a `CompArrow` for the inner loop. That reduce the size of the compiled `Arrow`.
 On the other hand, the output of one of the `carr` contains constats.
 Therefore, the inversion mechanism will not work:
 `AssertionError: true false (SubPort inner_compress_1 ◃inp_1::Any on...`
 """
function use_comparrow_for_inner_loop()
  function compress2(block, state, checksum)
    function inner_loop(n)
      carr = CompArrow(:inner_compress, n + 1, 0)
      t = ▹(carr, 1)
      foreach(▹(carr)[2:end]) do byte
        t = byte ⊻ md2box(t)
        link_to_parent!(t)
      end
      carr
    end
    newstate = Array{SubPort, 1}(size(state)...)
    one = Arrows.promote_constant(block[1] |> Arrows.anyparent, 1)
    foreach(1:16) do  i
      b = block[i]
      newstate[i] = state[i] * one
      newstate[i + 16] = b
      newstate[i + 32] = b ⊻ newstate[i]
    end

    t = 0 * one
    rounds = 18
    foreach(1:rounds) do i
      newstate = Arrows.compose!(vcat(t, newstate),
                                 inner_loop(newstate |> length))
      t = newstate[end]
      if i != rounds
        next_t = t + i - 1
        t = ifelse(next_t .> 0xFF, next_t .- 0x100, next_t)
      end
    end
    foreach(link_to_parent!, newstate)
  end

  c2 = CompArrow(:compress, 16, 0);
  block = in_sub_ports(c2);
  state = [0 for i in 1:48];
  newstate = compress2(block, state, 0)
  @show c2(1:16...)

  inv_c2 = c2 |> Arrows.duplify |> Arrows.invert
  md2_pgf2 = c2 |> pgf
  return c2, inv_c2, md2_pgf2
end
