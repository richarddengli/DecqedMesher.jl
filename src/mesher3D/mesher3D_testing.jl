# This file can be used by the user as a sandbox for testing.
# using .Mesher3D_Dualmesh

import FromFile: @from
@from "Mesher3D_dualmesh.jl" using Mesher3D_Dualmesh

@time dualmesh = Mesher3D_Dualmesh.complete_dualmesh(raw"/meshes/transfinite_test.msh")