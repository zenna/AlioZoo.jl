using Base.Test
using AlioZoo
import AlioZoo: rayintersect_arr, trc, rint_xabv
using Arrows

"Test ray trace arrow can be constructed"
function test_rayintersect(batch_size=2, width=5, height=5)
  @grab arr = rayintersect_arr(batch_size, width, height)
end

"Make a batch of `arr` of size `batch_size`"
function batch(arr::Array, batch_size::Integer)
  newshape = (1, size(arr)...)
  repeat(reshape(arr, newshape), inner = (batch_size, (1 for i = 1:ndims(arr))...))
end

"Input for raytrace arr"
function rayintersect_ex_input(batch_size, width, height)
  rdir, rorig = AlioZoo.rdirs_rorigs(width, height)
  rdir = batch(rdir, batch_size)
  rorig = batch(rorig, batch_size)  
  sphere = AlioZoo.example_spheres()[2]
  sradius = batch(reshape([sphere.radius], (1,1)), batch_size)
  scenter = batch(reshape(sphere.center, (1, 3)), batch_size)
  (rdir, rorig, scenter, sradius)
end

function test_rayintersect_execute(batch_size=1, width=480, height=320)
  ri = rayintersect_arr(batch_size, width, height)
  # Need to totalize forward arrow because we don't have proper control flow
  # and bad branch leads to inverse values of sqrt 
  ri = Arrows.aprx_totalize(ri)
  ri(rayintersect_ex_input(batch_size, width, height)...)
end

test_rayintersect_execute()

function test_ray_intersect_invert(batch_size=1, width=480, height=320)
  @grab ri = rayintersect_arr(batch_size, width, height)
  @grab rixabv = rint_xabv(batch_size, width, height)
  @grab rinv = invert(ri, inv, rixabv)
end

test_ray_intersect_invert()

# arrow             totalize      sym     domainpreds      pi
# exbcast,
# :inv_exbcast      todo          ok      todo
# :dupl_2,          ok            ok      ok
# :ifelse,          na            ok?     ok?
# :abs,             todo          ok      todo
# :(==),            na            ok      na
# :sqr,             na            ok      na       
# :bcast,           name          ok      na
# :inv_dupl_2, 
# :+,
# :cat,             na            todo    na
# :/,               todo          ok      todo
# :inv_dupl_3,
# :inv_dupl_5,
# :dupl_8,
# :dupl_5,
# :-,
# :source])


using Spec
using AlioAnalysis
"Are Pgf and Pi consistent - `invf(f(x); pgf(x) = x`"
function ispipgfid(f::Arrow, x::Vector, xabv::XAbVals=NmAbVals(), eq=(==))
  invf = invert(f, inv, xabv)
  pgff = pgf(f, pgf, xabv)

  pgfθ = port_sym_name.(⬧(pgff, is(θp)))
  inffθ = port_sym_name.(⬧(pgff, is(θp)))
  # Parametric ports should be the same
  @pre begin
    pgfθ = port_sym_name.(⬧(pgff, is(θp)))
    inffθ = port_sym_name.(⬧(invf, is(θp)))
    Set(pgfθ) == Set(inffθ)
  end "θ⬧ differ!, invf: $inffθ \n pgf: $pgfθ \n pgf-inv :$(setdiff(pgfθ, inffθ)) invf-pgf: $(setdiff(inffθ, pgfθ))"

  y, θ = (AlioAnalysis.y_θ_split(pgff) ∘ Arrows.aprx_totalize(pgff))(x...)
  @grab y
  @grab θ
  x = invf(y..., θ...)
  all(map(eq, x, x))
end


function test_ray_intersect_pgf(batch_size=1, width=480, height=320)
  @grab ri = rayintersect_arr(batch_size, width, height)
  @grab rixabv = rint_xabv(batch_size, width, height)
  @test ispipgfid(ri, [rayintersect_ex_input(batch_size, width, height)...], rixabv)
end

test_ray_intersect_pgf()


function test_trc(nspheres=3, batch_size=2, width=5, height=5)
  arr = trc(nspheres, batch_size, width, height)
end

test_trc()

function test_run_invert(batch_size=2, width=5, height=5)
  nmabv = AlioZoo.rtabv(batch_size, width, height)
  rsarr = rayintersect_arr(batch_size, width, height)
  invarr = invert(wrap(rsarr), inv, nmabv)
  @test is_valid(invarr)
end

test_run_invert()

function test_trc_invert(nspheres=1, batch_size=2, width=5, height=5)
  nmabv = NmAbVals(:rdir => AbVals(:size => Size([batch_size, width * height, 3])),
                     :rorig => AbVals(:size => Size([batch_size, width * height, 3])),
                     :doesintersect => AbVals(:size => Size([batch_size, width * height, 1])))
  for i = 1:nspheres
    nmabv[Symbol(:scenter, i)] = AbVals(:size => Size([batch_size, 1, 3]))
    nmabv[Symbol(:sradius, i)] = AbVals(:size => Size([batch_size, 1, 1]))
  end

  trcarr = test_trc(nspheres, batch_size, width, height)
  @test is_valid(trcarr)
  invarr = invert(trcarr, inv, nmabv)
  @test is_valid(invarr)
end

test_trc_invert()

function test_constraints(batch_size=2, width=5, height=5)
  nmabv = AlioZoo.rtabv(batch_size, width, height)
  rsarr = rayintersect_arr(batch_size, width, height)
  invarr = invert(wrap(rsarr), inv, nmabv)
  info = Arrows.ConstraintInfo()
  Arrows.symbol_in_ports!(invarr, info, nmabv)
  interpret(Arrows.sym_interpret, invarr, info.inp)
end

constraints = test_constraints()
