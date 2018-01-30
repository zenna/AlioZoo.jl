using ImageView

function distance(x, y, a, b, c)
  abs(a*x + b*y + c) / sqrt(a^2 + b^2)
end

function draw(a, b, c, width, height, λ=10)
  A = Array{Float64}(width, height)
  B = Array{Float64}(width, height)
  for x = 1:width, y = 1:height
    B[x, y] = distance(x, y, a, b, c)
    A[x, y] = k(distance(x, y, a, b, c))
  end
  A, B
end


k(x) = x < 10 ? 1.0 : 0.0


# img = draw(1, 1, 3, 100, 100)