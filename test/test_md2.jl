using Arrows
using AlioZoo
using Base.Test


function test_md2()
    carr = AlioZoo.md2hash(2)
    @test carr(1:16...) == (148, 97, 205, 220, 205, 167, 218, 220,
                            138, 57, 196, 176, 107, 2, 205, 199)
    inv_carr = carr |> Arrows.duplify |> Arrows.invert
    md2_pgf = carr |> pgf
    @test (md2_pgf >> inv_carr)(1:16...) == (1:16...)
end

test_md2()
