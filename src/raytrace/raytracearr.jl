using TensorFlowTarget

function dot_arr()
  dotarr = CompArrow(:dot, [:xs, :ys], [:dot])
  xs, ys, dot = ⬨(dotarr)
  reducesum = Arrows.ReduceSumArrow(3, true)
  reducesum(map(*, xs, ys)) ⥅ ◃(dotarr, 1)
  @assert is_wired_ok(dotarr)
  dotarr
end

# const dotarr = dot_arr()

"Ray Sphere Intersection"
function rayintersect_arr(vec3size, scalarsize)
  rayint = CompArrow(:raysphere, [:rdir, :rorig, :scenter, :sradius],
                                 [:doesintersect, :t0, :t1])
  dotarr = dot_arr()
  rdir, rorig, scenter, sradius, doesintersect, t0◂, t1◂ = ⬨(rayint)
  # Constants
  zerosscalar = zeros(Float64, scalarsize)
  falses = fill(false, scalarsize)
  trues = fill(true, scalarsize)

  l = scenter - rorig
  tca = dotarr(l, rdir)
  radius2 = sradius * sradius
  d2 = dotarr(l, l) - tca * tca
  cond1 = tca < zeros(Float64, scalarsize)
  cond2 = d2 > radius2

  # Output 0: doesintersect
  ifelsedoesintersect = ifelse(cond2, falses, trues)
  ifelse2 = ifelse(cond1, falses, ifelsedoesintersect)
  ifelse2 ⥅ doesintersect

  # Output 1: t0
  r2d2 = radius2 - d2
  thc = sqrt(r2d2)
  t0 = tca - thc
  t0out = ifelse(cond1, zerosscalar, ifelse(cond2, zerosscalar, t0))

  # Output 2: t1
  t1 = tca + thc
  t1out = ifelse(cond1, zerosscalar, ifelse(cond2, zerosscalar, t1))
  t0out ⥅ t0◂
  t1out ⥅ t1◂
  @assert is_wired_ok(rayint)
  rayint
end

"Ray Sphere Intersection"
function rayintersect_arr_bcast()
  rayint = CompArrow(:raysphere, [:rdir, :rorig, :scenter, :sradius],
                                 [:doesintersect, :t0, :t1])
  dotarr = dot_arr()
  rdir, rorig, scenter, sradius, doesintersect, t0◂, t1◂ = ⬨(rayint)
  # Constants
  zerosscalarsarr = add_sub_arr!(rayint, source(0.0))
  falsessarr = add_sub_arr!(rayint, source(false))
  truessarr = add_sub_arr!(rayint, source(true))
  zerosscalar = ◃(zerosscalarsarr, 1)
  falses = ◃(falsessarr, 1)
  trues = ◃(truessarr, 1)

  l = bcast(scenter) - rorig    # [batch_size, width * height, 3]
  tca = dotarr(l, rdir)             # [batch_size, width * height, 1]
  radius2 = sradius * sradius       # [batch_size, 1]
  d2 = dotarr(l, l) - tca * tca     # [batch_size, width * height, 1]
  cond1 = tca < bcast(zerosscalar) # [batch_size, width * height, 1]
  cond2 = d2 > bcast(radius2)     # [batch_size, width * height, 1]

  # Output 0: doesintersect
  # [batch_size, width * height, 1]
  ifelsedoesintersect = ifelse(cond2, bcast(falses), bcast(trues))
  ifelse2 = ifelse(cond1, bcast(falses), ifelsedoesintersect)
  ifelse2 ⥅ doesintersect

  # Output 1: t0
  r2d2 = bcast(radius2) - d2  # [batch_size, width * height, 1]
  thc = sqrt(r2d2)                # [batch_size, width * height, 1]
  t0 = tca - thc                  # [batch_size, width * height, 1]
  # [batch_size, width * height, 1]
  t0out = ifelse(cond1, bcast(zerosscalar), ifelse(cond2, bcast(zerosscalar), t0))

  # Output 2: t1
  t1 = tca + thc                  # [batch_size, width * height, 1]
  t1out = ifelse(cond1, bcast(zerosscalar), ifelse(cond2, bcast(zerosscalar), t1))
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

function trc(nspheres::Integer, vec3size, scalarsize)
  rayintersectarr = rayintersect_arr(vec3size, scalarsize)
  scenters = [Symbol(:scenter, i) for i = 1:nspheres]
  sradii = [Symbol(:sradius, i) for i = 1:nspheres]
  trcarr = CompArrow(:trccarr,
                      vcat([:rorig, :rdir], scenters, sradii),
                      [:didhit, :closest])
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
  didhit = +(allhits...)
  closest = leastpositive(scalarsize, allts...)
  didhit ⥅ ◃(trcarr, 1)
  closest ⥅ ◃(trcarr, 2)
  @assert is_wired_ok(trcarr)
  trcarr
