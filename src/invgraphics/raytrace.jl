# From:
# https://www.scratchapixel.com/code/upload/introduction-ren
dering/raytracer.cpp

# 1.

"A 3 point vector"
Vec3{T} = Vector{T}
Point{T} = Vector{T}

"A ray with origin `orig` and "
struct Ray{T}
  orig::Vec3{T}
  dir::Vec3{T}
end

"A sphere"
struct Sphere{T}
  center::Point{T} # position of center the sphere
  radius::T     # radius of sphere
  surface_color::Vec3{T}  # color of surface
  reflection::T
  transparency::T
  emission_color::T
end

"Result of intersection between ray and object"
mutable struct Intersection{T}
  doesintersect::T
  t0::T
  t1::T
end

"Linear interpolation between `a` and `b` by factor `mix`"
mix(a, b, mix::Real) = b * mix + a * (1 - mix)

"norm(x)^2"
dot_self(x) = dot(x, x)

"normalized x: `x/norm(x)`"
simplenormalize(x::Vector) = x / sqrt(dot_self(x))

function rayintersect(r::Ray, s::Sphere)::Intersection
  s.center
  l = s.center - r.orig
  tca = dot(l, r.dir)
  radius2 = s.radius^2
  tca

  if tca < 0
    return Intersection(tca, 0.0, 0.0)
  end

  d2 = dot(l, l) - tca * tca
  if d2 > radius2
    return Intersection(s.radius - d2, 0.0, 0.0)
  end

  thc = sqrt(radius2 - d2)
  t0 = tca - thc
  t1 = tca + thc
  Intersection(radius2 - d2, t0, t1)
end


function trc(r::Ray, spheres::Vector{<:Sphere}, depth::Integer)
  tnear = Inf
  areintersections = false

  hit = false
  for (i, sphere) in enumerate(spheres)
    t0 = Inf
    t1 = Inf
    r
    inter = rayintersect(r, sphere)
    if inter.doesintersect > 0
      if inter.t0 < 0
        inter.t0 = t1
      end
      if inter.t0 < tnear
        tnear = inter.t0
        sphere = spheres[i]
        hit = true
      end
    end
  end

  # If no sphere, then output 1,
  if hit
    1.0
  else
    0.0
  end
end

function render(spheres::Vector{<:Sphere},
                width::Integer=480,
                height::Integer=320,
                fov::Real=30.0)
  @show inv_width = 1 / width
  @show angle = tan(pi * 0.5 * fov / 100.0)
  @show inv_height = 1 / height
  @show aspect_ratio = width / height

  image = zeros(width, height)
  for y = 1:height, x = 1:width
    xx = (2 * ((x + 0.5) * inv_width) - 1) * angle * aspect_ratio
    yy = (1 - 2 * ((y + 0.5) * inv_height)) * angle
    minus1 = -1.0
    raydir = simplenormalize(Vec3([xx, yy, -1.0]))
    image[x, y] = trc(Ray(Vec3([0.0, 0.0, 0.0]), raydir), spheres, 0)
    zero = 0.0
  end
  image
end

"Render an example scene and display it"
function example()
  sphere = Sphere(Point([10.0, -4.0, 10.0]),
                  10.0,
                  Vec3([1.0, 1.0, 1.0]),
                  1.0,
                  0.5,
                  0.5)
  spheres = example_spheres()
  render(spheres)
end

using Images
img = example()

colorview(50, 50, Gray, img)
"A sphere"
struct Sphere{T}
  center::Point{T} # position of center the sphere
  radius::T     # radius of sphere
  surface_color::Vec3{T}  # color of surface
  reflection::T
  transparency::T
  emission_color::T
end

function example_spheres()
  [Sphere(Vec3([0.0, -10004, -20]), 10000.0, Vec3([0.20, 0.20, 0.20]), 0.0, 0.0, 0.0),
   Sphere(Vec3([0.0,      0, -20]),     4.0, Vec3([1.00, 0.32, 0.36]), 1.0, 0.5, 0.0),
   Sphere(Vec3([5.0,     -1, -15]),     2.0, Vec3([0.90, 0.76, 0.46]), 1.0, 0.0, 0.0),
   Sphere(Vec3([5.0,      0, -25]),     3.0, Vec3([0.65, 0.77, 0.97]), 1.0, 0.0, 0.0),
   Sphere(Vec3([-5.5,      0, -15]),    3.0, Vec3([0.90, 0.90, 0.90]), 1.0, 0.0, 0.0)]
 end
