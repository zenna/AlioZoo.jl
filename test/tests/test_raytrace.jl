import AlioZoo: render, Sphere, Vec3
import ImageView
import Colors

"Render an example scene and display it"
function render_example_spheres()
  spheres = example_spheres()
  render(spheres)
end

"Create an rgb image from a 3D matrix (w, h, c)"
function rgbimg(img)
  w = size(img)[1]
  h = size(img)[2]
  clrimg = Array{Colors.RGB}(w, h)
  for i = 1:w
    for j = 1:h
      clrimg[i,j] = Colors.RGB(img[i,j,:]...)
    end
  end
  clrimg
end

function test_show_img()
  img = render_example_spheres()
  ImageView.imshow(rgbimg(img), axes=(2,1))
end