end

function test_raytrace2()
  width = 6
  height = 4
  batch_size = 2
  vec3size = (batch_size, width * height, 3)
  scalarsize = (batch_size, width * height, 1) # (batch_size, w * h)
  outimgsz = (batch_size, width * height, 1)
  rsarr = rayintersect_arr(vec3size, scalarsize)
  vec3nms = [:rdir, :rorig, :scenter]
  vec3⬨s = [⬨(rsarr, nm) for nm in vec3nms]
  scalarnms = [:sradius, :doesintersect, :t0, :t1]
  scalar⬨s = [⬨(rsarr, nm) for nm in scalarnms]

  d1 = Dict{SubPort, Arrows.AbValues}(vec3▹ => Arrows.AbValues(:size => Size(vec3size)) for vec3▹ in vec3⬨s)
  d2 = Dict{SubPort, Arrows.AbValues}(scalar⬨ => Arrows.AbValues(:size => Size(scalarsize)) for scalar⬨ in scalar⬨s)
  rsarr, d1, d2
end

function namesz(arr::Arrow, dct::Dict{Symbol, Size})
  Dict{SubPort, AbValues}(⬨(arr, k) => AbValues(:size => v) for (k,v) in dct)
end

function test_sizes(batch_size=2, width=5, height=5)
  rsarr = rayintersect_arr_bcast()
  szs = Dict(:sradius => Size([batch_size, 1]),
             :scenter => Size([batch_size, 3]),
             :rdir => Size([batch_size, width * height, 3]),
             :rorig => Size([batch_size, width * height, 3]),
             :doesintersect => Size([batch_size, width * height, 1]),
             :t0 => Size([batch_size, width * height, 1]),
             :t1 => Size([batch_size, width * height, 1]))
  rsarr = rayintersect_arr_bcast()
  rsarr, traceprop!(rsarr, namesz(rsarr, szs))
end

function test_rayintersect(width = 6, height = 4, batch_size = 2)
  vec3size = (batch_size, width * height, 3)
  scalarsize = (batch_size, width * height, 1) # (batch_size, w * h)
  outimgsz = (batch_size, width * height, 1)

  rsarr = rayintersect_arr(vec3size, scalarsize)
  vec3nms = [:rdir, :rorig, :scenter]
  vec3⬨s = [⬨(rsarr, nm) for nm in vec3nms]
  scalarnms = [:sradius, :doesintersect, :t0, :t1]
  scalar⬨s = [⬨(rsarr, nm) for nm in scalarnms]

  d1 = Dict{SubPort, Arrows.AbValues}(vec3▹ => Arrows.AbValues(:size => Size(vec3size)) for vec3▹ in vec3⬨s)
  d2 = Dict{SubPort, Arrows.AbValues}(scalar⬨ => Arrows.AbValues(:size => Size(scalarsize)) for scalar⬨ in scalar⬨s)
  invert(rsarr, inv, merge(d1, d2))
end

function test_trc()
  rsarr(rand(vec3size...), rand(vec3size...), rand(vec3size...), 1.0)
  # TensorFlowTarget.Graph(rsarr)
  nspheres = 3
  trcarr = trc(nspheres, vec3size, scalarsize)
  scenters = [rand(vec3size...) for i = 1:nspheres]
  sradii = [rand(scalarsize...) for i = 1:nspheres]
  trcarr

  scenters = [Symbol(:scenter, i) for i = 1:nspheres]
  scenters▹s = map(nm->⬨(trcarr, nm), scenters)
  sradii = [Symbol(:sradius, i) for i = 1:nspheres]
  sradii▹s = map(nm->⬨(trcarr, nm), sradii)
  rdir▹ = ⬨(trcarr, :rdir)
  rorig▹ = ⬨(trcarr, :rorig)

  tvals1 = Dict{SubPort, Arrows.AbValues}(vec▹ => Arrows.AbValues(:size => Size(vec3size)) for vec▹ in vcat(scenters▹s, rdir▹, rorig▹))
  tvals2 = Dict{SubPort, Arrows.AbValues}(scal▹ => Arrows.AbValues(:size => Size(scalarsize)) for scal▹ in sradii▹s)
  tvals3 = Dict{SubPort, Arrows.AbValues}(◃(trcarr, 1) => Arrows.AbValues(:size => Size(outimgsz)))
  invert(trcarr, inv, merge(tvals1, tvals2, tvals3))
  # trcarr(rand(vec3size...), rand(shape...), scenters..., sradii...)
end
