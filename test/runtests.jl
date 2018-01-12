exclude = []
test_dir = joinpath(Pkg.dir("AlioZoo"), "test", "tests")
tests = setdiff(readdir(test_dir), exclude)
print_with_color(:blue, "Running tests:\n")

# Single thread
srand(345679)
res = map(tests) do t
  println("Testing: ", t)
  include(joinpath(test_dir, t))
  nothing
end

# print method ambiguities
println("Potentially stale exports: ")
display(Base.Test.detect_ambiguities(AlioZoo))
println()
