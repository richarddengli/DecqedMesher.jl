module DecqedMesher

include("./mesher3D/mesher3D_types.jl")
include("./mesher3D/mesher3D_parse.jl")
include("./mesher3D/mesher3D_primalmesh.jl")
include("./mesher3D/mesher3D_dualmesh.jl")

using .Mesher3D_Dualmesh
# complete_dualmesh is exported from Mesher3D_Dualmesh into DecqedMesher

# now export complete_dualmesh from DecqedMesher into the importing module, directly available in the global scope of the importing module:
export complete_dualmesh
# i.e. it is sufficient to use the unqualified function call in the importing module:
# ---
# using DecqedMesher
# complete_dualmesh()
# ---
# all other unexported functions must be accessed using qualified calls, e.g:
# ---
# using DecqedMesher (if package has not been imported yet)
# DecqedMesher.Mesher3D_Primalmesh.complete_primalmesh()
# ---

include("./mesher2D/mesher2D_types.jl")
include("./mesher2D/mesher2D_parse.jl")
include("./mesher2D/mesher2D_primalmesh.jl")
include("./mesher2D/mesher2D_dualmesh.jl")


end 
