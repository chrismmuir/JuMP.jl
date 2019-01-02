#  Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
#############################################################################
# JuMP
# An algebraic modeling language for Julia
# See http://github.com/JuliaOpt/JuMP.jl
#############################################################################
# test/print.jl
# Testing $fa pretty-printing-related functionality
#############################################################################
using JuMP
using Base.Test
import JuMP.REPLMode, JuMP.IJuliaMode
import JuMP.repl, JuMP.ijulia

# Helper function to test IO methods work correctly
function io_test(mode, obj, exp_str; repl=:both)
    if mode == REPLMode
        repl != :show  && @test sprint(print, obj) == exp_str
        repl != :print && @test sprint(show,  obj) == exp_str
    else
        @test sprint(show, "text/latex", obj) == string("\$\$ ",exp_str," \$\$")
    end
end

mutable struct NoMetaContainer{T,N} <: JuMP.JuMPContainer{T,N}
end

@testset "Printing" begin
    @testset "JuMPContainer with no field meta" begin
        @test_throws ErrorException JuMP.metadata(NoMetaContainer{Float64,2}())
    end

    @testset "JuMPContainer{Variable}" begin
        le, ge, fa = repl[:leq], repl[:geq], repl[:for_all]
        inset, dots = repl[:in], repl[:dots]
        infty, union = repl[:infty], repl[:union]

        m = Model()

        #------------------------------------------------------------------
        # Test bound printing
        @testset "bound printing" begin
        @variable(m,      bnd_free[2:5])
        @variable(m,      bnd_lowb[2:5] >= 2)
        @variable(m,      bnd_high[2:5] <= 5)
        @variable(m, 2 <= bnd_both[2:5] <= 5)
        @variable(m,      bnd_difflo[i=2:5] >= i)
        @variable(m,      bnd_diffup[i=2:5] <= i)
        @variable(m, i <= bnd_diffbo[i=2:5] <= 2i)
        @variable(m, i <= bnd_difflo_with_up[i=2:5] <= 5)
        @variable(m, 2 <= bnd_diffup_with_lo[i=2:5] <= i)

        io_test(REPLMode, bnd_free, "bnd_free[i] $fa i $inset {2,3,4,5}")
        io_test(REPLMode, bnd_lowb, "bnd_lowb[i] $ge 2 $fa i $inset {2,3,4,5}")
        io_test(REPLMode, bnd_high, "bnd_high[i] $le 5 $fa i $inset {2,3,4,5}")
        io_test(REPLMode, bnd_both, "2 $le bnd_both[i] $le 5 $fa i $inset {2,3,4,5}")
        io_test(REPLMode, bnd_difflo, "bnd_difflo[i] $ge $dots $fa i $inset {2,3,4,5}")
        io_test(REPLMode, bnd_diffup, "bnd_diffup[i] $le $dots $fa i $inset {2,3,4,5}")
        io_test(REPLMode, bnd_diffbo, "$dots $le bnd_diffbo[i] $le $dots $fa i $inset {2,3,4,5}")
        io_test(REPLMode, bnd_difflo_with_up, "$dots $le bnd_difflo_with_up[i] $le 5 $fa i $inset {2,3,4,5}")
        io_test(REPLMode, bnd_diffup_with_lo, "2 $le bnd_diffup_with_lo[i] $le $dots $fa i $inset {2,3,4,5}")

        io_test(IJuliaMode, bnd_free, "bnd_free_{i} \\quad\\forall i \\in \\{2,3,4,5\\}")
        io_test(IJuliaMode, bnd_lowb, "bnd_lowb_{i} \\geq 2 \\quad\\forall i \\in \\{2,3,4,5\\}")
        io_test(IJuliaMode, bnd_high, "bnd_high_{i} \\leq 5 \\quad\\forall i \\in \\{2,3,4,5\\}")
        io_test(IJuliaMode, bnd_both, "2 \\leq bnd_both_{i} \\leq 5 \\quad\\forall i \\in \\{2,3,4,5\\}")
        io_test(IJuliaMode, bnd_difflo, "bnd_difflo_{i} \\geq \\dots \\quad\\forall i \\in \\{2,3,4,5\\}")
        io_test(IJuliaMode, bnd_diffup, "bnd_diffup_{i} \\leq \\dots \\quad\\forall i \\in \\{2,3,4,5\\}")
        io_test(IJuliaMode, bnd_diffbo, "\\dots \\leq bnd_diffbo_{i} \\leq \\dots \\quad\\forall i \\in \\{2,3,4,5\\}")
        io_test(IJuliaMode, bnd_difflo_with_up, "\\dots \\leq bnd_difflo_with_up_{i} \\leq 5 \\quad\\forall i \\in \\{2,3,4,5\\}")
        io_test(IJuliaMode, bnd_diffup_with_lo, "2 \\leq bnd_diffup_with_lo_{i} \\leq \\dots \\quad\\forall i \\in \\{2,3,4,5\\}")
        end

        #------------------------------------------------------------------
        # Test index set printing
        @testset "index set printing" begin
        @variable(m, rng_unit1[1:10])  # Array{Variable}
        @variable(m, rng_unit2[-2:3])  # JuMPArray
        @variable(m, rng_unit3[[1:10;]])  # JuMPDict
        @variable(m, rng_step1[1:2:10])
        @variable(m, rng_step2[-2:5:10])
        @variable(m, rng_step3[1:5:3])
        @variable(m, rng_step4[0:2:2])
        @variable(m, arr_1[[:a,:b,:c]])
        @variable(m, arr_2[[:a,1,"test"]])
        @variable(m, arr_3[[:apple,:banana,:carrot,:diamonds]])
        @variable(m, rng2_1[1:10,[:a,:b,:c]])
        @variable(m, tri_1[i=1:3,j=i:3])
        @variable(m, tri_2[i=1:3,j=-i])
        @variable(m, tri_3[(i,j)=[(i,i+2) for i in 1:5],k=i:j])
        @variable(m, iter_1[keys(Dict(:a => 1))])

        io_test(REPLMode, rng_unit1, "rng_unit1[i] $fa i $inset {1,2,$dots,9,10}")
        io_test(REPLMode, rng_unit2, "rng_unit2[i] $fa i $inset {-2,-1,$dots,2,3}")
        io_test(REPLMode, rng_unit3, "rng_unit3[i] $fa i $inset {1,2,$dots,9,10}")
        io_test(REPLMode, rng_step1, "rng_step1[i] $fa i $inset {1,3,5,7,9}")
        io_test(REPLMode, rng_step2, "rng_step2[i] $fa i $inset {-2,3,8}")
        io_test(REPLMode, rng_step3, "rng_step3[i] $fa i $inset {1}")
        io_test(REPLMode, rng_step4, "rng_step4[i] $fa i $inset {0,2}")
        io_test(REPLMode, arr_1, "arr_1[i] $fa i $inset {a,b,c}")
        io_test(REPLMode, arr_2, "arr_2[i] $fa i $inset {a,1,test}")
        io_test(REPLMode, arr_3, "arr_3[i] $fa i $inset {apple,banana,carrot,diamonds}")
        io_test(REPLMode, rng2_1, "rng2_1[i,j] $fa i $inset {1,2,$dots,9,10}, j $inset {a,b,c}")
        io_test(REPLMode, tri_1, "tri_1[i,j] $fa i $inset {1,2,3}, j $inset {$dots}")
        io_test(REPLMode, tri_2, "tri_2[i,j] $fa i $inset {1,2,3}, j $inset {$dots}")
        if VERSION < v"0.6.0-dev.2505" # julia PR #20288
            io_test(REPLMode, tri_3, "tri_3[(i,j),k] $fa (i,j) $inset {(1,3),(2,4),(3,5),(4,6),(5,7)}, k $inset {$dots}")
        else
            io_test(REPLMode, tri_3, "tri_3[(i, j),k] $fa (i, j) $inset {(1, 3),(2, 4),(3, 5),(4, 6),(5, 7)}, k $inset {$dots}")
        end
        io_test(REPLMode, iter_1, "iter_1[i] $fa i $inset {a}")

        io_test(IJuliaMode, rng_unit1, "rng_unit1_{i} \\quad\\forall i \\in \\{1,2,\\dots,9,10\\}")
        io_test(IJuliaMode, rng_unit2, "rng_unit2_{i} \\quad\\forall i \\in \\{-2,-1,\\dots,2,3\\}")
        io_test(IJuliaMode, rng_unit3, "rng_unit3_{i} \\quad\\forall i \\in \\{1,2,\\dots,9,10\\}")
        io_test(IJuliaMode, rng_step1, "rng_step1_{i} \\quad\\forall i \\in \\{1,3,5,7,9\\}")
        io_test(IJuliaMode, rng_step2, "rng_step2_{i} \\quad\\forall i \\in \\{-2,3,8\\}")
        io_test(IJuliaMode, rng_step3, "rng_step3_{i} \\quad\\forall i \\in \\{1\\}")
        io_test(IJuliaMode, rng_step4, "rng_step4_{i} \\quad\\forall i \\in \\{0,2\\}")
        io_test(IJuliaMode, arr_1, "arr_1_{i} \\quad\\forall i \\in \\{a,b,c\\}")
        io_test(IJuliaMode, arr_2, "arr_2_{i} \\quad\\forall i \\in \\{a,1,test\\}")
        io_test(IJuliaMode, arr_3, "arr_3_{i} \\quad\\forall i \\in \\{apple,banana,carrot,diamonds\\}")
        io_test(IJuliaMode, rng2_1, "rng2_1_{i,j} \\quad\\forall i \\in \\{1,2,\\dots,9,10\\}, j \\in \\{a,b,c\\}")
        io_test(IJuliaMode, tri_1, "tri_1_{i,j} \\quad\\forall i \\in \\{1,2,3\\}, j \\in \\{\\dots\\}")
        io_test(IJuliaMode, tri_2, "tri_2_{i,j} \\quad\\forall i \\in \\{1,2,3\\}, j \\in \\{\\dots\\}")
        if VERSION < v"0.6.0-dev.2505" # julia PR #20288
            io_test(IJuliaMode, tri_3, "tri_3_{(i,j),k} \\quad\\forall (i,j) \\in \\{(1,3),(2,4),(3,5),(4,6),(5,7)\\}, k \\in \\{\\dots\\}")
        else
            io_test(IJuliaMode, tri_3, "tri_3_{(i, j),k} \\quad\\forall (i, j) \\in \\{(1, 3),(2, 4),(3, 5),(4, 6),(5, 7)\\}, k \\in \\{\\dots\\}")
        end
        io_test(IJuliaMode, iter_1, "iter_1_{i} \\quad\\forall i \\in \\{a\\}")
        end

        #------------------------------------------------------------------
        # Test category printing
        @testset "category printing" begin
        @variable(m, cat_bin[1:3], Bin)
        @variable(m, 2 <= cat_int[1:3] <= 5, Int)
        @variable(m, cat_semiint_both[2:3] >= 2, SemiInt)
        @variable(m, i <= cat_semiint_difflow[i=2:3] <= 4, SemiInt)
        @variable(m, 2 <= cat_semiint_diffup[i=2:3] <= i, SemiInt)
        @variable(m, i <= cat_semiint_none[i=2:3] <= 2i, SemiInt)
        @variable(m, cat_semicont_both[2:3] >= 2, SemiCont)
        @variable(m, i <= cat_semicont_difflow[i=2:3] <= 4, SemiCont)
        @variable(m, 2 <= cat_semicont_diffup[i=2:3] <= i, SemiCont)
        @variable(m, i <= cat_semicont_none[i=2:3] <= 2i, SemiCont)
        @variable(m, fixed_var[i=2:3] == i)

        io_test(REPLMode, cat_bin, "cat_bin[i] $inset {0,1} $fa i $inset {1,2,3}")
        io_test(REPLMode, cat_int, "2 $le cat_int[i] $le 5, integer, $fa i $inset {1,2,3}")
        io_test(REPLMode, cat_semiint_both, "cat_semiint_both[i] $inset {2,$dots,$infty} $union {0} $fa i $inset {2,3}")
        io_test(REPLMode, cat_semiint_difflow, "cat_semiint_difflow[i] $inset {$dots,$dots,4} $union {0} $fa i $inset {2,3}")
        io_test(REPLMode, cat_semiint_diffup, "cat_semiint_diffup[i] $inset {2,$dots,$dots} $union {0} $fa i $inset {2,3}")
        io_test(REPLMode, cat_semiint_none, "cat_semiint_none[i] $inset {$dots,$dots,$dots} $union {0} $fa i $inset {2,3}")
        io_test(REPLMode, cat_semicont_both, "cat_semicont_both[i] $inset [2,$infty] $union {0} $fa i $inset {2,3}")
        io_test(REPLMode, cat_semicont_difflow, "cat_semicont_difflow[i] $inset [$dots,4] $union {0} $fa i $inset {2,3}")
        io_test(REPLMode, cat_semicont_diffup, "cat_semicont_diffup[i] $inset [2,$dots] $union {0} $fa i $inset {2,3}")
        io_test(REPLMode, cat_semicont_none, "cat_semicont_none[i] $inset [$dots,$dots] $union {0} $fa i $inset {2,3}")
        io_test(REPLMode, fixed_var, "fixed_var[i] = $dots $fa i $inset {2,3}")

        io_test(IJuliaMode, cat_bin, "cat_bin_{i} \\in \\{0,1\\} \\quad\\forall i \\in \\{1,2,3\\}")
        io_test(IJuliaMode, cat_int, "2 \\leq cat_int_{i} \\leq 5, \\in \\mathbb{Z}, \\quad\\forall i \\in \\{1,2,3\\}")
        io_test(IJuliaMode, cat_semiint_both, "cat_semiint_both_{i} \\in \\{2,\\dots,\\infty\\} \\cup \\{0\\} \\quad\\forall i \\in \\{2,3\\}")
        io_test(IJuliaMode, cat_semiint_difflow, "cat_semiint_difflow_{i} \\in \\{\\dots,\\dots,4\\} \\cup \\{0\\} \\quad\\forall i \\in \\{2,3\\}")
        io_test(IJuliaMode, cat_semiint_diffup, "cat_semiint_diffup_{i} \\in \\{2,\\dots,\\dots\\} \\cup \\{0\\} \\quad\\forall i \\in \\{2,3\\}")
        io_test(IJuliaMode, cat_semiint_none, "cat_semiint_none_{i} \\in \\{\\dots,\\dots,\\dots\\} \\cup \\{0\\} \\quad\\forall i \\in \\{2,3\\}")
        io_test(IJuliaMode, cat_semicont_both, "cat_semicont_both_{i} \\in \\[2,\\infty\\] \\cup \\{0\\} \\quad\\forall i \\in \\{2,3\\}")
        io_test(IJuliaMode, cat_semicont_difflow, "cat_semicont_difflow_{i} \\in \\[\\dots,4\\] \\cup \\{0\\} \\quad\\forall i \\in \\{2,3\\}")
        io_test(IJuliaMode, cat_semicont_diffup, "cat_semicont_diffup_{i} \\in \\[2,\\dots\\] \\cup \\{0\\} \\quad\\forall i \\in \\{2,3\\}")
        io_test(IJuliaMode, cat_semicont_none, "cat_semicont_none_{i} \\in \\[\\dots,\\dots\\] \\cup \\{0\\} \\quad\\forall i \\in \\{2,3\\}")
        io_test(IJuliaMode, fixed_var, "fixed_var_{i} = \\dots \\quad\\forall i \\in \\{2,3\\}")
        end

        #------------------------------------------------------------------
        # Tests for particular issues
        @testset "Empty JuMPContainer printing (#124)" begin
        @variable(m, empty_free[1:0])
        io_test(REPLMode, empty_free, "Empty Array{Variable} (no indices)")
        io_test(IJuliaMode, empty_free, "Empty Array{Variable} (no indices)")
        @variable(m, empty_set[[]])
        io_test(REPLMode, empty_set, "empty_set (no indices)")
        io_test(IJuliaMode, empty_set, "empty_set (no indices)")
        end
    end


    @testset "JuMPContainer{Number}" begin
        # The same output for REPL and IJulia, so only testing one
        mod = Model()
        @variable(mod, u[2:1])
        @variable(mod, w[i=9:10, [:Apple,5,:Banana], j=-1:+1] == i*j)
        @variable(mod, x[i=9:11,j=99:101,k=3:4] == i*j*k)
        @variable(mod, y[i=9:11,j=i:11] == i*j)
        @variable(mod, z[i=[:a,'b'],j=1:3] == j)

        # Deal with hashing variations
        io_test(REPLMode, getvalue(u), """
    u: 1 dimensions:
      (no entries)""")
        if hash(5) < hash(:Apple)
            io_test(REPLMode, getvalue(w), """
    w: 3 dimensions:
    [ 9,:,:]
      [ 9, Apple,:]
        [ 9, Apple,-1] = -9.0
        [ 9, Apple, 0] = 0.0
        [ 9, Apple, 1] = 9.0
      [ 9,     5,:]
        [ 9,     5,-1] = -9.0
        [ 9,     5, 0] = 0.0
        [ 9,     5, 1] = 9.0
      [ 9,Banana,:]
        [ 9,Banana,-1] = -9.0
        [ 9,Banana, 0] = 0.0
        [ 9,Banana, 1] = 9.0
    [10,:,:]
      [10, Apple,:]
        [10, Apple,-1] = -10.0
        [10, Apple, 0] = 0.0
        [10, Apple, 1] = 10.0
      [10,     5,:]
        [10,     5,-1] = -10.0
        [10,     5, 0] = 0.0
        [10,     5, 1] = 10.0
      [10,Banana,:]
        [10,Banana,-1] = -10.0
        [10,Banana, 0] = 0.0
        [10,Banana, 1] = 10.0""", repl=:print)
        else
            io_test(REPLMode, getvalue(w), """
    w: 3 dimensions:
    [ 9,:,:]
      [ 9, Apple,:]
        [ 9, Apple,-1] = -9.0
        [ 9, Apple, 0] = 0.0
        [ 9, Apple, 1] = 9.0
      [ 9,     5,:]
        [ 9,     5,-1] = -9.0
        [ 9,     5, 0] = 0.0
        [ 9,     5, 1] = 9.0
      [ 9,Banana,:]
        [ 9,Banana,-1] = -9.0
        [ 9,Banana, 0] = 0.0
        [ 9,Banana, 1] = 9.0
    [10,:,:]
      [10, Apple,:]
        [10, Apple,-1] = -10.0
        [10, Apple, 0] = 0.0
        [10, Apple, 1] = 10.0
      [10,     5,:]
        [10,     5,-1] = -10.0
        [10,     5, 0] = 0.0
        [10,     5, 1] = 10.0
      [10,Banana,:]
        [10,Banana,-1] = -10.0
        [10,Banana, 0] = 0.0
        [10,Banana, 1] = 10.0""", repl=:print)
        end

        io_test(REPLMode, getvalue(x), """
    x: 3 dimensions:
    [ 9,:,:]
      [ 9, 99,:]
        [ 9, 99,3] = 2673.0
        [ 9, 99,4] = 3564.0
      [ 9,100,:]
        [ 9,100,3] = 2700.0
        [ 9,100,4] = 3600.0
      [ 9,101,:]
        [ 9,101,3] = 2727.0
        [ 9,101,4] = 3636.0
    [10,:,:]
      [10, 99,:]
        [10, 99,3] = 2970.0
        [10, 99,4] = 3960.0
      [10,100,:]
        [10,100,3] = 3000.0
        [10,100,4] = 4000.0
      [10,101,:]
        [10,101,3] = 3030.0
        [10,101,4] = 4040.0
    [11,:,:]
      [11, 99,:]
        [11, 99,3] = 3267.0
        [11, 99,4] = 4356.0
      [11,100,:]
        [11,100,3] = 3300.0
        [11,100,4] = 4400.0
      [11,101,:]
        [11,101,3] = 3333.0
        [11,101,4] = 4444.0""", repl=:print)

        io_test(REPLMode, getvalue(y), """
    y: 2 dimensions, 6 entries:
     [ 9, 9] = 81.0
     [ 9,10] = 90.0
     [ 9,11] = 99.0
     [10,10] = 100.0
     [10,11] = 110.0
     [11,11] = 121.0""")

        io_test(REPLMode, getvalue(z), """
    z: 2 dimensions:
    [a,:]
      [a,1] = 1.0
      [a,2] = 2.0
      [a,3] = 3.0
    [b,:]
      [b,1] = 1.0
      [b,2] = 2.0
      [b,3] = 3.0""")

    end



    @testset "SOS constraints" begin
        modS = Model()
        a = [1,2,3]
        @variable(modS, x[1:3], Bin)
        addSOS1(modS, [a[i]x[i] for i in 1:3])
        s1 = JuMP.SOSConstraint([x[i] for i in 1:3],
                                [a[i] for i in 1:3], :SOS1)
        io_test(REPLMode, s1, "SOS1: {1 x[1], 2 x[2], 3 x[3]}")
        io_test(IJuliaMode, s1, "SOS1: \\{1 x[1], 2 x[2], 3 x[3]\\}")

        b = [5,4,7,2,1]
        @variable(modS, y[1:5], Bin)
        s2 = JuMP.SOSConstraint([y[i] for i in 1:5],
                                [b[i] for i in 1:5], :SOS2)
        io_test(REPLMode, s2, "SOS2: {5 y[1], 4 y[2], 7 y[3], 2 y[4], 1 y[5]}")
        io_test(IJuliaMode, s2, "SOS2: \\{5 y[1], 4 y[2], 7 y[3], 2 y[4], 1 y[5]\\}")
    end


    @testset "changing variable categories" begin
        le, ge, fa = repl[:leq], repl[:geq], repl[:for_all]
        inset, dots = repl[:in], repl[:dots]
        infty, union = repl[:infty], repl[:union]

        mod = Model()
        @variable(mod, x[1:3])
        @variable(mod, y[i=1:3,i:3])
        setcategory(x[3], :SemiCont)
        setcategory(y[1,3], :Int)

        io_test(REPLMode, mod, """
    Min 0
    Subject to
     x[1]
     x[2]
     x[3] $inset [-$infty,$infty] $union {0}
     y[1,1]
     y[1,2]
     y[1,3], integer
     y[2,2]
     y[2,3]
     y[3,3]
    """, repl=:print)

        io_test(IJuliaMode, mod, """
    \\begin{alignat*}{1}\\min\\quad & 0\\\\
    \\text{Subject to} \\quad & x_{1}\\\\
     & x_{2}\\\\
     & x_{3} \\in \\[-\\infty,\\infty\\] \\cup \\{0\\}\\\\
     & y_{1,1}\\\\
     & y_{1,2}\\\\
     & y_{1,3}, \\in \\mathbb{Z}\\\\
     & y_{2,2}\\\\
     & y_{2,3}\\\\
     & y_{3,3}\\\\
    \\end{alignat*}
    """)
    end

    @testset "expressions" begin
        # Most of the expression logic is well covered by test/operator.jl
        # This is really just to check IJulia printing for expressions
        le, ge = repl[:leq], repl[:geq]

        #------------------------------------------------------------------
        mod = Model()
        @variable(mod, x[1:5])
        @variable(mod, y[i=2:4,j=i:5])
        @variable(mod, z)

        @constraint(mod, x[1] + 2*y[2,3] <= 3)
        io_test(REPLMode, mod.linconstr[end], "x[1] + 2 y[2,3] $le 3")
        io_test(IJuliaMode, mod.linconstr[end], "x_{1} + 2 y_{2,3} \\leq 3")

        @constraint(mod, (x[1]+x[2])*(y[2,2]+3.0) <= 1)
        io_test(REPLMode, mod.quadconstr[end], "x[1]*y[2,2] + x[2]*y[2,2] + 3 x[1] + 3 x[2] - 1 $le 0")
        io_test(IJuliaMode, mod.quadconstr[end], "x_{1}\\times y_{2,2} + x_{2}\\times y_{2,2} + 3 x_{1} + 3 x_{2} - 1 \\leq 0")

        @constraint(mod, (y[2,2]+3.0)*(x[1]+x[2]) <= 1)
        io_test(REPLMode, mod.quadconstr[end], "x[1]*y[2,2] + x[2]*y[2,2] + 3 x[1] + 3 x[2] - 1 $le 0")
        io_test(IJuliaMode, mod.quadconstr[end], "x_{1}\\times y_{2,2} + x_{2}\\times y_{2,2} + 3 x_{1} + 3 x_{2} - 1 \\leq 0")
    end



    @testset "Variable" begin
        m = Model()
        @variable(m, 0 <= x <= 2, inconstraints=ConstraintRef{Model,LinearConstraint}[], objective=0.0, coefficients=Float64[] )

        @test    getname(x) == "x"
        io_test(REPLMode,   x, "x")
        io_test(IJuliaMode, x, "x")

        setname(x, "x2")
        @test    getname(x) == "x2"
        io_test(REPLMode,   x, "x2")
        io_test(IJuliaMode, x, "x2")

        setname(x, "")
        @test    getname(x) == "col_1"
        io_test(REPLMode,   x, "col_1")
        io_test(IJuliaMode, x, "col_1")

        @variable(m, z[1:2,3:5])
        @test       getname(z[1,3]) == "z[1,3]"
        io_test(REPLMode,   z[1,3],    "z[1,3]")
        io_test(IJuliaMode, z[1,3],    "z_{1,3}")
        @test       getname(z[2,4]) == "z[2,4]"
        io_test(REPLMode,   z[2,4],    "z[2,4]")
        io_test(IJuliaMode, z[2,4],    "z_{2,4}")
        @test       getname(z[2,5]) == "z[2,5]"
        io_test(REPLMode,   z[2,5],    "z[2,5]")
        io_test(IJuliaMode, z[2,5],    "z_{2,5}")

        @variable(m, w[3:9,["red","blue","green"]])
        @test    getname(w[7,"green"]) == "w[7,green]"
        io_test(REPLMode,   w[7,"green"], "w[7,green]")
        io_test(IJuliaMode, w[7,"green"], "w_{7,green}")

        rng = 2:5
        @variable(m, v[rng,rng,rng,rng,rng,rng,rng])
        a_v = v[4,5,2,3,2,2,4]
        @test    getname(a_v) == "v[4,5,2,3,2,2,4]"
        io_test(REPLMode,   a_v, "v[4,5,2,3,2,2,4]")
        io_test(IJuliaMode, a_v, "v_{4,5,2,3,2,2,4}")
    end

    @testset "User-created Array{Variable}" begin
        m = Model()
        @variable(m, x)
        @variable(m, y)

        v = [x,y,x]
        A = [x y; y x]
        if VERSION < v"0.6.0-dev.2505" # julia PR #20288
            io_test(REPLMode,   v, "JuMP.Variable[x,y,x]")
            io_test(IJuliaMode, v, "JuMP.Variable[x,y,x]")
        else
            io_test(REPLMode,   v, "JuMP.Variable[x, y, x]")
            io_test(IJuliaMode, v, "JuMP.Variable[x, y, x]")
        end

        io_test(REPLMode,   A, "JuMP.Variable[x y; y x]")
        io_test(IJuliaMode, A, "JuMP.Variable[x y; y x]")
    end

    @testset "basename keyword argument" begin
        m = Model()
        @variable(m, x, basename="foo")
        @variable(m, y[1:3], basename=:bar)
        num = 123
        @variable(m, z[[:red,:blue]], basename="color_$num")
        @variable(m, v[1:2,1:2], SDP, basename=string("i","$num",num))
        @variable(m, w[1:3,1:3], Symmetric, basename="symm")

        io_test(REPLMode,   x, "foo")
        io_test(IJuliaMode, x, "foo")
        io_test(REPLMode,   y[2], "bar[2]")
        io_test(IJuliaMode, y[2], "bar_{2}")
        io_test(REPLMode,   z[:red], "color_123[red]")
        io_test(IJuliaMode, z[:red], "color_123_{red}")
        io_test(REPLMode,   v[2,1], "i123123[1,2]")
        io_test(IJuliaMode, v[2,1], "i123123_{1,2}")
        io_test(REPLMode,   w[1,3], "symm[1,3]")
        io_test(IJuliaMode, w[1,3], "symm_{1,3}")
    end

    @testset "SD constraints #883" begin
        m = Model()
        A = [2.0  0.0;
             0.0  1.0]
        @variable(m, X[1:2,1:2], SDP)
        s = @SDconstraint(m, X >= A)
        io_test(REPLMode, s, " X[1,1] - 2  X[1,2]     is semidefinite\n X[1,2]      X[2,2] - 1")
    end

    @testset "no method matching mapcontainer_warn(::JuMP.#_getValue, ::JuMP.JuMPArray{JuMP.NonlinearExpression,1,Tuple{UnitRange{Int64}}}) #964" begin
        items = 1:4
        m = Model()
        @variable(m, x[i in items])
        @NLexpression(m, A[i in items], x[i])
        @NLexpression(m, B[i in items, j in 1:i], j * x[i])

        a = getvalue(A)
        @test typeof(a) == JuMP.JuMPArray{Float64,1,Tuple{UnitRange{Int}}}
        io_test(REPLMode, a, """
    __anon__: 1 dimensions:
    [1] = NaN
    [2] = NaN
    [3] = NaN
    [4] = NaN""")
        b = getvalue(B)
        @test typeof(b) == JuMP.JuMPDict{Float64,2}
        io_test(REPLMode, b, """
    __anon__: 2 dimensions, 10 entries:
     [1,1] = NaN
     [2,1] = NaN
     [2,2] = NaN
     [3,1] = NaN
     [3,2] = NaN
     [3,3] = NaN
     [4,1] = NaN
     [4,2] = NaN
     [4,3] = NaN
     [4,4] = NaN""")
    end

    @testset "error printing value of variable with weird index set #982" begin
        for_all, inset = repl[:for_all], repl[:in]
        m = Model()
        @variable(m, x[1:2,1], start=0)
        io_test(REPLMode, x, "x[i,j] $for_all i $inset {1,2}, j $inset {1}")
        io_test(REPLMode, getvalue(x), """
    x: 2 dimensions:
    [1,:]
      [1,1] = 0.0
    [2,:]
      [2,1] = 0.0""")
    end

    @testset "Printing variables in a copied model #1019" begin
        ge, for_all, inset = repl[:geq], repl[:for_all], repl[:in]
        m1 = Model()
        @variable(m1, x[1:2] >= 0)
        n1 = copy(m1)
        io_test(REPLMode, m1.obj_dict[:x], "x[i] $ge 0 $for_all i $inset {1,2}")
        io_test(REPLMode, n1.obj_dict[:x], "x[i] $ge 0 $for_all i $inset {1,2}")

        a = [:a; :b]
        m2 = Model()
        @variable(m2, x[a] >= 0)
        n2 = copy(m2)
        io_test(REPLMode, m2.obj_dict[:x], "x[i] $ge 0 $for_all i $inset {a,b}")
        io_test(REPLMode, n2.obj_dict[:x], "x[i] $ge 0 $for_all i $inset {a,b}")
    end
end