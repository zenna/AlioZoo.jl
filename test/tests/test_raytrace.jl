import AlioZoo: render, Sphere, Vec3

"Render an example scene and display it"
function render_example_spheres()
  spheres = example_spheres()
  render(spheres)
end

"Some example spheres which should create actual image"
function example_spheres()
  [Sphere(Vec3([0.0, -10004, -20]), 10000.0, Vec3([0.20, 0.20, 0.20]), 0.0, 0.0, 0.0),
   Sphere(Vec3([0.0,      0, -20]),     4.0, Vec3([1.00, 0.32, 0.36]), 1.0, 0.5, 0.0),
   Sphere(Vec3([5.0,     -1, -15]),     2.0, Vec3([0.90, 0.76, 0.46]), 1.0, 0.0, 0.0),
   Sphere(Vec3([5.0,      0, -25]),     3.0, Vec3([0.65, 0.77, 0.97]), 1.0, 0.0, 0.0),
   Sphere(Vec3([-5.5,      0, -15]),    3.0, Vec3([0.90, 0.90, 0.90]), 1.0, 0.0, 0.0)]
end

function subport_example_spheres()
  carr = CompArrow(:raytrace, [:x, :y, :z], Symbol[])
  x, y, z = ⬨(carr)
  [Sphere(Vec3([x, y, z]), 10000.0, Vec3([0.20, 0.20, 0.20]), 0.0, 0.0, 0.0)]
end

img = render_example_spheres()
