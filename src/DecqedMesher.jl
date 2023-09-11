module DecqedMesher

include("./mesher3D/mesher3D_types.jl")
include("./mesher3D/mesher3D_parse.jl")
include("./mesher3D/mesher3D_primalmesh.jl")

using .Mesher3D_Types
using .Mesher3D_Parse
using .Mesher3D_Primalmesh


relative_filepaath = "/meshes/transfinite_test.msh"
filepath = getfilepath(relative_filepaath)
print(filepath)
#test = complete_primalmesh(file)
#print(test)

# the following exports are those made available to the user
export Mesher3D_Types, Mesher3D_Parse



end
