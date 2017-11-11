# using ImageView
# using Arrows
# # From:
# # https://www.scratchapixel.com/code/upload/introduction-rendering/raytracer.cpp
#
# # TODO:
# # Drop Type parameters
# # Make mutable immutable
# # use sqr instead of ^2
# # Use ifelse instead of if
# # PI for less than/greater than
# # Do it without infinity
# # Memory leak somewhere?
#
# "A 3 point vector"
# Vec3 = Vector
# Point = Vector
#
# "A ray with origin `orig` and "
# struct Ray
#   orig::Vec3
#   dir::Vec3
# end
#
# "A sphere"
# struct Sphere
#   center::Point  # position of center the sphere
#   radius         # radius of sphere
#   surface_color  # color of surface
#   reflection
#   transparency
#   emission_color
# end
#
# "Result of intersection between ray and object"
# mutable struct Intersection
#   doesintersect
#   t0
#   t1
# end
#
# "Linear interpolation between `a` and `b` by factor `mix`"
# mix(a, b, mix::Real) = b * mix + a * (1 - mix)
#
# "norm(x)^2"
# dot_self(x) = dott(x, x)
# dott(xs, ys) = sum(xs .* ys)
#
# "normalized x: `x/norm(x)`"
# simplenormalize(x::Vector) = x / sqrt(dot_self(x))
#
#

function dot_arr()
  dotarr = CompArrow(:dot, [:xs, :ys], [:dot])
  xs, ys, dot = ⬨(dotarr)
  reducesum = Arrows.ReduceSumArrow(1000, true)
  reducesum(map(*, xs, ys)) ⥅ ◃(dotarr, 1)
  @assert is_wired_ok(dotarr)
  dotarr
end

const dotarr = dot_arr()
# dot_arr()

"Ray Sphere Intersection"
function rayintersectarr(vecsize)
  rayint = CompArrow(:raysphere, [:rdir, :rorig, :scenter, :sradius],
                                 [:doesintersect, :t0, :t1])
  rdir, rorig, scenter, sradius, doesintersect, t0, t1 = ⬨(rayint)
  l = scenter - rorig
  tca = dotarr(l, rdir)
  radius2 = SqrArrow()(sradius)
  d2 = dotarr(l, l) - tca * tca
  cond1 = tca < zeros(Float64, vecsize)
  cond2 = d2 > radius2
  r2d2 = radius2 - d2
  ifelsedoesintersect = ifelse(cond2, sradius - d2, r2d2)
  ifelse2 = ifelse(cond1, tca, ifelsedoesintersect)
  ifelse2 ⥅ doesintersect
  ifelse2 ⥅ t0
  ifelse2 ⥅ t1
  @assert is_wired_ok(rayint)
  rayint
end

# "Ray Sphere Intersection"
# function rayintersectarr()
#   rayint = CompArrow(:raysphere, [:rdir, :rorig, :scenter, :sradius],
#                                  [:doesintersect, :t0, :t1])
#   rdir, rorig, scenter, sradius, doesintersect, t0, t1 = ⬨(rayint)
#   l = scenter - rorig
#   tca = dotarr(l, rdir)
#   radius2 = SqrArrow()(sradius)
#   d2 = map(-, dotarr(l, l), map(*, tca, tca))
#   cond1 = map(<, tca, 0.0)
#   cond2 = map(>, d2, radius2)
#   r2d2 = map(-, radius2, d2)
#
#   #
#   ifelsedoesintersect = map(ifelse, cond2, map(-, sradius, d2), r2d2)
#   ifelse2 = map(ifelse, cond1, tca, ifelsedoesintersect)
#   ifelse2 ⥅ doesintersect
#   ifelse2 ⥅ t0
#   ifelse2 ⥅ t1
#   @assert is_wired_ok(rayint)
#   rayint
# end

function test_raytrace()
  width = 3
  height = 4
  batch_size = 2
  shape = (batch_size, width * height, 3)
  rsarr = rayintersectarr(shape)
  rsarr(rand(shape...), rand(shape...), rand(shape...), 1.0)

end

#   # thc = sqrt(r2d2)
#
#
#
# function trc(r::Ray, spheres::Vector{<:Sphere}, depth::Integer)
#   tnear = Inf
#   areintersections = false
#
#   hit = false
#   for (i, sphere) in enumerate(spheres)
#     t0 = Inf
#     t1 = Inf
#     r
#     inter = rayintersect(r, sphere)
#     if inter.doesintersect > 0
#       if inter.t0 < 0
#         inter.t0 = t1
#       end
#       if inter.t0 < tnear
#         tnear = inter.t0
#         sphere = spheres[i]
#         hit = true
#       end
#     end
#   end
#
#   # If no sphere, then output 1,
#   if hit
#     1.0
#   else
#     0.0
#   end
# end
#
# function render(spheres::Vector{<:Sphere},
#                 width::Integer=480,
#                 height::Integer=320,
#                 fov::Real=30.0)
#   @show inv_width = 1 / width
#   @show angle = tan(pi * 0.5 * fov / 100.0)
#   @show inv_height = 1 / height
#   @show aspect_ratio = width / height
#
#   image = zeros(width, height)
#   for y = 1:height, x = 1:width
#     xx = (2 * ((x + 0.5) * inv_width) - 1) * angle * aspect_ratio
#     yy = (1 - 2 * ((y + 0.5) * inv_height)) * angle
#     minus1 = -1.0
#     raydir = simplenormalize(Vec3([xx, yy, -1.0]))
#     image[x, y] = trc(Ray(Vec3([0.0, 0.0, 0.0]), raydir), spheres, 0)
#     zero = 0.0
#   end
#   image
# end
#
# "Render an example scene and display it"
# function example(spheres)
#   sphere = Sphere(Point([10.0, -4.0, 10.0]),
#                   10.0,
#                   Vec3([1.0, 1.0, 1.0]),
#                   1.0,
#                   0.5,
#                   0.5)
#   spheres = example_spheres()
#   render(spheres)
# end
#
# function real_example_spheres()
#   [Sphere(Vec3([0.0, -10004, -20]), 10000.0, Vec3([0.20, 0.20, 0.20]), 0.0, 0.0, 0.0),
#    Sphere(Vec3([0.0,      0, -20]),     4.0, Vec3([1.00, 0.32, 0.36]), 1.0, 0.5, 0.0),
#    Sphere(Vec3([5.0,     -1, -15]),     2.0, Vec3([0.90, 0.76, 0.46]), 1.0, 0.0, 0.0),
#    Sphere(Vec3([5.0,      0, -25]),     3.0, Vec3([0.65, 0.77, 0.97]), 1.0, 0.0, 0.0),
#    Sphere(Vec3([-5.5,      0, -15]),    3.0, Vec3([0.90, 0.90, 0.90]), 1.0, 0.0, 0.0)]
# end
#
# function subport_example_spheres()
#   carr = CompArrow(:raytrace, [:x, :y, :z], Symbol[])
#   x, y, z = ⬨(carr)
#   [Sphere(Vec3([x, y, z]), 10000.0, Vec3([0.20, 0.20, 0.20]), 0.0, 0.0, 0.0)]
# end
# ## Example
#
# img = example()
