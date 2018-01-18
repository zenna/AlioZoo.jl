
# What makes arrow version difficult
# if
# or
# greater than
# inf
# imperative style of set a value then maybe override it
# recursion!

# o get simple version working first

# Problem, we need the sphere which we hit, not just the cloeset point
# Problem. The full function gets pretty complex.  Will we get the parameter explosion problem
# Problem. Lots of control flow. We don't have a PI for this.
# Problem. No recursion so need to unroll?

"Dot product"
function dot_arr()
  dotarr = CompArrow(:dot, [:xs, :ys], [:dot])
  xs, ys, dot = ⬨(dotarr)
  reducesum = Arrows.ReduceSumArrow(3, true)
  reducesum(map(*, xs, ys)) ⥅ ◃(dotarr, 1)
  @assert is_wired_ok(dotarr)
  dotarr
end

"Ray Sphere Intersection"
function rayintersect_arr(batch_size=1, width=100, height=100)
  rayint = CompArrow(:raysphere, [:rdir, :rorig, :scenter, :sradius],
                                 [:doesintersect, :t0, :t1])
  size3 = add_sub_arr!(rayint, source((batch_size, width * height, 3)))
  size1 = add_sub_arr!(rayint, source((batch_size, width * height, 1)))
  sz1 = ◃(size1, 1)
  sz3 = ◃(size3, 1)

  dotarr = dot_arr()
  rdir, rorig, scenter, sradius, doesintersect, t0◂, t1◂ = ⬨(rayint)
  # Constants
  zerosscalarsarr = add_sub_arr!(rayint, source(0.0))
  falsessarr = add_sub_arr!(rayint, source(false))
  truessarr = add_sub_arr!(rayint, source(true))

  zerosscalar = ◃(zerosscalarsarr, 1)
  falses = ◃(falsessarr, 1)
  trues = ◃(truessarr, 1)

  l = exbcast(scenter, sz3) - rorig    # [batch_size, width * height, 3]
  tca = dotarr(l, rdir)         # [batch_size, width * height, 1]
  radius2 = sradius * sradius   # [batch_size, 1]
  d2 = dotarr(l, l) - tca * tca     # [batch_size, width * height, 1]
  cond1 = tca < exbcast(zerosscalar, sz1) # [batch_size, width * height, 1]

  # Output 0: doesintersect
  cond2 = d2 > exbcast(radius2, sz1)     # [batch_size, width * height, 1]
  # [batch_size, width * height, 1]
  ifelsedoesintersect = ifelse(cond2, exbcast(falses, sz1), exbcast(trues, sz1))
  ifelse2 = ifelse(cond1, exbcast(falses, sz1), ifelsedoesintersect)
  ifelse2 ⥅ doesintersect

  # Output 1: t0
  r2d2 = exbcast(radius2, sz1) - d2  # [batch_size, width * height, 1]
  thc = sqrt(r2d2)                   # [batch_size, width * height, 1]
  t0 = tca - thc                     # [batch_size, width * height, 1]
  # [batch_size, width * height, 1]
  t0out = ifelse(cond1, exbcast(zerosscalar, sz1), ifelse(cond2, exbcast(zerosscalar, sz1), t0))

  # Output 2: t1
  t1 = tca + thc                  # [batch_size, width * height, 1]
  t1out = ifelse(cond1, exbcast(zerosscalar, sz1), ifelse(cond2, exbcast(zerosscalar, sz1), t1))
  t0out ⥅ t0◂
  t1out ⥅ t1◂
  @assert is_wired_ok(rayint)
  rayint
end

function leastpositive(shape, xs...)
  lp = first(xs)
  for x in xs[2:end]
    xsispos = x > zeros(Float64, shape)
    lp = ifelse(xsispos, ifelse(x > lp, lp, x), lp)
  end
  lp
end

"Renders spheres, just black and white renderer"
function trc(nspheres=3, batch_size=1, width=100, height=100)
  rayintersectarr = rayintersect_arr(batch_size, width, height)
  scenters = [Symbol(:scenter, i) for i = 1:nspheres]
  sradii = [Symbol(:sradius, i) for i = 1:nspheres]
  trcarr = CompArrow(:trccarr,
                      vcat([:rorig, :rdir], scenters, sradii),
                      #[:doesintersect]
                      Symbol[]
                      )
  scenters▹ = map(nm->⬨(trcarr, nm), scenters)
  sradii▹ = map(nm->⬨(trcarr, nm), sradii)
  rdir▹ = ⬨(trcarr, :rdir)
  rorig▹ = ⬨(trcarr, :rorig)
  allts = []
  allhits = []

  for i = 1:length(scenters▹)
    intersect◃s = rayintersectarr(rdir▹, rorig▹, scenters▹[i], sradii▹[i])
    hit◃, t0◃, t1◃ = intersect◃s
    push!(allts, t0◃)
    push!(allts, t1◃)
    push!(allhits, hit◃)
  end
  foreach(link_to_parent!, allts)
  foreach(link_to_parent!, allhits)
  @assert is_valid(trcarr)
  return trcarr
  # 
  #
  # doesintersect = |(allhits...) # Should be logical OR
  # doesintersect ⥅ ◃(trcarr, 1)
  # foreach(link_to_parent!, allts)
  #
  # # closest = leastpositive(scalarsize, allts...)
  # # closest ⥅ ◃(trcarr, 2)
  # @assert is_wired_ok(trcarr)
  # trcarr
end

function rtabv(batch_size=1, width=100, height=100)
  nmabv = NmAbValues(:sradius => AbValues(:size => Size([batch_size, 1, 1])),
                     :scenter => AbValues(:size => Size([batch_size, 1, 3])),
                     :rdir => AbValues(:size => Size([batch_size, width * height, 3])),
                     :rorig => AbValues(:size => Size([batch_size, width * height, 3])),
                     :doesintersect => AbValues(:size => Size([batch_size, width * height, 1])),
                     :t0 => AbValues(:size => Size([batch_size, width * height, 1])),
                     :t1 => AbValues(:size => Size([batch_size, width * height, 1])))
end

function trcabv(nspheres=3, batch_size=1, width=100, height=100)
  nmabv = NmAbValues(:rdir => AbValues(:size => Size([batch_size, width * height, 3])),
                     :rorig => AbValues(:size => Size([batch_size, width * height, 3])),
                     :doesintersect => AbValues(:size => Size([batch_size, width * height, 1])))
  for i = 1:nspheres
    nmabv[Symbol(:scenter, i)] = AbValues(:size => Size([batch_size, 1, 3]))
    nmabv[Symbol(:sradius, i)] = AbValues(:size => Size([batch_size, 1, 1]))
  end
  nmabv
end
