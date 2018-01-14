# https://www.scratchapixel.com/code/upload/introduction-rendering/raytracer.cpp

# TODO:
# Drop Type parameters
# Make mutable immutable
# use sqr instead of ^2
# Use ifelse instead of if
# PI for less than/greater than
# Do it without infinity
# Memory leak somewhere?

"A 3 point vector"
Vec3 = Vector
Point = Vector

"A ray with origin `orig` and "
struct Ray
  orig::Vec3
  dir::Vec3
end

"A sphere"
struct Sphere
  center::Point  # position of center the sphere
  radius         # radius of sphere
  surface_color  # color of surface
  reflection
  transparency
  emission_color
end

"Result of intersection between ray and object"
mutable struct Intersection
  doesintersect
  t0
  t1
end

"Linear interpolation between `a` and `b` by factor `mix`"
mix(a, b, mix::Real) = b * mix + a * (1 - mix)

"norm(x)^2"
dot_self(x) = dott(x, x)

"Dot product (without BLAS etc for generality)"
dott(xs, ys) = sum(xs .* ys)

"normalized x: `x/norm(x)`"
simplenormalize(x::Vector) = x / sqrt(dot_self(x))

"x iff x > 0 else 0"
rlu(x) = max(zero(x), x)

function rayintersect(r::Ray, s::Sphere)::Intersection
  s.center
  l = s.center - r.orig
  tca = dott(l, r.dir)
  radius2 = s.radius^2
  tca

  if tca < 0
    return Intersection(tca, 0.0, 0.0)
  end

  d2 = dott(l, l) - tca * tca
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

  # Determine whether this ray hits any of the spheres, and if so, which one
  hit = false
  sphere = spheres[1] # 1 is arbitrary
  for (i, target_sphere) in enumerate(spheres)
    t0 = Inf
    t1 = Inf
    r
    inter = rayintersect(r, target_sphere)
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

  surface_color = Vec3([0.0, 0.0, 0.0])
  phit = r.orig + r.dir * tnear
  nhit = phit - sphere.center
  nhit = simplenormalize(nhit)

  # If the normal and the view direction are not opposite to each other
  # reverse the normal direction. That also means we are inside the sphere so set
  # the inside bool to true. Finally reverse the sign of IdotN which we want
  # positive.
  bias = 1e-4;   # add some bias to the point from which we will be tracing
  inside = false

  if dott(r.dir, nhit) > 0.0
    nhit = -nhit
    inside = true
  end

  if ((sphere.transparency > 0.0 || sphere.reflection > 0.0) && depth < 1)
    minusrdir = r.dir * -1.0
    facingratio = dott(minusrdir, nhit)

    # change the mix value to tweak the effect
    fresneleffect = mix((1.0 - facingratio)^3, 1.0, 0.1)
    # @show facingratio, fresneleffect, -r.dir, nhit
    # compute reflection direction (not need to normalize because all vectors
    # are already normalized)
    refldir = r.dir - nhit * 2 * dott(r.dir, nhit)
    refldir = simplenormalize(refldir);
    reflection = trc(Ray(phit + nhit * bias, refldir), spheres, depth + 1)
    refraction = Vec3([0.0, 0.0, 0.0])

    # the result is a mix of reflection and refraction (if the sphere is transparent)
    prod = reflection * fresneleffect
    surface_color = map(*, prod, sphere.surface_color)
  else
    for i = 1:length(spheres)
      if spheres[i].emission_color[1] > 0.0
        # this is a light
        transmission = 1.0
        lightDirection = spheres[i].center - phit
        lightDirection = normalize(lightDirection)

        for j = 1:length(spheres)
          if (i != j)
            r2 = Ray(phit + nhit * bias, lightDirection)
            inter = rayintersect(r2, spheres[j])
            if (inter.doesintersect > 0)
              transmission = 0.0
            end
          end
        end
        lhs = sphere.surface_color * transmission * rlu(dott(nhit, lightDirection))
        surface_color += map(*, lhs, spheres[i].emission_color)
      end
    end
  end
  surface_color + sphere.emission_color
end

"Render `spheres` to image of given `width` and `height`"
function render(spheres::Vector{<:Sphere},
                width::Integer=480,
                height::Integer=320,
                fov::Real=30.0)
  inv_width = 1 / width
  angle = tan(pi * 0.5 * fov / 100.0)
  inv_height = 1 / height
  aspect_ratio = width / height

  image = zeros(width, height, 3)
  for y = 1:height, x = 1:width
    xx = (2 * ((x + 0.5) * inv_width) - 1) * angle * aspect_ratio
    yy = (1 - 2 * ((y + 0.5) * inv_height)) * angle
    minus1 = -1.0
    raydir = simplenormalize(Vec3([xx, yy, -1.0]))
    pixel = trc(Ray(Vec3([0.0, 0.0, 0.0]), raydir), spheres, 0)
    image[x, y, :] = pixel
    # trc(Ray(Vec3([0.0, 0.0, 0.0]), raydir), spheres, 0)
    zero = 0.0
  end
  image
end
