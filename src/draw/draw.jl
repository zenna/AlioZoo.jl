k(x) = x < 4 ? 1.0 : 0.0

function distance(x, y, a, b, c)
  abs(a*x + b*y + c) / sqrt(a^2 + b^2)
end

dist2(vx, vy, wx, wy) = sqr(vx - wx) + sqr(vy - wy)

"Minimum distance between line segment vw and point p"
function distance(p1, p2, x0, y0)
  px, py = x0, y0
  vx, vy = p1
  wx, wy = p2
  px = Float64(px)
  py = Float64(py)
  wx = Float64(wx)
  wy = Float64(wy)
  vx = Float64(vx)
  vy = Float64(vy)

  # If L2 is a point 
  l2 = dist2(vx, vy, wx, wy)
  if (l2 == 0)
    return dist2(px, py, vx, vy)
  end
  t = ((px - vx) * (wx - vx) + (py - vy) * (wy - vy)) / l2;
  t = max(0, min(1, t))
  x = vx + t * (wx - vx)
  y = vy + t * (wy - vy)
  sqrt(dist2(x0, y0, x, y))
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

stroketoline(stroke) = [stroke[1][1], stroke[1][end]], [stroke[2][1], stroke[2][end]]

function drawstrokes(strokes, width, height)
  A = Array{Float64}(width, height)
  @show length(strokes)
  for x = 1:width, y = 1:height
    dists = []
    for stroke in strokes
      l1, l2 = stroketoline(stroke)
      # @grab l2 
      push!(dists, distance(l1, l2, x, y))
    end
    A[x, y] = k(minimum(dists))
  end
  A
end

function loaddata(;imgtype = "laptop",
                  datapath = joinpath(ENV["DATADIR"], "quickdraw",
                                      "full_simplified_$(imgtype).ndjson"))
  f = open(datapath)
  drawings = map(eachline(f)) do l1
    parsed = JSON.parse(l1)
    lines = parsed["drawing"]
    # img = draw(1, 1, 3, 100, 100)
  end
end

function drawdata(lines)
  img = drawstrokes(lines, 256, 256)
  imshow(img)
end 

function drawarr(width::Integer, height::Integer, nlines::Integer)
  c = CompArrow(:quickdraw,
                [Symbol(:line_, i) for i = 1:nlines], 
                [Symbol(:x, i, :_, j) for i=1:width, j=1:height])
  linesprts = ▹(c)
  lines = reshape(linesprts)
end